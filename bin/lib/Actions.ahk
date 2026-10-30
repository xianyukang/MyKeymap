/**
 * 移动鼠标到活动窗口中心
 */
MouseToActiveWindowCenter() {
  WinGetPos(&X, &Y, &W, &H, "A")
  MouseMove(x + w / 2, y + h / 2)
}

/**
 * 移动活动窗口位置 (B-1: 已改为非模态实现)
 *
 * 原实现:
 *   PostMessage(WM_SYSCOMMAND(0x0112), SC_MOVE(0xF010), 0) + Sleep 50 + SendInput("{Right}")
 *   PostMessage 让窗口进入 Windows 的 **移动模态循环**(DefWindowProc 内部捕获鼠标),
 *   再补发一次方向键让模态循环挪一格, 而 **从不发送 Enter/Esc 收尾**。
 *   模态循环在收到 Enter/Esc 或鼠标右键前不会返回, 期间系统独占鼠标:
 *   其它窗口全部无法点击 —— 这正是用户报告"窗口操作后其它窗口点不动, 只能 Win+L"的成因。
 *
 * 现实现(方案 b: 一次性计算 + 单次 WinMove):
 *   - 不进入 SC_MOVE, 不产生任何系统模态;
 *   - 无 SetTimer / 无轮询 / 无循环;
 *   - 进入函数后必然在常数时间内返回, 返回后不遗留模态状态或定时器。
 * 语义: 保持窗口尺寸, 把窗口平移到以当前光标为中心的位置(并夹在光标所在监视器的工作区内)。
 * 该功能与侧键拖拽(StartDragMoveWindow)能力重叠, 保留它只是为了不丢失 CapsLock+. 这个入口。
 */
MakeWindowDraggable() {
  hwnd := WinExist("A")
  if !hwnd
    return
  ; 最小化窗口无几何意义, 直接返回
  if (WinGetMinMax(hwnd) = -1)
    return
  if (WindowMaxOrMin(hwnd))
    WinRestore(hwnd)

  WinGetPos(&wx, &wy, &ww, &wh, "ahk_id " hwnd)
  if (!ww || !wh)
    return
  ; 用原生 GetCursorPos 读物理屏幕坐标: 与 WinGetPos/窗口坐标同源,
  ; 不用 MouseGetPos —— v2 的 CoordMode 是线程局部设置, 默认 Client 系,
  ; 与窗口坐标混用会导致偏移(本文件 DragRawCursor 注释已详述该坑)。
  gcx := 0, gcy := 0
  DragRawCursor(&gcx, &gcy)
  tx := gcx - ww // 2
  ty := gcy - wh // 2
  ; 夹到光标所在监视器的工作区, 避免窗口被移出可视范围
  loop MonitorGetCount() {
    MonitorGet(A_Index, &ml, &mt, &mr, &mb)
    if (gcx >= ml && gcx < mr && gcy >= mt && gcy < mb) {
      MonitorGetWorkArea(A_Index, &al, &at, &ar, &ab)
      tx := Min(Max(tx, al), ar - ww)
      ty := Min(Max(ty, at), ab - wh)
      break
    }
  }
  ; 单次写入, 无后续动作
  WinMove(tx, ty, ww, wh, "ahk_id " hwnd)
  OutputDebug("[MyKeymap] MakeWindowDraggable(非模态) hwnd=" hwnd " -> (" tx "," ty ")")
}

; ─────────────────────────────────────────────────────────────
; 拖拽移动窗口 / 拖拽缩放窗口
;
; 按下时只记录基准(窗口几何 + 光标位置 + 抓取偏移), 由 SetTimer 轮询鼠标位移,
; 位移超过死区后才写窗口几何; 松开触发键立即停止.
; 全程使用原生 Win32 物理屏幕坐标(GetCursorPos/GetWindowRect/SetWindowPos),
; 只读光标、写窗口, 绝不调用 MouseMove/SetCursorPos.
; down 热键只记录基准, 由触发键自己的 **up 热键事件**结束(不查键态, 因为侧键
; 热键是吞键形态, 按住期间键态恒 false); 只剩下硬超时与窗口销毁两条兜底.
;
; 拦截策略: 完全拦截, 任何情况下都不补发/放行原触发键 ——
;   未拖动(单击/长按未动)不放行原键(视作什么都没按), 拖动时由拖拽接管.
; ─────────────────────────────────────────────────────────────

global WindowDragState := false
global DRAG_DEADZONE := 4                       ; 死区(px), 超过才认为"开始拖动"
global DRAG_MIN_W := 120, DRAG_MIN_H := 80      ; 缩放的最小宽高
; 会话的**正常**结束靠触发键自己的 up 热键事件
; (生成物: km.Map("XButton1 up", _ => StopDragWindow())), 不靠任何键态查询。
; 下面的硬超时是与会话语义无关的最后一道时间兜底: 即使 up 事件因为任何原因
; 没到达, timer 也绝不会无限跟随光标(每 10ms 一次 SetWindowPos 会把用户所有
; 点击吃掉), 到点必停。30s 远长于任何正常拖拽, 不会误杀。
global DRAG_HARD_TIMEOUT_MS := 30000            ; 单次拖拽会话最长 30s, 到点必停
; 调试日志开关(默认关闭). 开启时写 A_ScriptDir\drag_debug.log, 便于真实使用中取证.
global DRAG_DEBUG := false

