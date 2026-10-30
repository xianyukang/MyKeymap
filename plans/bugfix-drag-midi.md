# 修复方案：拖拽三 bug + MIDI 长按语义

> 状态：**待实施**（本文档为根因分析与方案，不含代码改动）
> 项目：MyKeymap，分支 `main`（`e8d179d` 之后有未提交改动）

---

## 一、结论先行

| # | 现象 | 根因 | 处置 |
|---|---|---|---|
| 0 | MIDI 按住连续触发 | 热键 AutoRepeat 使 down 多次 → 反复 NoteOn | ✅ 已修（down 去重，双层） |
| 1 | 高频原地点击侧键偶尔漏键 | down 处理器**阻塞**（`Sleep 50`/文件 I/O）导致配对竞态 | 改单线程手势模型 |
| 2 | 缩放后其它窗口不能点击 | **修饰键卡住**（Win/Alt 被系统认为按住 → 点击被吞） | 见 #3 修复 |
| 3 | Win/Alt 始终被视作按下 | `HoldModifierUntilKeyUp` 的 Down/Up **无 finally 保证**，被中断即永久卡住 | 重写为 try/finally + 看门狗 + 全局清理 |

另有一个**必须撤销**的错误改动：生成侧 [`wildcardHotkey()`](config-server/internal/script/action.go:238) 私自给热键加 `*`。

---

## 二、关于 `*` 通配符：**判定为错误改动，应撤销**

[`config-server/internal/script/action.go:236`](config-server/internal/script/action.go:236)：

```go
// wildcardHotkey 在热键名前补 "*" 通配符(已含则原样返回).
// 拖拽类 down/up 热键必须带 *, 否则物理按住 Ctrl/Alt 等修饰键时会被整体旁路.
func wildcardHotkey(hk string) string { ... }
```

在 [`windowActions3`](config-server/internal/script/action.go:254) 的 17/18 分支被用于改写用户热键：

```go
hk := wildcardHotkey(a.Hotkey)   // 把 XButton2 变成 *XButton2
```

### 为什么不对

1. **`*` 的语义是「忽略修饰键」**，与「拦截/不漏键」毫无关系。它只影响「**热键在何种修饰键状态下触发**」，完全不改变 down/up 的配对与拦截。
2. **它改变并扩大了用户配置的语义**：用户配置写的是 `XButton2`；加了 `*` 后，**按住 Win/Alt/Ctrl/Shift 再点侧键也会触发拖拽**，且会吞掉那些组合键的本意。这是隐式的行为变更，用户没有授权。
3. **它的真实动机是掩盖 #3**：一旦 Win 被卡住（#3），系统认为 Win 在按下，**不带 `*` 的热键会被旁路**，于是「拖拽突然不响应」。子任务没有去修 #3，而是用 `*` 让热键「即使 Win 卡住也触发」——**治标不治本**，且制造了上面第 2 条的副作用。
4. 把它写进**生成器**（对所有用户的产物生效），属于把临时规避手段固化进产品逻辑。

### 处置
- **删除** `wildcardHotkey()` 及其在 `windowActions3` 中的调用，恢复 `a.Hotkey` 原样使用。
- 真正要解决的是 #3（让修饰键不卡住）。#3 修好后，「Win 卡住导致热键被旁路」不复存在，`*` 自然不需要。

---

## 三、#3：修饰键卡住（Win/Alt 始终被判为按下）

### 现状代码
[`bin/lib/Actions.ahk:758`](bin/lib/Actions.ahk:758)：

```ahk
HoldModifierUntilKeyUp(modifier) {
  key := ExtractWaitKey(A_ThisHotkey)
  Send("{blind}{" modifier " Down}")     ; ① 送出 Down
  Loop 3000 {                            ; ② 阻塞最多 ~30s
    if !DragKeyPhysicallyDown(key)
      break
    Sleep 10
  }
  Send("{blind}{" modifier " Up}")       ; ③ 送出 Up
  if GetKeyState(modifier, "P")
    Send("{blind}{" modifier " Up}")
}
```

### 根因
Down(①) 与 Up(③) **不是原子对**。在 ①与③之间，任何**打断**都会让 Up 永远发不出：

- 热键线程被 `Suspend`/`Reload`/`Exit` 打断（MyKeymap 有暂停/重载/退出）；
- `A_MaxHotkeysPerInterval`/`A_HotkeyInterval` 触发（本仓库设为 256）导致该线程被中止；
- 阻塞 `Loop` 期间用户再次触发、或 `Send` 期间 hook 重入；
- 进程崩溃、脚本重载。

