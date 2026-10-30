# tools/e2e —— 进程级 E2E 与 git 二分工具

本轮诊断（故障1 拖拽不生效 / 故障2 长按只生效一次）留下的可复用资产。
**层级与 [`tools/harness/lib_test.ahk`](../harness/lib_test.ahk) 不同**：
harness 测"函数被调用后内部状态对不对"，本目录测"用某个 commit 的真实 lib，
外部驱动后真实行为是什么"。

---

## 一、结论摘要（本目录存在的理由）

| 工具 | 能回答什么 | 可靠度 |
|---|---|---|
| `run_e2e.py` + `inject.py` + `receiver.ahk` | 真实生成物启动后，注入按键后屏幕上出现什么 | **低**（受真人操作/IME/抢前台污染，见下） |
| `make_variant.py` + `make_shadow.py` + `run_shadow_all.py` | 对任意 commit 做**同一实验**，进程内观察真实 lib 行为 | **高**（不碰桌面） |
| `probe_repeat_enable_n.py` | 重复 `Enable` 是否被阻塞式 `MsgBox` 挂死（故障2 机制） | **高**（多次采样） |
| `probe_keystate.py` | 注入的按键是否让 `GetAsyncKeyState` 0x8000 置位 | **高** |
| `report.py` | 汇总全部变体 → 二分表 | — |

---

## 二、当前机器上的硬限制（实测，别再踩）

1. **本机有真人同时使用**。静默 6 秒、零注入，低级键盘钩子捕获到 **72 个物理按键**
   （`vk=75/65/68/73`）。因此"前台 Edit 收到了几个字符"**不可用**作判据。
2. **中文 IME 污染**：注入 `a` 在 Edit 里落地成 `"话"`。
   → `receiver.ahk` 已用 `ImmAssociateContext(hwnd, 0)` 关闭输入法上下文。
3. **有程序每秒抢前台**（实测 `StreetFighter6.exe` 每 ~1.5s 抢一次）。
   → `inject.py` 的 `jump` 动作把 `AttachThreadInput + TOPMOST + SetForegroundWindow`
   与后续按键放在**同一个注入进程**里，中间不 sleep。
4. **AHK 会忽略本脚本 `Send` 产生的键**，所以：
   - 注入必须跨进程（`inject.py`，Python 独立进程）；
   - 想触发自家热键不能用 `Send`，只能直接调用函数（`make_shadow.py` 就是这么做的）。
5. **注入 CapsLock 会翻转系统 CapsLock 状态**（实测 `toggled 0→1`），
   导致后续注入的 `q` 落地成 `Q`。必须传真实扫描码 `sc=0x3A`。
6. **AHK 反复 `Hotkey On/Off` 会让第三方低级键盘钩子失效**：
   自己写的 `WH_KEYBOARD_LL` 探针在 MyKeymap 运行期间**收不到任何事件**，
   所以不要用它做判据（本轮已放弃该路线）。

---

## 三、怎么跑

### 3.1 干净、可复现的部分（推荐）

```powershell
# 1) 把 8 个待二分 commit 的 lib 导出成独立变体目录
python tools\e2e\build_all_variants.py

# 2) 进程内 shadow 测试（S0..S7），每变体一份 shadow.log
python tools\e2e\run_shadow_all.py

# 3) 汇编二分表
python tools\e2e\report.py

# 4) 故障2 的机制验证（重复 Enable 是否被 MsgBox 挂死），5 次采样
python tools\e2e\probe_repeat_enable_n.py

# 5) 注入可行性验证（GetAsyncKeyState 0x8000）
python tools\e2e\probe_keystate.py
```

变体落在 `_e2e_variants/<tag>/`，包含：
- `bin/lib/*.ahk` —— **来自目标 commit**（不是 HEAD）
- `bin/MyKeymap.ahk` —— 工作区当前生成物副本（生成物被 gitignore）
- `data/` —— `config.json` / `custom_functions.ahk` **只读副本**
- `shadow.ahk` —— 进程内测试入口

> 变体目录里的 `data/` 是副本。`SetWorkingDir("../")` 后 `../data/...`
> 解析到副本目录，**不会碰到真实 `data/config.json`**。

### 3.2 真实桌面 E2E（仅限受控机器）

```powershell
python tools\e2e\run_e2e.py --cases A,A2,B,C,D,E,F --json-out result.json
python tools\e2e\run_e2e.py --entry "_e2e_variants\baseline\bin\MyKeymap.ahk" --cases A,C
```