/**
 * 拖拽轮询的退出闸门 —— 只做**兜底**, 不做"用户意图"判断
 *
 * 会话的正常结束由触发键的 up 热键事件驱动:
 *   生成物里是 km.Map("XButton1 up", _ => StopDragWindow()) (XButton2 up 同理),
 *   StopDragWindow() 内部按 A_ThisHotkey 做按键归属判定, 只停自己那个会话。
 * 这里只保留两条与会话语义无关的兜底:
 *   1) 被拖窗口已销毁 —— 继续写几何只会反复失败, 必须收尾;
 *   2) 硬超时 DRAG_HARD_TIMEOUT_MS (A_TickCount 基准) —— 到点必停。
 *
 * ── 为什么这里**不能**用键态判断"用户松手了"(踩过的坑, 别再改回去) ──────
 * 生产形态的侧键热键是**吞键**的(km.Map("XButton1", ...) => *XButton1)。
 * 实测(进程内探针 + tools/harness/lib_test.ahk T15, 3 次采样均一致):
 *     形态                        GetAsyncKeyState(0x8000)  GetKeyState(P)  DragKeyPhysicallyDown
 *     无热键(基准)                          1                   1                1
 *     *XButton1  (吞键 = 生产形态)          0                   0                0
 *     ~*XButton1 (透传)                     1                   1                1
 * 即: 被本进程钩子吞掉的键, 系统键态表**从头到尾不置位**。
 * 所以"键态显示已松开"不是"用户松手了", 而是**按住期间一直如此**。
 * 拿键态当退出条件 => 会话在第一个轮询帧就被杀掉 => 用户感受是
 * "侧键拖拽完全没生效"。这是故障1 的第二个成因(由 c574728 引入)。
 * 唯一可靠的信号是该键自己的 up 热键事件(实测成对到达, 见 T12/T15)。
 *
 * ── 为什么这里也**不能**用"前台窗口变了"判断退出(踩过的坑, 别再改回去) ──
 * 旧实现比对的是**会话开始时的前台窗口**(fg0), 不是被拖的窗口:
 *   - 侧键按下瞬间前台经常会变: 系统激活 DragWindowFromPoint 命中的未激活窗口、
 *     输入法候选窗、鼠标手势/窗口管理软件。于是会话在约 30ms 内就被判"用户切走了";
 *   - 拖动一个未激活窗口时, 该窗口随之被激活本来就是**正常且常见**的行为;
 *   - 用户真要切窗口时会自然松开侧键, up 热键会收尾 —— 这个闸门解决不了任何
 *     真实问题, 只会误杀。
 * 实测(tools/e2e/run_shadow_all.py, c574728 变体):
 *     fg0=2694154 fg1=3349508 前台已变=1 => 闸门帧序列 S2 frames=TTF
 *     lostFrames=3 state=已清空  (即 30ms 就停)
 *
 * 一旦判定应停, 这里直接调用 StopDragWindowForKey("") 收尾
 * (停两个轮询 timer + 清空 WindowDragState)。
 * 用强制版而不是 StopDragWindow(): 闸门是**内部判定**, 必须无条件收尾;
 * 而 StopDragWindow() 会看 A_ThisHotkey 做"按键归属"判定(见该函数),
 * 在 timer 线程里 A_ThisHotkey 是上一热键的残留值(已实测), 走归属判定会误挡。
 * 调用方 return 即可, 不存在"知道该停却没停"的路径。
 *
 * @returns {boolean} true 表示会话仍然有效, 可以继续本帧处理; false 表示已停止
 */
DragSessionAlive(st) {
  global DRAG_HARD_TIMEOUT_MS
  ; 兜底 1: 被拖窗口已销毁
  if !DllCall("IsWindow", "ptr", st.hwnd) {
    DragLog("[Gate] window destroyed: " st.hwnd)
    StopDragWindowForKey("")
    return false
  }
  ; 兜底 2: 硬超时 —— 与会话语义无关的时间上限, 绝不误杀正常拖拽
  if (A_TickCount - st.t0 >= DRAG_HARD_TIMEOUT_MS) {
    DragLog("[Gate] hard timeout " DRAG_HARD_TIMEOUT_MS "ms, force stop")
    OutputDebug("[MyKeymap] 拖拽会话硬超时, 强制收尾: key=" st.key " mode=" st.mode)
    StopDragWindowForKey("")
    return false
  }
  return true
}

/**
 * 调试日志 (仅 DRAG_DEBUG=true 时写文件)
 */
DragLog(s) {
  global DRAG_DEBUG
  if !DRAG_DEBUG
    return
  try FileAppend(s "`r`n", A_ScriptDir . "\drag_debug.log", "UTF-8")
}

/**
 * 清空调试日志 (每次 Start 调用)
 */
DragLogReset() {
  global DRAG_DEBUG
  if !DRAG_DEBUG
    return
  try FileDelete(A_ScriptDir . "\drag_debug.log")
}

/**
 * 原生 Win32 读光标物理屏幕坐标 (唯一的光标读取入口)
 *
 * 为什么不用 MouseGetPos: AHK v2 的 CoordMode 是 **线程局部** 的, 且默认值为
 * Client(相对活动窗口). 热键线程执行过 CoordMode("Mouse","Screen") 后,
 * SetTimer 建立的 **定时器线程** 并不会继承该设置, 其 A_CoordModeMouse 仍是
 * 默认 Client. 于是 Start(热键线程, Screen) 记录的基准, 与 Poll(定时器线程,
 * Client) 读到的坐标分属两个坐标系 → 首帧位移暴走(跳变) + 参照系随窗口移动
 * 产生反馈 → 疯狂抖动. 这正是本次的真实根因.
 * GetCursorPos 恒返回物理屏幕坐标, 与线程/CoordMode/DPI 层无关, 从根上杜绝该类问题.
 */
DragRawCursor(&x, &y) {
  pt := Buffer(8, 0)
  DllCall("GetCursorPos", "ptr", pt)
  x := NumGet(pt, 0, "int")
  y := NumGet(pt, 4, "int")
}

/**
 * 原生 Win32 读窗口物理屏幕矩形 (GetWindowRect, 唯一的窗口读取入口)
 */
DragRawRect(hwnd, &x, &y, &w, &h) {
  rc := Buffer(16, 0)
  DllCall("GetWindowRect", "ptr", hwnd, "ptr", rc)
  x := NumGet(rc, 0, "int")
  y := NumGet(rc, 4, "int")
  w := NumGet(rc, 8, "int") - x
  h := NumGet(rc, 12, "int") - y
}

/**
 * 取光标处应操作的**顶层窗口** (物理屏幕坐标入参)
 *
 * WindowFromPoint 可能返回子控件(如记事本的 Edit), 若直接对其 SetWindowPos 只会移动控件本身.
 * 故用 GetAncestor(GA_ROOT=2) 上溯到顶层窗口; 上溯失败再退回 WindowFromPoint 结果.
 */
DragWindowFromPoint(x, y) {
  wfp := DllCall("WindowFromPoint", "int64", (y << 32) | (x & 0xFFFFFFFF), "ptr")
  if !wfp
    return 0
  root := DllCall("GetAncestor", "ptr", wfp, "uint", 2, "ptr")   ; GA_ROOT
  return root ? root : wfp
}

