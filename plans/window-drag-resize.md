# 拖拽移动 / 拖拽缩放窗口 设计方案

> 目标：在「🏠 窗口操作」动作（后端 `id=3`，`windowActions3`）中新增两个功能：
> 1. 拖拽移动窗口（按下不变，鼠标实际移动后跟随）
> 2. 拖拽缩放窗口（按下瞬间不改尺寸，鼠标实际移动后按方向+距离改变，最少尺寸限制）
>
> **状态：✅ 已实现**。本设计已按下列最终形态落地，不再只是侦察。
>
> | 项 | 最终实现 |
> |---|---|
> | ValueID 17 | 拖拽移动窗口 → `StartDragMoveWindow()` / up → `StopDragWindow()` |
> | ValueID 18 | 拖拽缩放窗口 → `StartDragResizeWindow("axis")` / up → `StopDragWindow()` |
> | AHK 函数 | `StartDragMoveWindow` / `PollDragMoveWindow`、`StartDragResizeWindow` / `PollDragResizeWindow`、`StopDragWindow`，位于 [`Actions.ahk`](bin/lib/Actions.ahk:22) |
> | 全局状态 | `WindowDragState`、`DRAG_DEADZONE=4`、`DRAG_MIN_W=120`、`DRAG_MIN_H=80` |
> | 拦截策略 | 完全拦截, 任何情况都不补发/放行原触发键(未拖动 = 什么都没按); 见 §3.5 |
> | 缩放策略 | 按位移主轴自动选边/角（`|dx|>2|dy|` 改左右、`|dy|>2|dx|` 改上下、否则改角） |
> | 前端 | [`Window.vue`](config-ui/src/components/actions/Window.vue:23) `group2` 追加 17/18；标签 1701/1702（[`language-map.ts`](config-ui/src/store/language-map.ts:24)） |
> | 生成形态 | `km.Map("<Hotkey>", _ => <Start><ctx>), km.Map("<Hotkey> up", _ => <Stop><ctx>)` |
> | 坐标系 | **全程原生 Win32 物理屏幕坐标**: `GetCursorPos`(读光标) / `GetWindowRect`(读窗口) / `SetWindowPos`(写窗口), 与 AHK `CoordMode` 线程局部性、AHK DPI 层无关 (见 §0、§3.6) |
> | DPI 处理 | 每帧 `DragHarmonizeDpi()` 统一到 `PER_MONITOR_AWARE(-3)` 并 `DragRestoreDpi()` 复原, 杜绝会话内上下文漂移 (见 §0、§3.6) |
> | 去抖 | 目标矩形与上一帧一致(≥1px 才写)则跳过; `SWP_NOSIZE\|SWP_NOZORDER\|SWP_NOACTIVATE`(移动) / `SWP_NOMOVE\|SWP_NOZORDER\|SWP_NOACTIVATE`(缩放) |
> | 调试日志 | `DRAG_DEBUG`(默认 `false`) → `bin/drag_debug.log`; `DRAG_TEST_MODE`(默认 `false`) 仅跳过按键兜底, 供真实坐标路径测试 |
> | 文档补充 | `doc/` 下仅有图片资源、无窗口功能用户文档，未补充 |

---

## 零、修复复盘（2026-10-08，真实坐标路径）

### 0.1 真实故障（用户实测）

1. 移动窗口时窗口 **疯狂抖动**；
2. 缩放窗口时 **按下瞬间即改变窗口边缘位置**（要求：按下瞬间绝不能变，必须等鼠标移动后按方向+距离改变）。

### 0.2 根因：`CoordMode` 的**线程局部性**导致 Start / Poll 坐标系不一致

> ⚠️ **上次“验证通过”无效的教训**：上次测试脚本 **mock/伪造了鼠标坐标**（注入 `DragReadPos` 之类），
> 绕过了真实的 `MouseGetPos` 读取路径，因此真实的坐标不一致问题被完全掩盖。本次必须以
> `SetCursorPos`/`GetCursorPos` **真实驱动光标、走产品真实读取路径**才复现出来。

用真实坐标路径逐帧取证（`DRAG_DEBUG=true`，Test 1 从定时器线程调用 `Start` 且**不设** `CoordMode`）：

```
[Start move] ctx=18 cm=Screen | MouseGetPos=(1222,700) | ox=300 oy=250
[Poll move]  ctx=18 cm=Client | mx=926 my=664 dx=-296 dy=-36 | tgt=(626,414)
```

- `Start` 运行在**热键线程**：`CoordMode("Mouse","Screen")` 生效，`A_CoordModeMouse=Screen`，`MouseGetPos=(1222,700)`。
- `Poll` 由 `SetTimer` 建立的**定时器线程**执行：`CoordMode` 是 **thread-local**，定时器线程**不继承** Start 的设置，
  其 `A_CoordModeMouse=Client`（AHK 默认值，相对**活动窗口**），于是 `MouseGetPos=(926,664)`——
  与真实屏幕坐标 `(1222,700)` 相差一个“活动窗口客户区原点”的偏移。
- 结果：`Poll` 首帧 `dx=-296`（暴走）⇒ 窗口瞬间大幅移动（跳变）；且 Client 读数的参照系（活动窗口）**随拖动一起移动**，
  位移反馈回自身 ⇒ 往复振荡（**疯狂抖动**）。
- 缩放同理：`[Start resize] cm=Screen` 记录基准，`[Poll resize] cm=Client dx=-296` ⇒ 首帧 `nw: 716→420`，即“按下瞬间改变边缘”。

**补充**：本机为 **100% 缩放 / 96 DPI / 单显示器**（`A_ScreenDPI=96`、`SM_CXVIRTUALSCREEN=2560`），
`MouseGetPos`↔`GetCursorPos`、`WinGetPos`↔`GetWindowRect` 在同一坐标系下**完全一致**。
因此之前怀疑的“DPI/缩放不一致”在本机**不是**本次根因；真正的矛盾是 **CoordMode 的线程局部性**。
（多显示器混合 DPI 下该线程局部性问题依然存在，方案 A 同时规避两类问题。）