`run_e2e.py` 自带：
- 负向自检（未启动被测脚本时注入 `a` 必须收到），失败即 `rc=4` 并拒绝出数
- 注入进程 `CREATE_NO_WINDOW`（否则控制台窗口抢走前台）
- 每用例重复 5 次，按目标字符取最优
- `aim()` 光标复读校验，拿不到就报 `PROBE_INVALID` 而不是功能 FAIL
- 观察端 90s / 180s 自杀定时器

**即使如此，A/B/C（字符类）在本机仍不可信**；只有 D/E/F（窗口矩形）可用，
因为键盘输入不会移动窗口，天然免疫真人干扰。

---

## 四、依赖

- `bin\AutoHotkey64.exe`（仓库自带 2.0.19）
- Python 3.8+（仅标准库 `ctypes`/`subprocess`/`json`）
- Windows（用到 `SetWindowsHookEx` / `AttachThreadInput` / DWIN）

`hook_probe.py`（`WH_KEYBOARD_LL` + `LLKHF_INJECTED` 过滤）本轮验证过可实现，
但因限制 6 已从判据中移除；如需保留，注意它只能在没有 AHK 热键重注册时使用。

---

## 六、故障2 定论（2026-10，本轮新增）

**结论：`f26e24a` 引入的 `KeymapWaitRelease()` 在"触发键被本进程热键吞掉"时，
用不可信的键态查询判定"已松开"，导致按住期间提前 `Disable()` 子热键。**

### 决定性数据（`tools/harness/lib_test.ahk` T14，进程内 `keybd_event`，可稳定复现）

| 场景 | async | phys | logical | `KeyWait(T0.05)` | 说明 |
|---|---|---|---|---|---|
| 未装热键 | 39/62 为真 | 39/62 | 39/62 | 正常阻塞 | 键态查询可信 |
| 注册 `*CapsLock`（吞键） | **0/60** | **0** | **0** | **秒返回 1** | 键态查询**全部不可信** |
| 注册 `~*CapsLock`（透传） | 39/62 | **0** | 39/62 | 秒返回 1 | `phys` 仍然恒 0 |

关键补充：吞键时 `KeyWait` 在**主线程 / 定时器线程 / 热键回调线程**里都立刻返回 1
（`probe_timer_keywait.py` 27 次采样全部 `kw=1 dt=0`），所以"换成别的线程去 KeyWait"
不是解法。唯一可靠信号是该键自己的 `up` 热键事件：`*X up` 注入 3/3 成对到达，
up 事件驱动等待 `dt≈906ms`（`probe_up_event.py` / `probe_up_signal_fix.py`）。

### 修复要点（`bin/lib/KeymapManager.ahk`）

1. `KeymapIsKeySwallowed(key)`：查本进程注册表（Stack 各 keymap 的 `M` 表），
   判断该键是否有**已启用的 down 热键**。只读注册表，不做键态查询。
2. 被吞键 → 走 `KeymapWaitUpEvent()`，装临时 `*X up` 热键并用 `Sleep` 轮询标志位
   （`Sleep` 会让出线程，up 回调能插进来；`KeyWait` 那条路被抑制逻辑坑了）。
3. 未被吞键 → 保留原 `KeyWait` + 键态复核快路径（此时两者都可信，"已松开"可秒返回）。

### 副作用警告（写新 E2E 时必看）

- **跨进程注入在这个场景下不保真**：`inject.py` 注入的 CapsLock down 在吞键钩子下
  既不置 async 也不置逻辑键态，所以"跨进程注入 + 观察键态"会得到全 0 的假阴性。
  进程内 `keybd_event`（harness T14 用的方式）才能稳定造出现场。
- 变体脚本的 `#Include` 是**相对脚本所在目录**解析，不是相对 cwd：
  变体根目录下的探针写 `bin\lib\...` 才行，放在 `tools/e2e/` 下要写 `..\..\bin\lib\...`。
- 探针 `.ahk` 必须带 BOM，否则中文注释被按 ANSI 读，`/validate` 通过但运行 exit 2 且无输出。

---

## 六bis、故障1 定论（拖拽不生效，本轮追加）

**结论：`c574728` 引入的 `DragSessionAlive()` 三条闸门里有两条在常见条件下立刻误杀会话；
正确做法是"退出只靠 up 热键事件 + 硬超时 + 窗口销毁兜底"，不再查询键态、不再比对前台。**

### 决定性数据（进程内 `mouse_event` 注入侧键，`tools/harness/lib_test.ahk` T15 复现，3 次采样一致）