/**
 * 原生 Win32 写窗口物理几何 (SetWindowPos, 唯一的窗口写入入口)
 * flags 见 SWP_*; 调用方保证传 NOZORDER|NOACTIVATE, 避免置顶/激活副作用.
 */
DragSetWindowPos(hwnd, x, y, w, h, flags) {
  DllCall("SetWindowPos", "ptr", hwnd, "ptr", 0, "int", x, "int", y, "int", w, "int", h, "uint", flags)
}

/**
 * 当前线程 DPI 感知上下文句柄
 * 18 == GetThreadDpiAwarenessContext(SetThreadDpiAwarenessContext(-3)) 的句柄值
 * (PER_MONITOR_AWARE_V2)
 */
DragCtx() {
  return DllCall("GetThreadDpiAwarenessContext", "ptr")
}

/**
 * 把本线程 DPI 感知上下文统一为 PER_MONITOR_AWARE(-3), 返回切换前的句柄以便恢复.
 * 在 Start 与每帧 Poll 都调用: 保证 GetCursorPos / GetWindowRect / SetWindowPos
 * 在整个拖拽会话内始终处于同一 DPI 上下文, 杜绝混用导致的坐标系/比例不一致.
 */
DragHarmonizeDpi() {
  raw := DragCtx()
  if (raw != 18)
    try DllCall("SetThreadDpiAwarenessContext", "ptr", -3, "ptr")
  return raw
}

/**
 * 恢复切换前的 DPI 上下文句柄 (与 DragHarmonizeDpi 配对)
 */
DragRestoreDpi(raw) {
  if (raw != 18)
    try DllCall("SetThreadDpiAwarenessContext", "ptr", raw, "ptr")
}

/**
 * 从热键名中提取用于 GetKeyState 的物理按键名
 * 注意: up 热键形如 "*XButton1 up", ExtractWaitKey() 会保留 " up" 后缀
 * (空格不在其 Trim 集合内), 必须去掉 " up" 才能被 GetKeyState 正确识别,
 * 否则 GetKeyState("<key> up", "P") 恒为 false, 轮询会首帧自停.
 */
DragTriggerKey(hotkey) {
  return RegExReplace(ExtractWaitKey(hotkey), "i)\s+up$", "")
}

/**
 * 拖拽移动窗口
 * 按下时仅记录基准, 由 SetTimer 轮询鼠标位移后移动窗口.
 * 根因修复: 新 down 到来时若旧会话仍在, 先安全收尾旧会话再开新会话。
 *   - 绝不直接丢弃按下 (旧代码: if WindowDragState return)
 *   - 会话结束由触发键的 up 热键事件驱动(见 DragSessionAlive 的说明)
 */
StartDragMoveWindow() {
  global WindowDragState
  ; 根因修复: 新 down 先安全收尾旧会话, 再开新会话。不丢弃本次按下。
  ; 注意: 这里不再 ReleaseCapture —— 实测(见 tools/harness/lib_test.ahk T13)
  ; 拖拽会话期间本线程 GetCapture() 恒为 0(生产路径从不 SetCapture),
  ; 而真正冻结点击的捕获由前台窗口(可能是别的进程)持有,
  ; 本进程的 ReleaseCapture 跨线程/跨进程无效, 只会造成"已处理"的错觉。
  if WindowDragState
    StopDragWindowForKey("")
  ; 全程使用原生 Win32 物理屏幕坐标: GetCursorPos / GetWindowRect / SetWindowPos.
  ; 不再依赖 AHK 的 MouseGetPos/WinGetPos/WinMove, 因而与 CoordMode 线程局部性、
  ; AHK DPI 层均无关, 从根上杜绝"Start/Poll 坐标系不一致"导致的跳变与抖动.
  raw := DragHarmonizeDpi()
  DragRawCursor(&mx0, &my0)                    ; 只读光标, 绝不 SetCursorPos
  hwnd := DragWindowFromPoint(mx0, my0)        ; 顶层窗口(自动上溯出子控件)
  if !hwnd
    hwnd := DllCall("GetForegroundWindow", "ptr")
  if !hwnd {
    DragRestoreDpi(raw)
    return
  }
  ; 最小化窗口无几何意义, 跳过
  if (WinGetMinMax(hwnd) = -1) {
    DragRestoreDpi(raw)
    return
  }
  ; 最大化/全屏先还原, 否则无法拖动
  if (WinGetMinMax(hwnd) = 1) {
    WinRestore(hwnd)
    Sleep 50
  }
  DragRawRect(hwnd, &x0, &y0, &w0, &h0)
  WindowDragState := {
    mode: "move",
    hwnd: hwnd,
    key: DragTriggerKey(A_ThisHotkey),
    mx0: mx0, my0: my0,
    x0: x0, y0: y0, w0: w0, h0: h0,
    ox: mx0 - x0, oy: my0 - y0,   ; 抓取点相对窗口左上角的偏移, 移动时保持不变
    lx: x0, ly: y0, lw: w0, lh: h0,   ; 上一帧实际写入的目标矩形(去抖: 相同则跳过写)
    moved: false,
    t0: A_TickCount               ; 硬超时的计时基准(唯一的时间兜底, 见 DragSessionAlive)
  }
  DragLogReset()
  DragLog("[Start move] ctx=" DragCtx() " A_ScreenDPI=" A_ScreenDPI
    . " | cursorScreen=(" mx0 "," my0 ") rect=(" x0 "," y0 "," w0 "," h0 ")"
    . " | ox=" (mx0 - x0) " oy=" (my0 - y0))
  DragRestoreDpi(raw)
  SetTimer(PollDragMoveWindow, 10)
}

/**
 * 拖拽移动窗口 - 轮询 (每帧读取光标, 计算位移, 写窗口位置)
 *
 * 退出条件只有 DragSessionAlive() 里的两条兜底(窗口销毁 / 硬超时);
 * 正常结束由触发键的 up 热键事件调用 StopDragWindow() 完成。
 * 不在这里判断键态、也不判断前台窗口 —— 理由见 DragSessionAlive 的注释。
 */