### 0.3 修复：全程原生 Win32 物理屏幕坐标（方案 A）

- 读光标：`DragRawCursor()` → `GetCursorPos`（恒返回物理屏幕坐标，与线程/CoordMode/DPI 层无关）。
- 读窗口：`DragRawRect()` → `GetWindowRect`。
- 写窗口：`DragSetWindowPos()` → `SetWindowPos`，移动用 `SWP_NOSIZE|SWP_NOZORDER|SWP_NOACTIVATE`(0x15)，
  缩放用 `SWP_NOMOVE|SWP_NOZORDER|SWP_NOACTIVATE`(0x16)。
- DPI：`DragHarmonizeDpi()` 在 `Start` 与每帧 `Poll` 把本线程上下文统一为 `PER_MONITOR_AWARE(-3)`
  （句柄值 `18`），算完立即 `DragRestoreDpi()` 复原。
- 保留原始语义：死区 4px 内不写；移动“抓取点吸附光标”；缩放左上角固定 + 主轴 + 最小 `120x80`；
  仅当目标矩形相对上一帧有实际变化时才写（去抖）；**绝不** `MouseMove`/`SetCursorPos`。

### 0.4 真实坐标路径验证（修复前 → 修复后）

驱动方式：`DllCall("SetCursorPos", ...)` 真实移动光标；`Start` 从定时器线程调用且**刻意不设 CoordMode**（即复现故障的条件）。

| 项 | 修复前 | 修复后 |
|---|---|---|
| `Poll` 读取 | `cm=Client (926,664)`（错坐标系） | `cm` 无关, `GetCursorPos` 恒为物理屏幕坐标 |
| 移动首帧 dx | **-296**（暴走跳变） | 死区内(0) 不写；超死区后 `dx` 为真实小幅值 |
| 缩放首帧 | `716→420`（按下瞬间改变） | `716→716`（**按下瞬间不变**） |
| 每帧 `err` | 坐标系错位 | `(0,0)` / `(0,0,0,0)`（目标=实际，逐帧精确） |

自动化断言（[`tmp_drag/tmp_verify.ahk`] 真实坐标驱动，最终 `PASS=10 FAIL=0`）：

- 移动：帧0 光标不动 ⇒ 窗口不变 `(922,450)==(922,450)`；`Δ窗口 ≈ Δ光标(≤1px)` 且尺寸不变；抓取偏移恒定（吸附光标）；静止连续两帧窗口不变（**无往复抖动**）。
- 缩放：帧0 不变 `716x539`；水平 `Δ宽≈Δ光标x` 且高/左不变；垂直 `Δ高≈Δ光标y` 且宽/上不变；对角 `Δ宽≈Δ光标x 且 Δ高≈Δ光标y`；最小钳制 `120x80`；左上角固定 `(922,450)`。

> 说明：自动化测试刻意人为移动光标以省时；产品代码**绝不**移动光标，真实使用时由用户鼠标驱动。

### 0.5 结论与遗留

- 根因**已定位并复现**、修复后断言全部通过。
- 仍建议用户用**真实鼠标手感**做最终确认（尤其多显示器混合 DPI 环境；本机为 100% 单屏）。
- 临时脚本与测试进程已清理；`DRAG_TEST_MODE` 默认关闭，不影响正常运行路径。

---

## 一、侦察结论：现有实现与数据流

### 1.1 窗口操作动作体系（后端）

[`windowActions3()`](config-server/internal/script/action.go:219) 是 `actionMap[3]`（见 [`actionMap`](config-server/internal/script/action.go:14)）对应的生成函数。它把配置里的 `Action.ValueID` 映射成一段 AHK 调用：

- ValueID `4`（任务切换）走特判：[`action.go:220-222`](config-server/internal/script/action.go:220)
- ValueID `14`（绑定窗口）走特判：[`action.go:223-225`](config-server/internal/script/action.go:223)
- 其余走 [`callMap`](config-server/internal/script/action.go:226)：

| ValueID | AHK 调用 | 说明 |
|---|---|---|
| 1 | [`SmartCloseWindow()`](bin/lib/Actions.ahk:159) | 智能关闭 |
| 2 | `GoToLastWindow()` | 切上一个窗口 |
| 3 | [`LoopRelatedWindows()`](bin/lib/Actions.ahk:59) | 同程序窗口轮换 |
| 4 | `Send("^!{tab}")` + taskSwitch | 任务切换（特判） |
| 5 | `GoToPreviousVirtualDesktop()` | 上一个虚拟桌面 |
| 6 | `GoToNextVirtualDesktop()` | 下一个虚拟桌面 |
| 7 | `MoveWindowToNextMonitor()` | 移到下一个显示器 |
| 8 | `MinimizeWindow()` | 最小化 |
| 9 | `MaximizeWindow()` | 最大化/还原 |
| 10 | [`CenterAndResizeWindow(1200, 800)`](bin/lib/Actions.ahk:183) | 居中 1200x800 |
| 11 | `CenterAndResizeWindow(1370, 930)` | 居中 1370x930 |
| 12 | [`ToggleWindowTopMost()`](bin/lib/Actions.ahk:240) | 切换置顶 |
| **13** | **[`MakeWindowDraggable()`](bin/lib/Actions.ahk:12)** | **让窗口随鼠标拖动（现状）** |
| 14 | [`BindWindow()`](bin/lib/Actions.ahk:365) | 绑定窗口（特判） |
| 15 | [`CloseWindowProcesses()`](bin/lib/Actions.ahk:270) | 杀进程关闭 |
| 16 | [`CloseSameClassWindows()`](bin/lib/Actions.ahk:406) | 关闭同类窗口 |