**一旦 ③ 被跳过，系统就永久认为 Win/Alt 按住** → 
- 该修饰键「始终被视作按下」（#3）；
- Windows 对「按住修饰键时的鼠标点击」有特殊处理（Win+点击、Alt+点击），**导致其它窗口点不动**（#2）。

> 即：**#2 与 #3 是同一个根因的两种表现**（#2 是 Win/Alt 卡住后点击被吞）。

### 修复设计
1. **Down/Up 用 `try { } finally { }` 包成原子对**（AHK v2 支持 `finally`），保证任何异常路径都会发 Up：
   ```ahk
   HoldModifierUntilKeyUp(modifier) {
     key := ExtractWaitKey(A_ThisHotkey)
     sent := false
     try {
       Send("{blind}{" modifier " Down}")
       sent := true
       loop { if !DragKeyPhysicallyDown(key) break ; Sleep 10 }
     } finally {
       if sent
         Send("{blind}{" modifier " Up}")
     }
   }
   ```
2. **全局看门狗**：用模块级 `Map` 记录「已发出 Down 但未 Up 的修饰键 + 时间戳」；用一个 `SetTimer` 低频（如 500ms）扫描，超时（如 3s）强制补发 Up。这样即使线程被强杀，也能被另一线程兜底释放。
3. **在生命周期节点强制释放**：
   - [`MyKeymapExit()`](bin/lib/Functions.ahk:27)：调用 `ReleaseAllHeldModifiers()`
   - 暂停/恢复（`MyKeymapToggleSuspend`）、重载（`MyKeymapReload`）同样调用。
4. **不重复发送**：若 `GetAsyncKeyState(modifier)` 显示用户**真的**按着该修饰键，则本次不发送 Down（也就不发 Up），避免抢夺用户真实按键。
5. 保持不引入 `MouseMove` 的既有约束。

---

## 四、#1：高频原地点击侧键偶尔漏键

### 现象
快速短按 XButton2（原地不动），偶尔触发其原生行为（后退/前进）。

### 根因（候选，按可能性排序）
1. **down 处理器阻塞 → down/up 配对竞态（主因）**：
   [`StartDragResizeWindow`](bin/lib/Actions.ahk:297) 在热键线程里做了一串耗时操作——`StopDragWindow()`、`DragHarmonizeDpi()`、`WinGetMinMax`、**`WinRestore` + `Sleep 50`**，以及 **`MkDiag()`（同步写文件 I/O）**。当用户「快速点击」时，**up 热键在 down 处理器尚未返回时就到达**，AHK 线程调度下 up 可能延迟或被 `A_MaxHotkeysPerInterval` 抑制 → **up 未被拦截 → 前台程序收到孤立 up → 判定为一次点击**。
2. **热键被兜底旁路**：`StartDragMoveWindow`/`StartDragResizeWindow` 内有 `if WindowDragState → return`；若上一手未清理干净，down 直接返回、但 up 仍会触发 `StopDragWindow`，不构成泄漏；但若 down 返回后 **`GetKeyState` 兜底逻辑**在 Poll 中立即 Stop，也会出现「down 吞了、up 没吞」的窗口期。
3. `MkDiag` 的同步文件写入在每次 Start/Stop 都执行 → 在热键线程里引入毫秒级抖动，放大 1 的竞态。

### 修复设计：**改为「单线程手势模型」**（推荐，且与仓库既有范式一致）
本仓库已有成熟的「按住-拖拽-松开」单线程范式（[`MouseKeymap._moveMouse`](bin/lib/KeymapManager.ahk:553)、[`BindWindow`](bin/lib/Actions.ahk:804) 都用 `KeyWait` 阻塞整个手势）。

改为：

```ahk
; 只注册一个 down 热键; 手势期间在本线程内轮询, 松开时自然结束
StartDragResizeWindow(strategy := "axis") {
  ...
  MouseGetPos 基准 / 记录 rect          ; 记录, 不动窗口
  while DragKeyPhysicallyDown(triggerKey) {   ; 同一线程内闭环
     读取光标 → 计算 → (死区内不写; 超过死区才 SetWindowPos)
     Sleep 10
  }
  ; 结束清理(DPI/状态)
}
```

**收益**：
- 不存在 down/up 两个热键的竞态 → **彻底解决 #1**（不存在「up 到达时 down 未归」的窗口）；
- 整个手势同一线程 → DPI 上下文天然一致（可简化 `DragHarmonizeDpi/Restore`）；
- 无需 `SetTimer`、无需 up 热键 → 消除「定时器残留」（#2 的一个次要嫌疑）；
- 与仓库既有 `KeyWait` 范式一致，风格统一。

**注意**：需确认 MyKeymap 的 `#MaxThreadsPerHotkey` 等设置允许该阻塞（默认 `1`，`_moveMouse` 已在用，故可行）；并确保松开检测用 `DragKeyPhysicallyDown`（`GetAsyncKeyState`）以免内部键态卡死。