PollDragMoveWindow() {
  global WindowDragState, DRAG_DEADZONE
  st := WindowDragState
  if !st
    return
  ; 兜底闸门(窗口已销毁 / 硬超时), 任一满足即已收尾
  if !DragSessionAlive(st)
    return
  raw := DragHarmonizeDpi()
  DragRawCursor(&mx, &my)              ; 原生物理屏幕坐标, 与 Start 完全同源
  dx := mx - st.mx0
  dy := my - st.my0
  if !st.moved && (Abs(dx) > DRAG_DEADZONE || Abs(dy) > DRAG_DEADZONE)
    st.moved := true
  if !st.moved {   ; 死区之内不改变窗口位置, 保证按下瞬间窗口不动
    DragLog("[Poll move] ctx=" DragCtx() " mx=" mx " my=" my " dx=" dx " dy=" dy " moved=false (no write)")
    DragRestoreDpi(raw)
    return
  }
  ; 新位置 = 光标 - 恒定抓取偏移, 尺寸不变 ⇒ 抓取点始终吸附光标, 无初始位移
  tgtx := mx - st.ox, tgty := my - st.oy
  ; 去抖: 目标矩形与上一帧一致(无可视变化)则跳过写, 避免冗余 SetWindowPos 引起的抖动
  if (tgtx != st.lx || tgty != st.ly) {
    ; SWP_NOSIZE(0x1)|SWP_NOZORDER(0x4)|SWP_NOACTIVATE(0x10) = 0x15
    DragSetWindowPos(st.hwnd, tgtx, tgty, 0, 0, 0x15)
    st.lx := tgtx, st.ly := tgty
  }
  DragRestoreDpi(raw)
  DragRawRect(st.hwnd, &ax, &ay, &aw, &ah)
  DragLog("[Poll move] ctx=" DragCtx() " mx=" mx " my=" my " dx=" dx " dy=" dy
    . " | tgt=(" tgtx "," tgty ") | actualRect=(" ax "," ay "," aw "," ah ")"
    . " | err=(" (ax - tgtx) "," (ay - tgty) ")")
}

/**
 * 拖拽缩放窗口
 * 按下瞬间不改变尺寸; 鼠标移动后按位移主轴自动选边/角:
 * 水平为主改左右, 垂直为主改上下, 两者都大改角.
 * 根因修复: 新 down 到来时若旧会话仍在, 先安全收尾旧会话再开新会话。
 *   - 绝不直接丢弃按下 (旧代码: if WindowDragState return)
 *   - 会话结束由触发键的 up 热键事件驱动(StopDragWindow), 不靠键态轮询:
 *     侧键热键是吞键形态, 按住期间键态查询恒为 false(详见 DragSessionAlive)
 */
StartDragResizeWindow(strategy := "axis") {
  global WindowDragState
  ; 根因修复: 新 down 先安全收尾旧会话, 再开新会话。不丢弃本次按下。
  ; 同 StartDragMoveWindow: 不再调用 ReleaseCapture(实测无效, 见 T13)。
  if WindowDragState
    StopDragWindowForKey("")
  ; 同移动: 全程原生 Win32 物理屏幕坐标, 与 CoordMode 线程局部性/DPI 层无关.
  raw := DragHarmonizeDpi()
  DragRawCursor(&mx0, &my0)                    ; 只读光标, 绝不 SetCursorPos
  hwnd := DragWindowFromPoint(mx0, my0)        ; 顶层窗口(自动上溯出子控件)
  if !hwnd
    hwnd := DllCall("GetForegroundWindow", "ptr")
  if !hwnd {
    DragRestoreDpi(raw)
    return
  }
  if (WinGetMinMax(hwnd) = -1) {
    DragRestoreDpi(raw)
    return
  }
  if (WinGetMinMax(hwnd) = 1) {
    WinRestore(hwnd)
    Sleep 50
  }
  DragRawRect(hwnd, &x0, &y0, &w0, &h0)
  WindowDragState := {
    mode: "resize",
    hwnd: hwnd,
    key: DragTriggerKey(A_ThisHotkey),
    strategy: strategy,
    mx0: mx0, my0: my0,
    x0: x0, y0: y0, w0: w0, h0: h0,
    lx: x0, ly: y0, lw: w0, lh: h0,   ; 上一帧实际写入的目标矩形(去抖)
    moved: false,
    t0: A_TickCount               ; 硬超时的计时基准(唯一的时间兜底, 见 DragSessionAlive)
  }
  DragLogReset()
  DragLog("[Start resize/" strategy "] ctx=" DragCtx() " A_ScreenDPI=" A_ScreenDPI
    . " | cursorScreen=(" mx0 "," my0 ") rect=(" x0 "," y0 "," w0 "," h0 ")")
  DragRestoreDpi(raw)
  SetTimer(PollDragResizeWindow, 10)
}

/**
 * 拖拽缩放窗口 - 轮询 (按位移主轴自动选边/角)
 *
 * 退出条件同 PollDragMoveWindow: 只有 DragSessionAlive() 的两条兜底,
 * 正常结束靠触发键的 up 热键事件。
 */