生成形态：`km.Map("<Hotkey>", _ => <call><Context>)`，其中 `<Context>` 来自 [`Config.GetHotkeyContext()`](config-server/internal/script/config.go:148)（返回 `, , winTitle, conditionType`，用于 `HotIf` 窗口过滤）。**已用 ValueID：1-16；可直接使用 17、18…**（避开 1-16 即可）。

### 1.2 `MakeWindowDraggable` 为何会移动/跳变光标

[`MakeWindowDraggable()`](bin/lib/Actions.ahk:12) 的完整实现：

```ahk
MakeWindowDraggable() {
  hwnd := WinExist("A")
  if (WindowMaxOrMin())
    WinRestore("A")

  PostMessage("0x0112", "0xF010", 0)   ; WM_SYSCOMMAND, SC_MOVE
  Sleep 50
  SendInput("{Right}")                 ; 发一个方向键让系统移动循环“咬住”
}
```

原因分析：

1. `PostMessage(0x0112=WM_SYSCOMMAND, 0xF010=SC_MOVE)` 触发的是 **Windows 自带的模态“移动窗口”循环**（与 Alt+Space→M 等价）。
2. 该循环由 `DefWindowProc` 驱动，它**以当前光标位置为锚点重定位窗口**，习惯上把光标“吸”到窗口顶端/标题栏对应点，因此会产生 **光标被强制移动（跳变到窗口顶部）** 的现象。
3. `SendInput("{Right}")` 只是给系统一个方向键输入，让移动循环开始跟随，并可能产生一次瞬移。
4. 整个过程依赖系统循环，**无法感知/保持“抓取点相对窗口的偏移”**，光标会被系统强制移动。

> 结论：这条路径本质上是“借用系统 SC_MOVE 循环”，与用户要的“抓住窗口上某点、光标不动”背道而驰，**必须用新的自实现方案**。

补充：仓库内**不存在** `MakeWindowDraggableByMouse` / `WindowDrag` / `DragWindow` 等函数（已全库检索，`bin/lib` 仅命中 `MakeWindowDraggable` 与 `BindWindow`），用户提到的这些名字在 AltSnap 侧，不在本项目。

### 1.3 鼠标触发链路（鼠标侧键 / 鼠标模式）

- 键位清单：在 [`config.ts`](config-ui/src/store/config.ts:14) 中 `mouseButtons = "LButton RButton MButton XButton1 XButton2 WheelUp WheelDown WheelLeft WheelRight"`，即 **XButton1/XButton2 就是“鼠标侧键”**。
- 默认映射示例：[`bin/MyKeymap.ahk:232-244`](bin/MyKeymap.ahk:232) 把 `RButton`（右键）注册为一个 keymap（`km16`），在其中 `km.Map("*XButton1", …)`、`km.Map("*XButton2", …)`。
- 核心类：
  - [`Keymap.Map()`](bin/lib/KeymapManager.ahk:253)：把 `hotkeyName → handler` 存入 `this.M`，最终由 [`_Hotkey.Enable()`](bin/lib/KeymapManager.ahk:219) 调用 `Hotkey(rawName, handler, "On")` 完成系统热键注册。
  - [`_Hotkey`](bin/lib/KeymapManager.ahk:208)：`ExtractWaitKey()` 把带修饰符的热键归一到“等待键”。
  - [`MouseKeymap`](bin/lib/KeymapManager.ahk:473)：鼠标模式专用 keymap，提供 [`_moveMouse()`](bin/lib/KeymapManager.ahk:505)（**用 `MouseMove(..., "R")` 相对移动光标**，这正是“鼠标模式”本质）、[`LButton()`](bin/lib/KeymapManager.ahk:578)/[`RButton()`](bin/lib/KeymapManager.ahk:586)/[`MButton()`](bin/lib/KeymapManager.ahk:594)。
- **down/up 成对注册的既有范式**：[`RemapInHotIf()`](bin/lib/KeymapManager.ahk:457) 中
  ```ahk
  this.Map("*" a, h, , winTitle, conditionType)
  this.Map("*" a " up", h, , winTitle, conditionType)   ; 见 KeymapManager.ahk:467-468
  ```
  即 `"*<key>"` 处理按下、`"*<key> up"` 处理松开，**两个热键共享同一 handler，用 `A_ThisHotkey` 区分**。本设计的 down/up 成对注册完全沿用该范式。
- 鼠标“单击 vs 拖动”的既有判定：[`Keymap.Wait()`](bin/lib/KeymapManager.ahk:299) 中当触发键含 `button` 时，会 `MouseGetPos` 轮询位移是否 >10px，从而区分“单击(singlePress)”与“拖动”。**这是本项目已存在的“读光标坐标判断拖动”范式**，本设计可复用其阈值思想。
- 关于用户提到的 `km.MapMidi`：本仓库**不存在** `bin/lib/Midi.ahk`，也无 `MapMidi`（已检索，0 命中）。可参考的 down/up 范式即 [`KeymapManager.ahk:467-468`](bin/lib/KeymapManager.ahk:467)。

### 1.4 现有窗口操作 UI

- [`Window.vue`](config-ui/src/components/actions/Window.vue:4) 用两个数组 `group1/group2` 声明选项，每项 `{ actionValueID, label }`，例如 ValueID=13 对应 `"label:15"`（[`Window.vue:21`](config-ui/src/components/actions/Window.vue:21)）、ValueID=14 对应 `"label:16"`（[`Window.vue:22`](config-ui/src/components/actions/Window.vue:22)）。
- [`RadioGroup.vue`](config-ui/src/components/actions/RadioGroup.vue:41) 渲染 `v-radio-group`，`label` 经 [`translate()`](config-ui/src/store/config.ts:1) 解析 `label:N` → `languageMap[N]`。
- 翻译表：[`language-map.ts`](config-ui/src/store/language-map.ts:6) 采用**全局扁平 key（不是按动作类型分命名空间）**，窗口段占用 1-16（[`language-map.ts:8-23`](config-ui/src/store/language-map.ts:8)），系统段从 17 开始（[`language-map.ts:26`](config-ui/src/store/language-map.ts:26)）。
  - ⚠️ 因此新增窗口选项的 label key **不能复用 17/18**，需另取空闲号段（详见 §3.4 之 (D)）。