**同时**：
- **移除** down 路径里的 `Sleep 50` 与同步 `MkDiag`/`DragLog` 文件 I/O（改为默认关闭、仅排查时开启，且异步/批量）。

---

## 五、#2：缩放后其它窗口不能点击

### 主因（与 #3 同源）
Win/Alt 被卡住 → 系统对修饰键+鼠标点击做特殊处理 → 其它窗口「点不动」。
**修好 #3 后应同步消失**（需实机复验，这是**首要验证点**）。

### 次要嫌疑（防御性加固）
1. **捕获残留**：在 [`StopDragWindow`](bin/lib/Actions.ahk:409) 结束时调用 `DllCall("ReleaseCapture")`（释放**本线程**捕获，安全无副作用）。
2. **DPI 上下文**：`StopDragWindow` 已复位；改为单线程手势后此项自然简化。
3. **定时器残留**：单线程模型不再有 `SetTimer`，风险消除。
4. **不要再用 `WM_SYSCOMMAND/SC_MOVE`**：旧 [`MakeWindowDraggable`](bin/lib/Actions.ahk:12)（ValueID 13）用的是系统模态移动循环，**正是「鼠标被抢/其它窗口点不动」的经典成因**。确认用户未使用 13；若使用，需一并说明其固有缺陷（本方案不改变 13 的行为，仅澄清）。

---

## 六、实施步骤（建议顺序）

1. **撤销 `*` 改动**：删除 [`wildcardHotkey()`](config-server/internal/script/action.go:238) 与其调用，恢复用户热键原样。
2. **重写拖拽为单线程手势模型**：[`Actions.ahk`](bin/lib/Actions.ahk:199) 的 `StartDragMoveWindow`/`StartDragResizeWindow` 内部闭环；移除 up 热键需求（生成侧 [`windowActions3`](config-server/internal/script/action.go:254) 同步只生成 down 一条 `km.Map`）。
3. **移除热键路径的阻塞与 I/O**：去掉 `Sleep 50`、把 `MkDiag`/`DragLog` 改为默认关闭。
4. **重写 `HoldModifierUntilKeyUp`**：`try/finally` + 看门狗 + 全局释放；在 `MyKeymapExit`/暂停/重载处调用 `ReleaseAllHeldModifiers()`。
5. **`StopDragWindow` 加固**：`ReleaseCapture()` + 状态/DPI 清理（保留幂等）。
6. **重建产物**：`settings.exe`（Go 有改动）、`bin/templates`、`bin/MyKeymap.ahk`。
7. **清理临时文件**：`tmp_bisect.ps1`、`bin/tmp_api.ahk`、`bin/tmp_diag.ahk`、`bin/tmp_drive.ahk`、`bin/tmp_hello.ahk`、`bin/tmp_inc.ahk`、`bin/tmp_inc2.ahk`、`bin/tmp_one.ahk`、`bin/tmp_probe.ahk`，以及任何 `%TEMP%\mk_diag*`、`bin/drag_debug.log`。
8. **验证**（见下）。

---

## 七、验证方案

| 项 | 方法 | 通过标准 |
|---|---|---|
| #1 | 真实鼠标高频原地短按 XButton2 数十次 | 全程无一次触发原生后退/前进 |
| #2 | 缩放后立刻点击多个其它窗口 | 均可正常点击/激活 |
| #3 | 触发修饰键保持键、并中断（暂停/重载/退出）后查 `GetKeyState("LWin","P")` 与 `GetAsyncKeyState` | 均回到「未按下」；系统不再认为 Win/Alt 按住 |
| 回归 | 移动/缩放仍「按下不跳变、不抖动、松手停止」 | 与既有表现一致 |
| 语法 | `AutoHotkey64.exe /validate` | 退出码 0 |

> 注：AHK 会忽略注入按键，**#1/#2/#3 的最终确认必须由用户用真实鼠标/键盘操作**。我将提供可选的诊断开关（默认关闭）以便按需取证。

---

## 八、需用户确认的决策

1. **拖拽改为「单线程阻塞手势」**（推荐，根治 #1 且风格统一）——是否接受？该模型下热键线程在手势期间被占用（与仓库现有 `_MoveMouse`/`BindWindow` 相同）。
   - 备选：保留 `SetTimer` + down/up 双热键，仅做「去阻塞 + 配对加固」。修复力度较弱，但线程占用更小。
2. **撤销 `*` 通配改动**（恢复用户配置原样）——确认。
3. `HoldModifierUntilKeyUp` 的超时上限（现 30s）是否收紧为更短（如 5s）+ 看门狗（3s）？