PollDragResizeWindow() {
  global WindowDragState, DRAG_DEADZONE, DRAG_MIN_W, DRAG_MIN_H
  st := WindowDragState
  if !st
    return
  ; 兜底闸门(窗口已销毁 / 硬超时), 任一满足即已收尾
  if !DragSessionAlive(st)
    return
  raw := DragHarmonizeDpi()
  DragRawCursor(&mx, &my)              ; 原生物理屏幕坐标, 与 Start 完全同源
  dx := mx - st.mx0
  dy := my - st.my0
  if !st.moved && (Abs(dx) > DRAG_DEADZONE || Abs(dy) > DRAG_DEADZONE)
    st.moved := true
  if !st.moved {   ; 满足"按下瞬间不改变尺寸"
    DragLog("[Poll resize] ctx=" DragCtx() " mx=" mx " my=" my " dx=" dx " dy=" dy " moved=false (no write)")
    DragRestoreDpi(raw)
    return
  }

  ; 默认左上角固定, 右/下边跟随鼠标
  nx := st.x0, ny := st.y0, nw := st.w0, nh := st.h0
  if (st.strategy = "bottomright") {
    ; 策略(b): 固定右下角, 宽高直接跟随位移
    nw := st.w0 + dx
    nh := st.h0 + dy
  } else {
    ; 策略(a): 按位移主轴自动选边/角
    ax := Abs(dx), ay := Abs(dy)
    if (ax > ay * 2) {
      nw := st.w0 + dx                       ; 水平为主: 只改左右边
    } else if (ay > ax * 2) {
      nh := st.h0 + dy                       ; 垂直为主: 只改上下边
    } else {
      nw := st.w0 + dx                       ; 两者都大: 同时改角
      nh := st.h0 + dy
    }
  }
  nw := Max(nw, DRAG_MIN_W)   ; 最小尺寸钳制
  nh := Max(nh, DRAG_MIN_H)
  ; 去抖: 目标矩形与上一帧一致(无可视变化)则跳过写
  if (nx != st.lx || ny != st.ly || nw != st.lw || nh != st.lh) {
    ; SWP_NOMOVE(0x2)|SWP_NOZORDER(0x4)|SWP_NOACTIVATE(0x10) = 0x16
    DragSetWindowPos(st.hwnd, nx, ny, nw, nh, 0x16)
    st.lx := nx, st.ly := ny, st.lw := nw, st.lh := nh
  }
  DragRestoreDpi(raw)
  DragRawRect(st.hwnd, &ax2, &ay2, &aw2, &ah2)
  DragLog("[Poll resize] ctx=" DragCtx() " mx=" mx " my=" my " dx=" dx " dy=" dy
    . " | tgt=(" nx "," ny "," nw "," nh ") | actualRect=(" ax2 "," ay2 "," aw2 "," ah2 ")"
    . " | err=(" (ax2 - nx) "," (ay2 - ny) "," (aw2 - nw) "," (ah2 - nh) ")")
}

/**
 * 结束拖拽 (移动/缩放共用) - 停定时器并清理
 *
 * 拦截策略: 完全拦截, 不补发原键.
 *   无论是否拖动、无论按住时长, 都绝不放行原触发键(未拖动 = 什么都没按).
 *   本函数只负责: 停掉轮询定时器 + 清空拖拽状态, 保证按键不卡住.
 *
 * ── 按键归属判定(接线入口) ──────────────────────────────────────────
 * 生成物里 up 热键是:  km.Map("XButton1 up", _ => StopDragWindow())
 * 因此从 up 热键进来时 A_ThisHotkey 就是 "XButton1 up"(实测, 见
 * tools/_q3_probe/hotkey_probe.ahk)。此时按"触发键"做归属判定:
 *   只停自己触发的那个会话, 不会因为松 XButton1 而停掉 XButton2 的会话。
 * 竞态是真实的: WindowDragState 是**单槽**全局量, 且 Start 新会话时会先收尾旧会话,
 * 所以 XButton2 按住拖拽期间按一下 XButton1 就会把会话换成 XButton1 的;
 * 若此时松开 XButton2, 无归属判定的 up 会把 XButton1 的会话一并停掉。
 *
 * 非 up 热键线程的调用(退出/暂停/重载/harness/定时器)必须**强制**收尾,
 * 故一律走 StopDragWindowForKey("")。定时器线程不能走这里:
 * A_ThisHotkey 在 SetTimer 线程里是上一热键的残留值(实测), 会误挡。
 */
StopDragWindow() {
  hk := A_ThisHotkey
  if (hk != "" && RegExMatch(hk, "i)\s+up$")) {
    StopDragWindowForKey(DragTriggerKey(hk))
    return
  }
  StopDragWindowForKey("")
}

/**
 * 结束拖拽 (按键感知版) - key 非空时仅当它与当前会话的触发键一致才停止
 * @param {string} key 触发键(已去 " up" 后缀); 空串 = 强制停止
 */
StopDragWindowForKey(key) {
  global WindowDragState
  st := WindowDragState
  ; 如果指定了 key, 仅在与当前会话一致时才停止; 空 key 表示强制停止
  if (key != "" && st && st.key != key) {
    DragLog("[Stop] 忽略非归属 up: hotkeyKey=" key " sessionKey=" st.key)
    return
  }
  SetTimer(PollDragMoveWindow, 0)
  SetTimer(PollDragResizeWindow, 0)
  WindowDragState := false
}

/**
 * 启动程序或切换到程序
 * @param {string} winTitle AHK中的WinTitle
 * @param {string} target 程序的路径
 * @param {string} args 参数
 * @param {string} workingDir 工作文件夹
 * @param {bool} admin 是否为管理员启动
 * @param {bool} isHide 窗口是否为隐藏窗口
 * @returns {void} 
 */
ActivateOrRun(winTitle := "", target := "", args := "", workingDir := "", admin := false, isHide := false, runInBackground := false) {
  ; 如果是程序或参数中带有“选中的文件” 则通过该程序打开该连接
  if (InStr(target, "{selected}") || InStr(args, "{selected}")) {
    ; 没有获取到文字直接返回
    if not (ReplaceSelectedText(&target, &args))
      return
  }

  ; 切换程序
  winTitle := Trim(winTitle)
  if (winTitle && activateWindow(winTitle, isHide))
    return

  ; 程序没有运行，运行程序
  if not target {
    return
  }
  workingDir := workingDir ? workingDir : A_WorkingDir
  RunPrograms(target, args, workingDir, admin, runInBackground)
}

/**
 * 轮换程序窗口
 * @param winTitle AHK中的WinTitle
 * @param hwnds 活动窗口的句柄数组
 * @returns {void|number} 
 */
LoopRelatedWindows(winTitle?, hwnds?) {
  ; 如果没有传句柄数组则获取当前窗口的
  if not (IsSet(hwnds)) {
    predicate := (hwnd) => WinGetTitle(hwnd) != ""
    if (GetProcessName() == "explorer.exe") {
      predicate := (hwnd) => WinGetClass(hwnd) = "CabinetWClass"
    }
    hwnds := FindWindows("ahk_exe " WinGetProcessName("A"), predicate)
  }

  ; 只有一个窗口显示出来就行
  if (hwnds.Length = 1) {
    WinActivate(hwnds.Get(1))
    return
  }

  ; 没有传winTitle时，则获取当前程序的名称
  if not (IsSet(winTitle)) {
    class := WinGetClass("A")
    if (class == "ApplicationFrameWindow") {
      winTitle := WinGetTitle("A") "  ahk_class ApplicationFrameWindow"
    } else {
      winTitle := "ahk_exe " GetProcessName()
    }
  }
  winTitle := Trim(winTitle)

  static winGroup, lastWinTitle := "", lastHwnd := "", gi := 0
  if (winTitle != lastWinTitle || lastHwnd != WinExist("A")) {
    lastWinTitle := winTitle
    winGroup := "AutoName" gi++
  }

  ; 将所有的hwnd都添加到组里
  for hwnd in hwnds {
    GroupAdd(winGroup, "ahk_id" hwnd)
  }

  ; 切换
  lastHwnd := GroupActivate(winGroup, "R")
  return lastHwnd
}