### 1.5 AHK 可用坐标 / API（本项目已用范式）

| 手段 | 用途 | 本项目出处 |
|---|---|---|
| `MouseGetPos(&x,&y,&hwnd)` | 读光标屏幕坐标 + 光标下窗口 hwnd（**只读不写**） | [`KeymapManager.ahk:313`](bin/lib/KeymapManager.ahk:313) |
| `CoordMode("Mouse","Screen")` | 统一为屏幕坐标 | [`KeymapManager.ahk:311`](bin/lib/KeymapManager.ahk:311) |
| `GetKeyState(key,"P")` | 轮询按键是否物理按下 | [`KeymapManager.ahk:44`](bin/lib/KeymapManager.ahk:44) |
| `KeyWait(key, "T0.01")` | 带超时的等待 | [`KeymapManager.ahk:314`](bin/lib/KeymapManager.ahk:314) |
| `WinGetPos/WinMove` | 读窗口 rect / 改窗口几何 | [`Actions.ahk:193`](bin/lib/Actions.ahk:193)、[`Actions.ahk:530`](bin/lib/Actions.ahk:530) |
| `SetTimer(fn, ms)` | 定时轮询刷新 | [`Actions.ahk:124`](bin/lib/Actions.ahk:124)、[`Functions.ahk:50`](bin/lib/Functions.ahk:50) |
| `A_TickCount` | 计时（区分单击/长按） | [`KeymapManager.ahk:303`](bin/lib/KeymapManager.ahk:303) |
| `WinGetMinMax()` / `WinRestore()` | 最大化需先还原 | [`Actions.ahk:14-15`](bin/lib/Actions.ahk:14) |
| `DllCall("SetThreadDpiAwarenessContext", …)` | **多显示器混合 DPI 关键处理** | [`Actions.ahk:188-190`](bin/lib/Actions.ahk:188)、[`Actions.ahk:209`](bin/lib/Actions.ahk:209) |
| `MouseMove(..., "R")` | 相对移动光标（**本设计禁用**，避免抢光标） | [`KeymapManager.ahk:507`](bin/lib/KeymapManager.ahk:507) |

> DPI 经验（来自 [`CenterAndResizeWindow()`](bin/lib/Actions.ahk:183) 注释）：**读鼠标坐标**需要 `PER_MONITOR_AWARE(-3)` 才不会跨屏漂移；**写 `WinMove`** 需要 `UNAWARE(-1)` 让系统帮忙按 DPI 缩放。本设计“读坐标 + 写窗口”混合，跨 DPI 是风险点（见 §4.2）。

---

## 二、AltSnap 参考实现要点（可读源码）

参考项目：[`M:/08_Project/VSCODE/AltSnap`](M:/08_Project/VSCODE/AltSnap)（AltDrag 分支）。其理念见 [`README_zh-CN.md:11`](M:/08_Project/VSCODE/AltSnap/README_zh-CN.md:11)：“按住 Alt 键并单击窗口上的任何位置来移动和调整窗口大小，并不需要任何精确的点击。”

### 2.1 抓取与基准记录（按下时）

[`init_movement_and_actions()`](M:/08_Project/VSCODE/AltSnap/hooks.c:5019)（在按键按下时调用）：

- **目标窗口 = 光标下的窗口**：`state.hwnd = hwnd ? hwnd : WindowFromPoint(pt)`（[hooks.c:5037](M:/08_Project/VSCODE/AltSnap/hooks.c:5037)）。**不是**前台窗口。
- 记录基准尺寸：`state.origin.width/height` 取自 `GetWindowPlacement().rcNormalPosition`（[hooks.c:5093-5094](M:/08_Project/VSCODE/AltSnap/hooks.c:5093)）。
- 记录 **抓取点相对窗口的偏移**（移动模式，按比例）：
  ```c
  state.offset.x = state.origin.width  * min(pt.x-wnd.left, wnd.right-wnd.left) / max(wnd.right-wnd.left,1);
  state.offset.y = state.origin.height * min(pt.y-wnd.top,  wnd.bottom-wnd.top) / max(wnd.bottom-wnd.top,1);
  ```
  （[hooks.c:1979-1982](M:/08_Project/VSCODE/AltSnap/hooks.c:1979)）
- 按下时**不改变窗口**（只记录），改变发生在 `WM_MOUSEMOVE`。

### 2.2 移动算法（保持抓取点）

新位置 = 光标位置 − 抓取偏移：

```c
ownd->left = pt.x - state.offset.x - state.mdipt.x;
ownd->top  = pt.y - state.offset.y - state.mdipt.y;
ownd->right  = ownd->left + state.origin.width;
ownd->bottom = ownd->top  + state.origin.height;
```
（[hooks.c:1996-1999](M:/08_Project/VSCODE/AltSnap/hooks.c:1996)）

即“抓住的那个点”始终贴在光标处，**窗口跟随光标移动，但从不调用 MouseMove**（除 `CURSOR_ONLY`/最大化特例，[hooks.c:5320-5326](M:/08_Project/VSCODE/AltSnap/hooks.c:5320)）。

### 2.3 缩放算法（方向+距离驱动，无初始跳变）

`AC_RESIZE` 分支（[hooks.c:2286-2343](M:/08_Project/VSCODE/AltSnap/hooks.c:2286)）：

- 先判定缩放边/角（`RZ_LEFT/RIGHT/TOP/BOTTOM/XCENTER/YCENTER`），记录“光标到该边”的偏移 `state.offset.x/y`，例如：
  ```c
  if (state.resize.y == RZ_BOTTOM) { posy = wnd.top - state.mdipt.y; wndheight = pt.y - posy + state.offset.y; }
  if (state.resize.x == RZ_RIGHT ) { posx = wnd.left - state.mdipt.x; wndwidth = pt.x - posx + state.offset.x; }
  ```
  （[hooks.c:2323-2336](M:/08_Project/VSCODE/AltSnap/hooks.c:2323)）