| 注册形态 | `GetAsyncKeyState(0x8000)` | `GetKeyState(P)` | `DragKeyPhysicallyDown` | up 热键是否成对到达 |
|---|---|---|---|---|
| 无热键（基准） | 1/1/1 | 1/1/1 | 1/1/1 | — |
| `*XButton1`（**吞键 = 生产形态**，同 `km.Map("XButton1", ...)`） | **0/0/0** | **0/0/0** | **0/0/0** | **是**（down 1 次 / up 2 次） |
| `~*XButton1`（透传） | 1/1/1 | 1/1/1 | 1/1/1 | 否（透传不拦截，未注册等效） |

与故障2（`CapsLock`）完全同源：**被本进程钩子吞掉的键，系统键态表从头到尾不置位**。
所以条件1「触发键物理键态」对侧键恒为 false ⇒ 会话在第一个轮询帧（10ms）被杀。

### 修复（`bin/lib/Actions.ahk`）

1. 删除条件1「触发键物理键态」与条件3「前台窗口变了（比 `fg0`）」。
2. `DragSessionAlive()` 只留：被拖窗口已销毁（`IsWindow`）、硬超时 `DRAG_HARD_TIMEOUT_MS`。
3. 会话正常结束 = 触发键自己的 up 热键事件 → `StopDragWindow()` → 内部 `A_ThisHotkey`
   归属判定（`XButton1 up` 只停 XButton1 的会话），该机制**保留不动**。
4. 一并清掉死字段/死全局：`fg0`、`lostFocusFrames`、`DRAG_LOSTFOCUS_FRAMES`、
   `DRAG_TEST_MODE`（键态闸门没了，它也没有存在意义）。

### 4 场景实测（`GetWindowRect` 序列，`DRAG_HARD_TIMEOUT_MS=30000`）

| 场景 | before | after | Δ |
|---|---|---|---|
| S1 窗口已激活 | (1012,510,536x419) | (1060,558,536x419) | (+48,+48) |
| S2 窗口未激活（另一窗口在前台） | (1012,510,536x419) | (1060,558,536x419) | (+48,+48) |
| S2 续：拖拽中该窗口被激活（`fg` 25762530→22681938，旧闸门在此必杀） | (1060,558) | (1108,606) | (+48,+48) |
| S3 中途切到别的窗口（侧键仍按住） | (1060,558) | (1108,606) | (+48,+48) |
| S3 续：松开侧键后继续动光标（必须不动） | (1108,606) | (1108,606) | (0,0) |
| S4 长拖拽到 29s（仍存活） | — | (1065,553) | 跟随中 |
| S4 31s 采样点（已被硬超时终止） | — | (1069,557) | 会话已清空 |

> S4 的 hard-timeout 观测点落在 29s~31s 之间（采样间隔 250ms + 检查节奏所致），
> 生产值 30s 的语义不变。

### 副作用警告（写新探针时必看）

- **探针必须按生产 include 顺序载入**：只 `#Include Actions.ahk` 会缺 `Functions.ahk` 的
  `ExtractWaitKey()`（`DragTriggerKey()` 依赖它），热键线程抛错后 AHK 弹**阻塞式**错误框，
  现象是"脚本挂了但日志只写了一半"。顺序见 `tools/harness/lib_test.ahk` 顶部。
- 本机窗口管理器会把**每个**新建 Gui 居中，两个 Gui 必然同心重叠。
  需要"另一个窗口在前台 + 光标仍命中被测窗口"时，必须把光标偏开
  （harness 的 `AimDragProbe(..., offX, offY)` 就是为此加的），否则 `WindowFromPoint`
  会拿到覆盖在上面的那个窗口。
- 计时断言不要用"开始等待的时刻"当基准：`Sleep 150` 会吃掉一部分超时预算。
  用会话自己的 `WindowDragState.t0`。

---

## 五、建议

**不要把本目录并入 `tools/harness/`**：harness 是"内部状态断言"，零外部依赖、
可进 `run_verify.ps1`；本目录需要真实桌面/真实进程，属另一层级。

推荐处置：
- `make_variant.py` / `make_shadow.py` / `run_shadow_all.py` / `report.py` /
  `probe_repeat_enable_n.py` → **保留为正式资产**（不碰桌面，稳定可复现）
- `run_e2e.py` + `receiver.ahk` + `drag_target.ahk` + `inject.py`
  → 保留，但**只在受控机器上跑**，且必须看它自己的负向自检结果
- `_e2e_variants/`（~1.6MB 临时产物）→ **不要提交**，随时可重新生成