/**
 * CapsLock 命令框
 */
EnterCapslockAbbr(capsHook) {
  static WM_USER := 0x0400
  static SHOW_COMMAND_INPUT := WM_USER + 0x0001
  static HIDE_COMMAND_INPUT := WM_USER + 0x0002
  static CANCEL_COMMAND_INPUT := WM_USER + 0x0003

  ; 高级键盘设置 > 输入语言热键, 用户勾选了用 Shift 键关闭大写
  ; if GetKeyState("Shift", "P") {
  ;   Tip("bug: Shift key is pressed down")
  ;   return
  ; }

  ; 显示命令框窗口
  PostMessageToCpasAbbr(SHOW_COMMAND_INPUT)

  endReason := StartInputHook(capsHook)
  if (InStr(endReason, "Match")) {
    char := SubStr(capsHook.Match, -1)
    PostCharToCaspAbbr(, char)
    SetTimer(HideCaspAbbr, -1)
  } else {
    if (InStr(endReason, "EndKey")) {
      PostMessageToCpasAbbr(CANCEL_COMMAND_INPUT)
    } else {
      PostMessageToCpasAbbr(HIDE_COMMAND_INPUT)
    }
  }

  if (capsHook.Match) {
    ExecCapslockAbbr(capsHook.Match)
  }
}

/**
 * semi缩写框
 */
EnterSemicolonAbbr(semiHook, semiHookAbbrWindow) {
  semiHookAbbrWindow.Show(" ")
  endReason := StartInputHook(semiHook)
  if (InStr(endReason, "Match")) {
    char := SubStr(semiHook.Match, -1)
    semiHookAbbrWindow.Show(char, true)
    SetTimer(() => semiHookAbbrWindow.Hide(), -100)
  } else {
    semiHookAbbrWindow.Hide()
  }

  if (semiHook.Match)
    ExecSemicolonAbbr(semiHook.Match)
}

/**
 * 智能的关闭窗口
 */
SmartCloseWindow() {
  if NotActiveWin() {
    return
  }

  class := WinGetClass("A")
  name := GetProcessName()
  if (WinActive("- Microsoft Visual Studio ahk_exe devenv.exe")) {
    Send("^{F4}")
  } else {
    if (class == "ApplicationFrameWindow" || name == "explorer.exe") {
      Send("!{F4}")
    } else {
      PostMessage(0x112, 0xF060, , , "A")
    }
  }
}

/**
 * 窗口居中并修改其大小
 * @param width 窗口宽度
 * @param height 窗口高度
 * @returns {void} 
 */
CenterAndResizeWindow(width, height) {
  if NotActiveWin() {
    return
  }

  ; 在 mousemove 时需要 PER_MONITOR_AWARE (-3), 否则当两个显示器有不同的缩放比例时, mousemove 会有诡异的漂移
  ; 在 winmove 时需要 UNAWARE (-1), 这样即使写死了窗口大小为 1200x800, 系统会帮你缩放到合适的大小
  try DllCall("SetThreadDpiAwarenessContext", "ptr", -1, "ptr")

  WinExist("A")
  if (WindowMaxOrMin())
    WinRestore

  WinGetPos(&x, &y, &w, &h)

  ms := GetMonitorAt(x + w / 2, y + h / 2)
  MonitorGetWorkArea(ms, &l, &t, &r, &b)
  w := r - l
  h := b - t

  winW := Min(width, w)
  winH := Min(height, h)
  winX := l + (w - winW) / 2
  winY := t + (h - winH) / 2

  WinMove(winX, winY, winW, winH)
  try DllCall("SetThreadDpiAwarenessContext", "ptr", -3, "ptr")
}

/**
 * 窗口最大化
 */
MaximizeWindow() {
  if NotActiveWin() {
    return
  }

  if WindowMaxOrMin() {
    WinRestore("A")
  } else {
    WinMaximize("A")
  }
}

/**
 * 窗口最小化
 */
MinimizeWindow() {
  if (NotActiveWin() || WinGetProcessName("A") == "Rainmeter.exe")
    return

  WinMinimize("A")
}

/**
 * 窗口置顶
 */
ToggleWindowTopMost() {
  value := !(WinGetExStyle("A") & 0x8)
  WinSetAlwaysOnTop(value, "A")
  if value {
    Tip(Translation().always_on_top_on)
  } else {
    Tip(Translation().always_on_top_off)
  }
}

/**
 * 模拟 Alt+Tab 热键
 */
SystemAltTab() {
  global altTabIsOpen := true
  send("^!{Tab}")
}

/**
 * 模拟 Shift+Alt+Tab 热键
 */
SystemShiftAltTab() {
  global altTabIsOpen := true
  send("^+!{Tab}")
}

/**
 * 关闭窗口（直接杀进程）
 * @returns  
 */
CloseWindowProcesses() {
  if NotActiveWin() {
    return
  }

  name := WinGetProcessName("A")
  ; 如果删了explorer会导致桌面白屏
  if (name == "explorer.exe") {
    CloseSameClassWindows()
    return
  }

  Run('taskkill /f /im "' name '"', , "Hide")
}

/**
 * 将鼠标移动到光标的位置
 */
MoveMouseToCaret() {
  GetCaretPos(&x, &y)
  if (StrLen(x) | StrLen(y)) {
    ; Tip(A_SendMode "|" A_CoordModeMouse) ; 每次执行热键, 这两个都会重置为默认值
    SendMode("Event")
    CoordMode("Mouse", "Screen")
    MouseMove(x, y, 100)
  } else {
    MouseToActiveWindowCenter()
  }
}