- 强制最小值/最大值：`wndwidth = CLAMPW(wndwidth); wndheight = CLAMPH(wndheight);`（[hooks.c:2337-2338](M:/08_Project/VSCODE/AltSnap/hooks.c:2337)）。
- **边/角判定两种策略**（[hooks.c:3741-3810](M:/08_Project/VSCODE/AltSnap/hooks.c:3741)）：
  - `SetEdgeAndOffsetCF()`：把窗口划成九宫格（角 38% / 边 24%，[hooks.c:3744-3770](M:/08_Project/VSCODE/AltSnap/hooks.c:3744)），按**按下时光标在窗口内的相对位置**选边/角。
  - `SetEdgeToClosestSide()`：用对角线比较选最近边（[hooks.c:3777-3803](M:/08_Project/VSCODE/AltSnap/hooks.c:3777)）。
- **“右下角模式”** 是最简策略，AltSnap 也内置：当禁用中心缩放时
  ```c
  if (conf.ResizeCenter == 0) { // Use Bottom Right Mode
      state.resize.x = RZ_RIGHT; state.resize.y = RZ_BOTTOM;
  }
  ```
  （[hooks.c:3990-3995](M:/08_Project/VSCODE/AltSnap/hooks.c:3990)）

### 2.4 鼠标驱动

- `WM_MOUSEMOVE` 中若位置未变直接返回；否则更新 `state.prevpt` 并重算窗口（[hooks.c:5438-5448](M:/08_Project/VSCODE/AltSnap/hooks.c:5438)）。
- 整个拖动过程由**低层鼠标钩子读取光标位置** + 窗口位置写回驱动，**不修改光标坐标**。可选 `HideCursor()`（[hooks.c:5029](M:/08_Project/VSCODE/AltSnap/hooks.c:5029)）。

### 2.5 提炼（用于本设计的复用点）

| 要点 | AltSnap 做法 | 本设计对应 |
|---|---|---|
| 作用窗口 | 光标下窗口 `WindowFromPoint` | 建议同款（可配置，见决策点） |
| 基准 | 按下时记录窗口 rect + 光标 + 抓取偏移 | 同款 |
| 移动 | `新位置 = 光标 − 抓取偏移` | 同款 |
| 缩放 | 记录边/角 + 该边偏移，`新尺寸 = 光标 − 锚点 + offset` | 采用简化版（位移驱动） |
| 防跳变 | 按下只记录，位移在 MOVE 事件才生效 | 同款（死区 + 基准位移） |
| 光标处理 | 只读 `CursorPos`，从不 `SetCursorPos` | 同款 |
| 最小尺寸 | `CLAMPW/CLAMPH` | AHK 侧常量钳制 |

---

## 三、设计方案

### 3.1 交互模型

**总原则**：触发键按下 → 进入拖拽模式（只记录基准）→ 移动鼠标 → 窗口按算法跟随 → 松开触发键 → 结束。
**全程绝不调用 `MouseMove`**，只用 `MouseGetPos` 读坐标、`SetTimer` 定时刷新。

```
按下触发键(k) ──► 记录基准(窗口rect, 光标pos, 抓取偏移)
                    │
                    ▼
            ┌── SetTimer 轮询 ──┐
            │  MouseGetPos 读光标 │
            │  位移向量 → 新几何   │
            │  WinMove(hwnd,...)  │
            └─────────┬──────────┘
                      │  松开触发键(k up)
                      ▼
             停止定时器 + 清理 + (未移动则补发原按键)
```

两种触发方式的行为差异与统一：

| | 鼠标侧键（XButton1/2 等） | 键盘键（如 Caps 模式内的某键、组合键） |
|---|---|---|
| 触发点 | 按下即进入拖拽模式 | 按下即进入拖拽模式 |
| “持续移动鼠标”语义 | **天然成立**：按住按键时鼠标本就可自由移动 | **不天然**：需用户按住该键盘键的同时移动鼠标；仍成立，但手感较别扭 |
| 单击保留 | 需要：若未移动则**补发原按键**（保住“前进/后退”等功能），沿用 [`Keymap.Wait()`](bin/lib/KeymapManager.ahk:326) 的“位移阈值判定”思想 | 一般不需要补发，可按需 |
| 结束条件 | 松开该侧键 | 松开该键盘键（或“再按一次”切换式，见下） |
| 统一处理 | 二者共用同一 `Start/Stop` 与轮询逻辑，仅“是否补发原键”与死区阈值不同 | 同左 |

> **回答用户疑问“键盘按键映射时逻辑是否成立”**：成立。键盘键没有“按住期间鼠标持续移动”的自然语义，因此明确约定为：**按下该键 → 进入拖拽模式；期间鼠标移动驱动窗口；松开该键（或再按一次，取决于模式）→ 结束**。这依赖“按键保持按下”这一状态，可用 `GetKeyState(key,"P")` 或 down/up 成对热键检测。若担心“按住键盘键 + 移动鼠标”太别扭，可提供**切换式（toggle）**：按一次开始、再按一次结束。

### 3.2 移动功能算法

**基准记录（按下时，不改窗口）**：

| 符号 | 含义 |
|---|---|
| `hwnd` | 目标窗口（光标下窗口，见 §4.1） |
| `x0,y0,w0,h0` | 窗口初始 rect（最大化先 `WinRestore`） |
| `mx0,my0` | 光标初始屏幕坐标 |
| `ox = mx0 - x0`，`oy = my0 - y0` | 抓取点相对窗口左上角的偏移 |

**每帧（轮询）**：

```
MouseGetPos(&mx,&my)
dx = mx - mx0 ; dy = my - my0
if !moved && (|dx|>DEADZONE || |dy|>DEADZONE): moved = true   ; 死区，区分单击/拖动
if moved: WinMove(mx - ox, my - oy, , , hwnd)                ; 尺寸不变，仅移动
```

**防跳变**：按下时**不做任何 `WinMove`**；只有位移超过死区后才开始移动；且 `ox/oy` 恒定 ⇒ 抓取点始终吸附光标，无初始位移。

**轴向锁定（可选增强）**：位移主轴确定后可锁定单轴（例如 `|dx|>=|dy|` 只改 x），手感更稳，避免斜向抖动。

### 3.3 缩放功能算法

**基准记录（按下时，绝不改尺寸）**：

| 符号 | 含义 |
|---|---|
| `hwnd, x0,y0,w0,h0` | 目标窗口初始 rect |
| `mx0,my0` | 光标初始坐标 |
| `moved=false` | 位移死区标志 |

**每帧**：

```
MouseGetPos(&mx,&my)
dx = mx - mx0 ; dy = my - my0
if !moved && (|dx|>DEADZONE || |dy|>DEADZONE): moved = true
if !moved: return                      ; ← 满足“按下不即时改变”
按策略计算 w,h（见下）
w = Max(w, MIN_W); h = Max(h, MIN_H)   ; 最小尺寸钳制
WinMove(x, y, w, h, hwnd)
```

**缩放策略（至少两种，供选择）**：

- **策略 (a) 按位移主轴自动选边/角**（更贴合“按鼠标移动方向”）
  - 若 `|dx| >= |dy|`：水平为主 → 只改**左右边**，`w = w0 + dx`（左/上边固定，右边界跟随光标；`dx<0` 时收缩）。
  - 否则：垂直为主 → 只改**上下边**，`h = h0 + dy`。
  - 增强变形：当 `|dx|` 与 `|dy|` 都较大时同时改 x、y 两边（即改“角”）。
  - 可选“以中心对称缩放”：`x = x0 - dx/2, w = w0 + dx`（同理 y/h），观感更居中。
- **策略 (b) 固定右下角**（最简、最可预测，类似系统 resize 抓手）
  - `w = w0 + dx; h = h0 + dy;` 左上角固定。
  - AltSnap 也内置此模式（[hooks.c:3990-3995](M:/08_Project/VSCODE/AltSnap/hooks.c:3990)）。
- **（进阶，可选）策略 (c) 抓取点九宫格**（最接近 AltSnap）
  - 按下时依据光标在窗口内的相对位置（九宫格/最近边对角线，[hooks.c:3741-3803](M:/08_Project/VSCODE/AltSnap/hooks.c:3741)）决定缩放边/角，并记录该边到光标的偏移；位移直接作用于该边。此策略“按下时只判定边、不改尺寸”，同样满足要求。

> **推荐**：默认 **策略 (a)**（符合用户“按方向改变”的描述），并把 **(b)** 作为可选项（若追求“零意外”）。**(c)** 复杂度最高，可作为后续增强。（见决策点 1）

### 3.6 DPI / 坐标系处理决策（2026-10-08 最终修订，见 §0）

**结论（方案 A）**：**全程改用原生 Win32 物理屏幕坐标**——`GetCursorPos`(读光标) / `GetWindowRect`(读窗口) / `SetWindowPos`(写窗口)，
并由 `DragHarmonizeDpi()` 在 `Start` 与每帧 `Poll` 显式把本线程上下文统一为 `PER_MONITOR_AWARE(-3)`（句柄 `18`），算完 `DragRestoreDpi()` 复原。

**为什么不只用“会话内沿用 -3”**：仅统一 DPI 上下文**并不能**解决本次根因——
根因是 AHK `CoordMode` 的**线程局部性**：`Start`(热键线程, Screen) 与 `Poll`(定时器线程, 默认 Client) 分属两个坐标系。
改用 `GetCursorPos/GetWindowRect/SetWindowPos` 后，读写**完全绕开 AHK 的 CoordMode 层**，物理屏幕坐标恒定自洽（见 §0.2、§0.3）。

**原因（实测发现的缺陷）**：早期实现按“读坐标用 `-3`、写 `WinMove` 用 `-1`”反复切换线程上下文，导致同一拖拽会话内：

1. `StartDrag` 用 `-3` 记录的 `mx0` 与 `Poll` 中（上一帧遗留 `-1` 上下文下）读到的 `mx` 坐标系不一致，产生恒定偏移 ⇒ **按下即跳变 + 跟随偏移**（实测本机 125% 缩放下偏差约 0.67 倍）。
2. 高频反复切换 `SetThreadDpiAwarenessContext` 在本环境导致 `MouseGetPos` 读数异常（出现 1500+ 的暴走值）。

因此统一：**同一会话内读写全用 `-3`**（`DragHarmonizeDpi`），`mx0` / `mx` / 窗口 rect 均取自原生 API 的物理屏幕坐标，位移量自洽。多显示器不同缩放的最终观感仍需人工实测（列入人工验收）。

### 3.5 完全拦截（不漏键）

down/up 成对注册后，触发键的**整段按下-抬起**都由本功能接管，**任何情况下都不补发/放行原触发键**：

| 情况 | 行为 |
|---|---|
| 拖动（位移超过死区 `DRAG_DEADZONE`=4px） | 由拖拽接管，**不放行** |
| 未拖动（单击 / 长按未动） | **同样不放行**原键，视作“什么都没按” |

- **理由**：绑定到鼠标侧键（`XButton1`/`XButton2`，原本是“后退/前进”）时，若在未拖动时放行原键，会在高频操作中偶发触发“后退/前进”（即用户反馈的“漏键”）。完全拦截可彻底避免。
- **实现**：[`StopDragWindow()`](bin/lib/Actions.ahk:359) 仅「停定时器 + 清理状态」，**不含任何 `Send` 补发**。
- **键名来源**：`st.key` 由 [`DragTriggerKey()`](bin/lib/Actions.ahk:41) 从 `A_ThisHotkey` 提取（去掉 `*`、` up` 等），仅用于轮询判定触发键是否仍按住。