/**
 * 修改文本颜色字体
 * @param {string} color HEX颜色值
 * @param {string} fontFamily 字体
 */
changeTextStyle(color := "#000000", fontFamily := "Iosevka") {
  text := GetSelectedText()
  loop StrLen(text) {
    Send("{Del}")
  }
  if not (text) {
    return
  }

  if (WinActive("ahk_group makrdownGroup")) {
    text := "<font color='" color "'>" text "</font>"
  } else {
    text := FormatHtmlStyle(text, color, fontFamily)
  }

  PasteToPrograms(text)
}

/**
 * 中英文之间添加空格
 */
InsertSpaceBetweenZHAndEn() {
  text := GetSelectedText()
  text := RegExReplace(text, "([\x{4e00}-\x{9fa5}])(?=[a-zA-Z0-9])|([a-zA-Z0-9])(?=[\x{4e00}-\x{9fa5}])", "$0 ")
  PasteToPrograms(text)
}

/**
 * 触发键是否"物理按下"。
 *
 * 实际实现是**二选一**, 不是双重保障:
 *   1) 先把手写 vkMap 里的大小写变体查一遍; 查不到再试 GetKeyVK(key)
 *   2) 只要拿到了 VK, 就**只**问 GetAsyncKeyState(检测 0x8000 位), 直接返回;
 *      GetKeyState(key, "P") 仅在该键**完全没有 VK** 时才会被执行。
 * 所以"有 VK 时不看 GetKeyState"是当前事实, 二者不可能同时参与判定。
 *
 * 大小写覆盖范围有限: vkMap 只硬写了两份大小写(LButton/RButton/MButton/
 * XButton1/XButton2 与全小写形式), 共 5 个鼠标键; 其它键名依赖 GetKeyVK 自身
 * 的解析, 不是"通用大小写不敏感查找"。
 *
 * 有效性证据见 tools/harness/lib_test.ahk 的 T6 组(闸门实际停掉了会话)。
 */
DragKeyPhysicallyDown(key) {
  static vkMap := Map(
    "LButton", 0x01, "RButton", 0x02, "MButton", 0x04,
    "XButton1", 0x05, "XButton2", 0x06,
    "lbutton", 0x01, "rbutton", 0x02, "mbutton", 0x04,
    "xbutton1", 0x05, "xbutton2", 0x06
  )
  vk := vkMap.Get(key, "")
  if !vk
    vk := GetKeyVK(key)
  if vk
    return (DllCall("GetAsyncKeyState", "int", vk, "short") & 0x8000) ? true : false
  return GetKeyState(key, "P")
}