**最小尺寸**：定义常量 `MIN_W := 200, MIN_H := 150`（可调）；如需精确对齐系统最小值，可后续用 `GetMinMaxInfo`/`WM_GETMINMAXINFO`（AltSnap 用 `CLAMPW/CLAMPH`，[hooks.c:5097](M:/08_Project/VSCODE/AltSnap/hooks.c:5097)）。

**死区**：建议移动/缩放死区 3-4px，避免手抖触发。

### 3.4 接入点清单

#### (A) 后端 Go —— [`config-server/internal/script/action.go`](config-server/internal/script/action.go:219)

在 [`windowActions3()`](config-server/internal/script/action.go:219) 中新增两个 ValueID（**避开已用的 1-16**）：

| 新 ValueID | 语义 | 建议 AHK 起始调用 |
|---|---|---|
| **17** | 拖拽移动窗口 | `StartDragMoveWindow()` |
| **18** | 拖拽缩放窗口 | `StartDragResizeWindow("axis")` |

生成形态（**down/up 成对**，沿用 [`KeymapManager.ahk:467-468`](bin/lib/KeymapManager.ahk:467) 范式；`ctx` 复用 [`GetHotkeyContext()`](config-server/internal/script/config.go:148) 以保留窗口过滤）：

```go
// 伪代码
if a.ValueID == 17 || a.ValueID == 18 {
    start, stop := "StartDragMoveWindow()", "StopDragWindow()"
    if a.ValueID == 18 {
        start = `StartDragResizeWindow("axis")`
        stop  = "StopDragWindow()"
    }
    ctx := Cfg.GetHotkeyContext(a)
    return fmt.Sprintf(
        `km.Map("%[1]s", _ => %[2]s%[3]s), km.Map("%[1]s up", _ => %[4]s)`,
        a.Hotkey, start, ctx, stop)
}
```

注意：窗口操作在“缩写命令框”上下文中不受支持（见 [`action.go:33-35`](config-server/internal/script/action.go:33) TODO），故无需处理 `inAbbrContext`。

#### (B) AHK —— [`bin/lib/Actions.ahk`](bin/lib/Actions.ahk:1)

新增函数（建议放在 [`MakeWindowDraggable()`](bin/lib/Actions.ahk:12) 附近）：

| 函数 | 作用 |
|---|---|
| `StartDragMoveWindow()` | 按下：记录基准，`SetTimer(PollDragMoveWindow, 10)` |
| `PollDragMoveWindow()` | 轮询：读光标 + `WinMove` |
| `StopDragWindow()` | 松开：停定时器、清理状态（移动/缩放共用） |
| `StartDragResizeWindow(strategy)` | 同移动，但记录 rect 且策略驱动 |
| `PollDragResizeWindow()` | 轮询：按策略算 w/h、最小尺寸钳制、`WinMove` |
| `StopDragWindow()` | 同上（移动/缩放共用同一 Stop） |

依赖的**既有工具函数/范式**：`ExtractWaitKey()`（[KeymapManager.ahk:666](bin/lib/KeymapManager.ahk:666)）、`WindowMaxOrMin()`（[Functions.ahk:502](bin/lib/Functions.ahk:502)）、`WinRestore`、`Tip()`（[Utils.ahk:7](bin/lib/Utils.ahk:7)）、`SetTimer`。

设计要点（伪代码，示意）：

```ahk
WindowDragState := false

StartDragMoveWindow() {
  global WindowDragState
  if WindowDragState
    return
  CoordMode("Mouse", "Screen")
  MouseGetPos(&mx0, &my0, &hwndUnderCursor)          ; 只读光标
  hwnd := hwndUnderCursor ? hwndUnderCursor : WinExist("A")
  if !hwnd
    return
  if WinGetMinMax(hwnd)
    WinRestore(hwnd)
  WinGetPos(&x0, &y0, &w0, &h0, "ahk_id " hwnd)
  WindowDragState := {
    key: ExtractWaitKey(A_ThisHotkey),
    hwnd: hwnd, mx0: mx0, my0: my0,
    ox: mx0 - x0, oy: my0 - y0, moved: false
  }
  SetTimer(PollDragMoveWindow, 10)
}

PollDragMoveWindow() {
  global WindowDragState
  st := WindowDragState
  if !st
    return
  MouseGetPos(&mx, &my)
  if !st.moved && (Abs(mx - st.mx0) > 3 || Abs(my - st.my0) > 3)
    st.moved := true
  if st.moved && WinExist("ahk_id " st.hwnd)
    WinMove(mx - st.ox, my - st.oy, , , "ahk_id " st.hwnd)
}
```

> **无需**单独注册 `up` 热键也能实现（在 `Poll` 内用 `GetKeyState(key,"P")` 自查并自停）；但**推荐**用 down/up 成对注册（与 §3.4A 一致），把“结束”放在 `up` 处理器里，语义最清晰、且保证按键绝不会卡住。

#### (C) 前端 —— [`config-ui/src/components/actions/Window.vue`](config-ui/src/components/actions/Window.vue:4)

在 `group2` 追加两个选项（沿用现有结构）：

```ts
const group2 = [
  ...,
  { actionValueID: 13, label: "label:15" },
  { actionValueID: 14, label: "label:16", hideInAbbr: true },
  { actionValueID: 17, label: "label:1701" },   // 拖拽移动窗口
  { actionValueID: 18, label: "label:1702" },   // 拖拽缩放窗口
]
```

#### (D) 翻译标签 —— [`config-ui/src/store/language-map.ts`](config-ui/src/store/language-map.ts:6)

因 key 是**全局扁平**的（窗口段已占 1-16，系统段从 17 起），新标签须取**空闲号段**（建议 1701/1702，并预留 1703 给缩放策略文案）：