; ── 修饰键保持的全局看门狗状态 (#3 防卡死) ──
; g_HeldModifiers: Map<modifier, tickStart> —— "已发 Down 尚未 Up" 的修饰键。
; 看门狗低频扫描, 超时即强制补发 Up; 即使持有它的线程被 Suspend/Reload/中止也能兜底。
global g_HeldModifiers := Map()
global MOD_HOLD_TIMEOUT_MS := 5000        ; 单次保持上限 5s (防御性)
global MOD_WATCHDOG_MS := 500             ; 看门狗扫描间隔

/** 修饰键是否被用户真实按住(物理键态); 若是则不由我们接管, 避免抢占真实按键 */
ModifierPhysicallyDown(modifier) {
  vk := GetKeyVK(modifier)
  if !vk
    return false
  return (DllCall("GetAsyncKeyState", "int", vk, "short") & 0x8000) ? true : false
}

/** 释放单个修饰键(幂等): 发 Up 并从看门狗表移除 */
ReleaseModifier(modifier) {
  global g_HeldModifiers
  try Send("{blind}{" modifier " Up}")
  try g_HeldModifiers.Delete(modifier)
}

/** 释放所有"由本程序按住"的修饰键。供退出/暂停/重载/看门狗统一调用 */
ReleaseAllHeldModifiers() {
  global g_HeldModifiers
  for modifier, _ in g_HeldModifiers.Clone()
    ReleaseModifier(modifier)
}

/** 看门狗: 超过 MOD_HOLD_TIMEOUT_MS 仍保持的修饰键强制释放 */
ModifierWatchdog() {
  global g_HeldModifiers, MOD_HOLD_TIMEOUT_MS
  if (g_HeldModifiers.Count = 0)
    return
  now := A_TickCount
  for modifier, t0 in g_HeldModifiers.Clone() {
    if (now - t0 >= MOD_HOLD_TIMEOUT_MS)
      ReleaseModifier(modifier)
  }
}

/**
 * 按住修饰键, 直到触发键松开后释放 (#3 防卡死)
 *
 * 修复 "Win/Alt 始终被视作按下" / "滚轮等长按松手仍触发":
 *   1) **不再用无超时 KeyWait** (up 丢失即永久阻塞), 改为轮询物理键态;
 *   2) Down/Up 用 try/finally 包成原子对, 任何异常路径都会发出 Up;
 *   3) 跨线程看门狗兜底 (线程被 Suspend/Reload/中止也能释放);
 *   4) 5s 超时兜底;
 *   5) 用户真实按着该修饰键时不接管。
 */
HoldModifierUntilKeyUp(modifier) {
  global g_HeldModifiers, MOD_HOLD_TIMEOUT_MS, MOD_WATCHDOG_MS
  key := ExtractWaitKey(A_ThisHotkey)
  if ModifierPhysicallyDown(modifier) {
    while DragKeyPhysicallyDown(key)
      Sleep 10
    return
  }
  SetTimer(ModifierWatchdog, MOD_WATCHDOG_MS)
  try {
    Send("{blind}{" modifier " Down}")
    g_HeldModifiers[modifier] := A_TickCount
    t0 := A_TickCount
    while (A_TickCount - t0 < MOD_HOLD_TIMEOUT_MS) {
      if !DragKeyPhysicallyDown(key)
        break
      Sleep 10
    }
  } finally {
    ReleaseModifier(modifier)
    if (g_HeldModifiers.Count = 0)
      SetTimer(ModifierWatchdog, 0)
  }
}

/**
 * 按住左Shift
 */
HoldDownLShiftKey() {
  HoldModifierUntilKeyUp("LShift")
}

HoldDownModifierKey(modifier) {
  HoldModifierUntilKeyUp(modifier)
}

/**
 * 按住右Shift
 */
HoldDownRShiftKey() {
  HoldModifierUntilKeyUp("RShift")
}

/**
 * 绑定当前窗口到当前键上
 * @param key 当前键
 * @returns {void} 
 */
BindWindow() {
  windowID := false
  windowTitle := false
  handler(thisHotKey) {
    waitkey := ExtractWaitKey(thisHotKey)
    if not (KeyWait(waitkey, "T0.6")) {
      ; 绑定窗口
      windowID := WinGetID("A")
      windowTitle := WinGetTitle("A")
      Tip("已绑定当前窗口")
      KeyWait(waitkey, "T2") ; 避免按住时每隔 0.6 秒重复执行这个动作
      return
    }

    if (windowID && WinExist("ahk_id " windowID)) {
      if WinActive() {
        WinMinimize
        return
      }
      WinActivate(windowID)
      return
    }

    if (windowTitle && WinExist(windowTitle)) {
      if WinActive() {
        WinMinimize
        return
      }
      WinActivate(windowTitle)
      return
    }

    Tip("请长按绑定窗口")
  }

  return handler
}

/**
 * 关闭同应用的所有窗口
 */
CloseSameClassWindows() {
  if NotActiveWin() {
    return
  }

  exe := WinGetProcessName("A")
  if exe == "explorer.exe" {
    windows := FindWindows("ahk_class " WinGetClass("A"))
  } else {
    windows := FindWindows("ahk_exe " exe)
  }

  for i, hwnd in windows {
    WinClose(hwnd)
  }
}

/**
 * 锁屏
 */
SystemLockScreen() {
  Sleep 300
  DllCall("LockWorkStation")
}

/**
 * 关机
 */
SystemShutdown() {
  Run("SlideToShutDown.exe")
  sleep(1300)
  CoordMode("Mouse", "Screen")
  MouseClick("Left", 100, 100)
}

/**
 * 重启
 */
SystemReboot() {
  Shutdown(2)
}

SystemSleep() {
  DllCall("PowrProf\SetSuspendState")
}

SystemRestartExplorer() {
  Run("tools\Rexplorer_x64.exe /I /R")
}

SoundControl() {
  wnd := WinExist("A")
  if wnd {
    ActivateOrRun(, "bin\SoundControl.exe", "PreviousWindow " wnd)
  } else {
    ActivateOrRun(, "bin\SoundControl.exe")
  }
}

BrightnessControl() {
  Run("MyKeymap.exe /script bin\ChangeBrightness.ahk")
}

GoToLastWindow() {
  Send("!{tab}")
}

GoToPreviousVirtualDesktop() {
  Send("^#{left}")
}

GoToNextVirtualDesktop() {
  Send("^#{right}")
}

MoveWindowToNextMonitor() {
  Send("#+{right}")
}

/**
 * 切换Capslock状态
 */
ToggleCapslock() {
  if GetKeyState("Alt", "P")
    send("{blind}{LCtrl}{LAlt Up}")
  send("{blind}{CapsLock}")
}

/**
 * 查看帮助
 */
openHelpHtml() {
  if FileExist("bin\site\help.html") {
    Run("bin\site\help.html")
  } else {
    ; 非模态提示: 模态 MsgBox 会阻塞热键线程(与 B-5 同类), 用户一旦绑定"查看帮助"就会卡住
    ; ToolTip 用 -3000 一次性定时器关闭, 不留下常驻 timer
    ToolTip("帮助文件未生成，需要打开设置点一下保存")
    SetTimer(() => ToolTip(), -3000)
  }
}

/**
 * 设置窗口位置
 * @param x 窗口左上角X轴
 * @param y 窗口左上角Y轴
 * @param width 窗口宽度
 *   default: 不做修改
 * @param height 窗口高度
 *   default: 不做修改
 */
SetWindowPositionAndSize(x, y, width, height) {
  if NotActiveWin() {
    return
  }

  hwnd := WinExist("A")
  statie := WinGetMinMax()
  if statie
    WinRestore

  if (width == "default" || height == "default") {
    offset := GetWindowPositionOffset(hwnd)
    width := width == "default" ? offset.w : width
    height := height == "default" ? offset.h : height
  }

  WinMove(x, y, width, height)
}

/**
 * 一次打开多个链接或程序
 * @param urls 链接或程序 
 */
LaunchMultiple(urls*) {
  for index, url in urls {
    ShellRun(url)
  }
}

/**
 * 进程存在时用热键激活、否则启动程序
 */
ProcessExistSendKeyOrRun(pname, key, target) {
  if ProcessExist(pname) {
    Send(key)
  } else {
    RunPrograms(target)
  }
}

/**
 * 包裹选中的文本
 * @param Format 格式
 */
WrapSelectedText(Format) {
  text := GetSelectedText()
  if text {
    PasteToPrograms(StrReplace(format, "{text}", text))
  }
}

CopySelectedAsPlainText() {
  A_Clipboard := ""
  Send "^c"
  if !ClipWait(1) {
    Tip(Translation().copy_failed)
    return
  }
  A_Clipboard := A_Clipboard
  Tip(Translation().copy_ok)
}

MuteActiveApp() {
  code := RunWait("bin\SoundControl.exe ToggleMute " GetActiveProcess("name"))
  switch code {
    case 1: Tip(Translation().mute_on)
    case 2: Tip(Translation().mute_off)
    default: Tip(Translation().mute_falied)
  }
}

ShowActiveProcessInFolder() {
  try path := GetActiveProcess("path")
  catch as e {
    Tip(e.Message)
    return
  }
  ShowFileInFoler(path)
}

chromeInstance() {
  static m := Map()
  key := A_ThisHotkey

  if !m.Has(key) || (m.Has(key) && !WinExist(m.Get(key))) {
    oldWindow := WinActive("A")
    Run("C:\Program Files\Google\Chrome\Application\chrome.exe")
    if !WinWaitNotActive(oldWindow, , 0.2) || !WinWaitActive("ahk_exe chrome.exe", , 0.2) {
      Tip("启动 chrome 失败")
      return
    }
    m.Set(key, WinActive("A"))
    return
  }

  id := WinExist(m.Get(key))
  if WinActive(id) {
    WinMinimize(id)
  } else {
    WinActivate(id)
  }
}