```ts
// window (新增，避开 1-16 与系统段 17+)
1701: { zh: "拖拽移动窗口", en: "Drag to move window" },
1702: { zh: "拖拽缩放窗口", en: "Drag to resize window" },
1703: { zh: "缩放方式：按移动方向/固定右下角", en: "Resize: follow direction / bottom-right" },
```

（若最终需要“缩放策略”单选项，可在 `Window.vue` 用一个 `group3` + 新 ValueID 19/20 承载，对应 label 1704/1705。）

---

## 四、边界与风险

### 4.1 作用窗口：光标下窗口 vs 前台窗口

- AltSnap 作用**光标下窗口**（[hooks.c:5037](M:/08_Project/VSCODE/AltSnap/hooks.c:5037)）。
- 现状 [`MakeWindowDraggable()`](bin/lib/Actions.ahk:12) 作用**前台窗口** `WinExist("A")`。
- **建议**：默认“光标下窗口”，回退到前台窗口（与 AltSnap 一致，且用户用鼠标侧键触发时“指哪拖哪”最自然）。**见决策点 2**。

### 4.2 多显示器 / DPI

- 读坐标（`MouseGetPos`）与写窗口（`WinMove`）的 DPI 感知要求不同（详见 §1.5；[`Actions.ahk:188-190`](bin/lib/Actions.ahk:188) 注释明确说明）。
- 风险：混合 DPI 多显示器下，可能出现位移比例偏差/漂移。
- **建议**：实现时按 §1.5 注释分别设置读写时的 `SetThreadDpiAwarenessContext`（读 `-3`、写 `-1`），并在混合 DPI 环境实测；本设计将其列为**必须验证项**。

### 4.3 最大化 / 全屏 / 特殊窗口

- 最大化窗口需先 `WinRestore`（沿用 [`Actions.ahk:14`](bin/lib/Actions.ahk:14)）。
- 全屏/无边框/游戏窗口、带自定义非客户区的窗口，`WinMove` 可能无效或异常；建议对 `WindowMaxOrMin`、桌面窗口（沿用 [`NotActiveWin()`](bin/lib/Functions.ahk:597)）做跳过。
- 最小化窗口无几何意义，应跳过。

### 4.4 触发键冲突

- 若触发键同时用于其他功能（如 XButton1 默认“上一个虚拟桌面”，[`MyKeymap.ahk:234`](bin/MyKeymap.ahk:234)），按下即被本功能接管：
  - 采取“**未位移则补发原按键**”（沿用 [`Keymap.Wait()`](bin/lib/KeymapManager.ahk:326) 的按钮判定思想），可保住单击语义；但**长按 + 微动**仍会吞掉原功能。
  - 需在 UI/文档提示“该选项会接管触发键的长按行为”。

### 4.5 结束条件

- 首选：松开触发键（`"*<key> up"` 热键）。
- 兜底：`Poll` 内 `GetKeyState(key,"P")` 为假时自停，**防止按键卡住导致窗口一直被拖动**。
- 额外：窗口被关闭（`WinExist` 失效）时自停。

### 4.6 与 `MouseKeymap`（鼠标模式）是否冲突

- 鼠标侧键多注册在右键 keymap（如 `km16`，[`MyKeymap.ahk:232`](bin/lib/MyKeymap.ahk:232)）内。按下 `RButton` 会激活该 keymap 并进入其 [`Wait()`](bin/lib/KeymapManager.ahk:299)（鼠标分支会轮询位移）。
- 本设计在**触发键 up 即停**，且**不调用 `MouseMove`**，因此不会触发 `MouseKeymap._moveMouse()` 的“相对移动光标”逻辑。
- 风险：`SetTimer` 轮询与 `MouseKeymap` 的 `KeyWait` 阻塞线程并存时需验证调度是否顺畅；建议死区阈值与 `Keymap.Wait()` 的 10px 阈值保持一致的量级，避免同一手势被两处同时解释。

---

## 五、需要用户拍板的关键决策点

1. **缩放策略选 (a) 还是 (b)？**
   - (a) 按位移主轴自动选边/角（贴合“按方向改变”，推荐）
   - (b) 固定右下角（最可预测）
   - 或 (c) 抓取点九宫格（最像 AltSnap，复杂度最高）

2. **拖拽作用窗口取“光标下窗口”还是“前台窗口”？**
   - 建议：默认“光标下窗口”（AltSnap 同款），回退前台窗口；是否需要做成可配置项？

3. **是否保留旧版 [`MakeWindowDraggable()`](bin/lib/Actions.ahk:12)（ValueID=13）？**
   - 建议保留（不破坏既有配置），新增 17/18 两个 ValueID 并存；还是直接替换 13 的行为？

4. **触发方式默认取哪种？**
   - 按住式（松开即停，鼠标侧键自然）为默认
   - 是否额外提供“切换式（按一次开始、再按一次结束）”，以缓解键盘键“按住 + 移动鼠标”的别扭手感？

---

## 六、后续实现步骤（供切换模式后执行）

1. 后端 [`action.go`](config-server/internal/script/action.go:219)：新增 ValueID 17/18 的 down/up 生成逻辑。
2. AHK [`Actions.ahk`](bin/lib/Actions.ahk:12)：实现 `Start/Poll/Stop` 六个函数（移动 + 缩放），含死区、最小尺寸、DPI 处理、未位移补发原键。
3. 前端 [`Window.vue`](config-ui/src/components/actions/Window.vue:4)：追加两个选项（及可选策略项）。
4. 翻译 [`language-map.ts`](config-ui/src/store/language-map.ts:6)：新增 1701/1702（+1703…）标签。
5. 生成模板无需改动（[`mykeymap.tmpl`](bin/templates/mykeymap.tmpl:38) 不涉及动作生成）。
6. 测试：鼠标侧键（XButton1/2）触发、键盘键触发、多显示器混合 DPI、最大化窗口、最小尺寸边界、与鼠标模式共存。
