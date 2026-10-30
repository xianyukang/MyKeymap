/**
 * 托盘菜单被点击
 * @param ItemName 
 * @param ItemPos 
 * @param MyMenu 
 */
TrayMenuHandler(ItemName, ItemPos, MyMenu) {
  switch ItemName {
    case Translation().menu_exit:
      MyKeymapExit()
    case Translation().menu_pause:
      MyKeymapToggleSuspend()
    case Translation().menu_reload:
      MyKeymapReload()
    case Translation().menu_settings:
      MyKeymapOpenSettings()
    case Translation().menu_window_spy:
      run("MyKeymap.exe /script bin\WindowSpy.ahk")
  }
}

/**
 * 退出程序
 * @param ExitReason 退出原因
 * @param ExitCode 传递给 Exit 或 ExitApp 的退出代码.
 */
MyKeymapExit(ExitReason?, ExitCode?) {
  ProcessClose("MyKeymap-CommandInput.exe")
  ; B-9: 退出前必须停掉窗口拖拽轮询定时器并清掉拖拽状态, 否则定时器会带着
  ; 未结束的会话继续跑.
  ; Actions.ahk 可能未加载, 用 try 做存在性保护; StopDragWindow 内部已负责
  ; SetTimer(PollDragMoveWindow/0) + SetTimer(PollDragResizeWindow/0) + 清状态.
  ; (不涉及 ReleaseCapture: 实测本进程拖拽全程无鼠标捕获, 见 lib_test.ahk T13)
  try StopDragWindow()
  ; 退出前释放所有"由本程序按住"的修饰键, 防止 Win/Alt 卡住(#3).
  ; Actions.ahk 可能未加载, 用 try 做存在性保护.
  try ReleaseAllHeldModifiers()
  ; 退出前释放 MIDI: 先发 All Notes Off, 再关闭端口, 防止按键未松导致卡音.
  ; Midi.ahk 可能未加载 (如精简构建), 用 try 做存在性保护, 避免报错中断退出.
  try MidiAllNotesOff()
  try MidiClose()
  ExitApp
}

/**
 * 暂停
 */
MyKeymapToggleSuspend() {
  fn() {
    ; 暂停时释放可能卡住的修饰键(#3): 暂停后热键不再处理, 若不释放会永久卡住
    if !A_IsSuspended
      try ReleaseAllHeldModifiers()
    ; B-9: 暂停后拖拽轮询定时器仍在跑, 会继续移动/缩放窗口并改写鼠标捕获,
    ; 而热键已被暂停、up 再也收不到, 会话无法正常结束。暂停时先收尾拖拽会话。
    if !A_IsSuspended
      try StopDragWindow()
    Suspend(!A_IsSuspended)
    if (A_IsSuspended) {
      TraySetIcon("./bin/icons/logo2.ico")
      A_TrayMenu.Check(Translation().menu_pause)
      Tip(Translation().mykeymap_off, -500)
    } else {
      TraySetIcon("./bin/icons/logo.ico")
      A_TrayMenu.UnCheck(Translation().menu_pause)
      Tip(Translation().mykeymap_on, -500)
    }
  }

  if A_PriorKey == "RButton" {
    SetTimer(fn, -200)
    return
  }
  fn()
}

/**
 * 打开设置
 */
MyKeymapOpenSettings() {
  if (!WinExist("\bin\settings.exe")) {
    Run("./bin/settings.exe", "./bin")
  } else if (WinExist("MyKeymap Setting")) {
    WinActivate("MyKeymap Setting")
  } else {
    if WinExist("\bin\settings.exe") {
      WinClose
      WinWaitClose(, , 2)
    }
    Run("./bin/settings.exe", "./bin")
  }
}

/**
 * 重启程序
 */
MyKeymapReload() {
  Tip("Reload")
  ; B-9: 同 MyKeymapExit, 重载前先收尾拖拽会话(停定时器 + 释放捕获 + 清状态)
  try StopDragWindow()
  ; 重载会终止当前进程, 先释放卡住的修饰键(#3), 否则新进程启动后仍被系统认为按下
  try ReleaseAllHeldModifiers()
  Run("MyKeymap.exe")
}

/**
 * 获取当前程序名称
 * 自带的WinGetProcessName无法获取到uwp应用的名称
 * 来源：https://www.autohotkey.com/boards/viewtopic.php?style=7&t=112906
 * @returns {string} 
 */
GetProcessName() {
  return GetActiveProcess("name")
}

GetActiveProcess(type) {
  fn := (winTitle) => (WinGetProcessName(winTitle) == 'ApplicationFrameHost.exe')

  winTitle := "A"
  if fn(winTitle) {
    for hCtrl in WinGetControlsHwnd(winTitle)
      bool := fn(hCtrl)
    until !bool && winTitle := hCtrl
  }

  if type == "name" {
    return WinGetProcessName(winTitle)
  }
  if type == "id" {
    return WinGetPID(winTitle)
  }
  if type == "path" {
    return WinGetProcessPath(winTitle)
  }
}

/**
 * 从环境中补全程序的绝对路径
 * 来源: https://autohotkey.com/board/topic/20807-fileexist-in-path-environment/
 * @param target 程序路径 
 * @returns {string|any} 
 */
CompleteProgramPath(target) {
  ; 工作目录下的程序
  PathName := A_WorkingDir "\" target
  if FileExist(PathName)
    return PathName

  ; 本身便是绝对路径
  if FileExist(target)
    return target

  ; 从环境变量 PATH 中获取
  DosPath := EnvGet("PATH")
  loop parse DosPath, "`;" {
    if A_LoopField == ""
      continue

    if FileExist(A_LoopField "\" target)
      return A_LoopField "\" target
  }

  ; 从安装的程序中获取
  try {
    PathName := RegRead("HKLM", "SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\" target)
    if FileExist(PathName)
      return PathName
  }

  return target
}

/**
 * 通过命令行去启动程序，防止会导致以管理员启动软件的问题
 * @param target 程序路径 
 * @param arguments 参数
 * @param directory 工作目录
 * @param operation 选项 (runas/open/edit/print
 * @param show 是否显示
 */
ShellRun(target, arguments?, directory?, operation?, show?) {
  static VT_UI4 := 0x13, SWC_DESKTOP := ComValue(VT_UI4, 0x8)
  ComObject("Shell.Application").Windows.Item(SWC_DESKTOP).Document.Application
  .ShellExecute(target, arguments?, directory?, operation?, show?)
}

ActivateDesktop() {
  tmp := A_DetectHiddenWindows
  DetectHiddenWindows true
  if WinExist("ahk_class ForegroundStaging") {
    WinActivate
  }
  DetectHiddenWindows tmp
}

/**
 * 以管理员权限打开软件
 * @param target 程序路径
 * @param args 参数
 * @param workingDir 工作目录
 */
RunAsAdmin(target, args, workingDir, options) {
  try {
    Run("*RunAs " target " " args, workingDir, options)
  } catch Error as e {
    Tip("使用管理启动失败 " target ", " e.Message)
  }
}

/**
 * 运行程序或打开目录，用于解决打开的程序无法获取焦点的问题
 * @param target 程序路径
 * @param {string} args 参数
 * @param {string} workingDir 工作目录
 * @param {number} admin 是否为管理员启动
 * @returns {void} 
 */
RunPrograms(target, args := "", workingDir := "", admin := false, runInBackground := false) {
  ; 记录当前窗口的hwnd，当软件启动失败时还原焦点
  currentHwnd := WinExist("A")

  if !runInBackground {
    ActivateDesktop()
  }

  try {
    ; 补全程序路径
    programPath := CompleteProgramPath(target)

    ; 如果是文件夹直接打开
    if (InStr(FileExist(programPath), "D")) {
      Run(programPath)
      return
    }

    ; 避免在快捷方式无效，导致的程序卡住
    ShortcutTargetExist(programPath)

    if (admin) {
      runAsAdmin(programPath, args, workingDir, runInBackground ? "Hide" : "")
    } else {
      ; 直接 run "https://example.com" 会让 chrome 以管理员启动
      ; ShellRun 也支持 ms-setting: 或 shell: 或 http: 之类的链接
      ShellRun(programPath, args, workingDir, , runInBackground ? 0 : unset)
    }

  } catch Error as e {
    Tip(e.Message)
    ; 还原窗口焦点
    try WinActivate(currentHwnd)
    return
  }
}

/**
 * 快捷方式指向目标是否存在，不存在抛出异常
 * @param LnkPath 快捷方式路径
 */
ShortcutTargetExist(LnkPath) {
  if SubStr(LnkPath, -4) == ".lnk" {
    FileGetShortcut(LnkPath, &OutTarget)

    ; 没有获取到目标路径可能是因为是uwp应用的快捷方式
    ; 也有可能是ms-setting: 或shell:之类的连接
    if !OutTarget || SubStr(outTarget, 2, 2) != ":\"
      return

    if !FileExist(OutTarget)
      throw Error("快捷方式指向的目标不存在`n快捷方式: " LnkPath "`n指向目标: " OutTarget)
  }
}

/**
 * 激活窗口
 * @param winTitle AHK中的WinTitle
 * @param {number} isHide 窗口是否为隐藏窗口
 * @returns {number} 
 */
ActivateWindow(winTitle := "", isHide := false) {
  ; 如果匹配不到窗口且认为窗口为隐藏窗口时查找隐藏窗口
  hwnds := FindWindows(winTitle, (hwnd) => WinGetTitle(hwnd) != "")
  if ((!hwnds.Length) && isHide) {
    hwnds := FindHiddenWindows(winTitle)
    if hwnds.Length {
      WinShow(hwnds.Get(1))
      WinActivate(hwnds.Get(1))
      return true
    }
  }

  ; 如果匹配到则跳转，匹配不到返回0
  if (!hwnds.Length) {
    return 0
  }

  ; 只有一个窗口为最小化则切换否则最小化
  if (hwnds.Length = 1) {
    hwnd := hwnds.Get(1)
    ; 指定不为活动窗口或窗口被缩小则显示出来
    if (WinExist("A") != hwnd || WinGetMinMax(hwnd) = -1) {
      WinActivate(hwnd)
    } else {
      WinMinimize(hwnd)
    }
  } else {
    ; 如果多个窗口则来回切换
    LoopRelatedWindows(winTitle, hwnds)
  }

  return 1
}

/**
 * 查找隐藏窗口返回窗口的Hwnd 
 * @param winTitle AHK中的WinTitle
 * @returns {array} 
 */
FindHiddenWindows(winTitle) {
  WS_MINIMIZEBOX := 0x00020000
  WS_MINIMIZE := 0x20000000

  ; 窗口过滤条件
  ; 标题不为空、包含最小化按钮
  Predicate(hwnd) {
    if (WinGetTitle(hwnd) = "")
      return false

    style := WinGetStyle(hwnd)
    return style & WS_MINIMIZEBOX
  }

  ; 开启可以查找到隐藏窗口
  DetectHiddenWindows true
  hwnds := FindWindows(winTitle, Predicate)
  DetectHiddenWindows false

  return hwnds
}

/**
 * 返回与指定条件匹配的所有窗口
 * @param winTitle AHK中的WinTitle
 * @param predicate 过滤窗口方法，传过Hwnd，返回bool
 * @returns {array} 
 */
FindWindows(winTitle, predicate?) {
  temps := WinGetList(winTitle)
  ; 不需要做任何匹配直接返回
  if not (IsSet(predicate)) {
    return temps
  }

  hwnds := []
  for i, hwnd in temps {
    ; 当有谓词条件且满足时添加这个hwnd
    if predicate(hwnd) {
      hwnds.Push(hwnd)
    }
  }
  return hwnds
}

/**
 *  将程序路径或参数中的{selected} 替换为选中的文字
 * @param target 程序路径的引用
 * @param args 参数的引用
 * @returns {void|number} 
 */
ReplaceSelectedText(&target, &args) {
  text := GetSelectedText()
  if not (text) {
    text := ""
  }

  ; 如果是划词搜索且选中了 http 链接那么跳转链接
  if InStr(args, "https://") == 1 || InStr(target, "https://") == 1 {
    if InStr(text, "https://") || InStr(text, "http://") {
      args := InStr(args, "{selected}") ? Trim(text) : args
      target := InStr(target, "{selected}") ? Trim(text) : target
      return 1
    }
  }

  if InStr(args, "://") || InStr(target, "://") {
    text := URIEncode(text)
  }
  args := strReplace(args, "{selected}", text)
  target := strReplace(target, "{selected}", text)

  return 1
}

/**
 * 获取选中的文字
 * @returns {void|string} 
 */
GetSelectedText() {
  temp := A_Clipboard
  ; 清空剪贴板
  A_Clipboard := ""

  Send("^c")
  if not (ClipWait(0.4)) {
    Tip(Translation().no_items_selected, -700)
    return
  }
  text := A_Clipboard

  A_Clipboard := temp
  return RTrim(text, "`r`n")
}

/**
 * url 编码
 * 来源: https://www.autohotkey.com/boards/viewtopic.php?t=112741
 * @param Uri 需要编码的文本
 * @param {string} encoding 编码格式
 * @returns {string} 
 */
URIEncode(Uri, encoding := "UTF-8") {
  res := ""
  var := Buffer(StrPut(Uri, encoding), 0)
  StrPut(Uri, var, encoding)
  pos := 1
  ; 按字节遍历 buffer 中的 utf-8 字符串, 注意字符串有  null-terminator
  While pos < var.Size {
    code := NumGet(var, pos - 1, "UChar")
    if (code >= 0x30 && code <= 0x39) || (code >= 0x41 && code <= 0x5A) || (code >= 0x61 && code <= 0x7A)
      res .= Chr(code)
    else
      res .= "%" . Format("{:02X}", code)
    pos++
  }
  return res
}

/**
 * 启动InputHook，并返回EndReason
 * @param ih InputHook对象
 * @returns {void}
 *
 * ── 为什么不能用 Suspend(true)(实测, 这是"卡死别的窗口"的真因) ──────────
 * Suspend(true) 是**全局**停用所有热键, 其中包含 `*XButton1` / `*XButton2`
 * 这两个"吞键"热键。热键一停, 钩子就不再拦截侧键 down, 它直接落到前台窗口。
 * 若前台恰好是 VB6 控件(实测 bin/freeze_log.txt:
 * class=ThunderRT6PictureBoxDC), 控件收到 down 就 SetCapture, 只在收到对应
 * 的 up 时才 ReleaseCapture。而 up 往往落在 Suspend 结束**之后**, 那时本进程
 * 钩子已恢复, up 被重新吞掉 —— 前台永远等不到 up, 捕获永久滞留,
 * 其它窗口全部点不动, 必须 Win+L 解锁。
 *
 * 实测数据(tools/probe_xbleak, 独立进程受害者窗口 + 自身 GetCapture 采样):
 *   Suspend(true) 期间注入侧键      -> AHK 接住 0/3, 泄漏 3/3, 出现捕获滞留
 *   逐键禁用(保留侧键) 同期注入      -> AHK 接住 3/3, 泄漏 0/3
 *   两者 InputHook 都成功收到字符   -> input=[a], 功能等价
 *   纯阻塞 Sleep 3000 / 紧循环 3000 -> 泄漏 0 (顺带排除"钩子回调超时放行"假设)
 *
 * ── 现在的做法: 精确禁用除鼠标按钮之外的热键 ──────────────────────────
 * InputHook 需要"输入不被热键吞掉", 所以必须让字符类热键失效; 但完全没必要
 * 连鼠标按钮一起停。策略:
 *   1) 记录当前所有已启用热键的 rawName;
 *   2) 逐个 Hotkey(name, "Off"), 跳过鼠标按钮(IsMouseHotkeyName: 左右中键 + 侧键);
 *   3) finally 里只把**本次确实关掉**的重新 "On", 保证异常路径也能复原。
 *
 * 注意 2) 的范围: 旧实现只跳侧键, 把 `*LButton` 也关掉了, 由此产生
 * "down 落在关窗内 / up 落在开窗后" 的不对称窗口 -> VB6 控件捕获永久滞留。
 * 完整证据链见 IsMouseHotkeyName 的注释。
 * 最坏情况: 某键在会话期间被上层重新启用/禁用, 恢复时会按"本次关过的集合"
 * 复原, 与 Suspend 的"整体开关"语义相比不会更差(旧实现更是把整个进程的
 * 热键状态推平)。
 *
 * B-9 保留: ih.Wait() 必须有超时(30s), 否则匹配/结束条件都不触发时本函数
 * 永不返回。
 */
StartInputHook(ih) {
  ; 关掉除拖拽触发键(侧键)之外的所有热键
  turnedOff := TurnOffHotkeysExceptDragTriggers()

  try {
    ; RAlt 映射到 LCtrl 后,  按下 RAlt 再触发 Capslock 命令会导致 LCtrl 键一直处于按下状态
    if GetKeyState("LCtrl") {
      Send("{LCtrl Up}")
    }

    ; 启动监听等待输入匹配后关闭监听
    ih.Start()
    ; B-8: 给 Wait 加上限(秒)。v2 的 InputHook.Wait 只接受 Number,
    ; 超时后 EndReason 不一定为 "Timeout", 所以用 InProgress 复核。
    ih.Wait(30)
    if ih.InProgress {
      OutputDebug("[MyKeymap] InputHook 等待超时, 强制停止")
    }
  } finally {
    ; B-8/B-9: 任何异常或提前返回都走到这里, 保证钩子停止 + 热键恢复
    try ih.Stop()
    RestoreHotkeys(turnedOff)
  }

  return ih.EndReason
}

/**
 * 该热键名是否是"鼠标按钮热键"(LButton/RButton/MButton/XButton1/XButton2)。
 * 这类热键在 InputHook 会话期间必须**全程保持拦截**。
 *
 * ── 为什么必须包含 LButton/RButton/MButton(实测根因, 别再改回只认侧键) ──
 * 旧实现只认 XButton1/XButton2, 于是 TurnOffHotkeysExceptDragTriggers() 会把
 * 用户配置里的 `*LButton` 一并 Hotkey(...,"Off") (data/config.json 里鼠标右键模式、
 * 侧键后退、侧键前进共 3 处映射都用 *LButton)。后果是一条**不可自愈的不对称窗口**:
 *   1) InputHook 会话开始 -> `*LButton` 被关闭, 钩子不再拦截左键;
 *   2) 此刻用户点一下 -> 左键 down 直接落到前台窗口。若前台是 VB6 控件
 *      (实测证据 bin/freeze_log.txt: capture=0x20BA2 class=ThunderRT6PictureBoxDC),
 *      控件收到 down 就 SetCapture, 只在收到对应 up 时才 ReleaseCapture;
 *   3) 会话结束 -> RestoreHotkeys() 把 `*LButton` 重新打开;
 *   4) 用户松手 -> up 被**已恢复的钩子吞掉** -> 控件永远等不到 up
 *      -> 捕获永久滞留 -> 只有那一个窗口能响应, 其它窗口完全点不动也打不了字
 *      -> 必须 Win+L 让系统清理捕获才恢复。
 * 日志侧对上了: tools/diag 抓到 cap=<VB6类名> 而 keys=- (键态正常, 没有任何键卡住),
 * 所以任何"检测键卡住再补 up"的方案都不会触发 —— 判据从来不是键态。
 *
 * 收益对比: InputHook 需要的是"字符输入不被吞", 鼠标按钮完全不参与字符输入,
 * 关掉它们对 InputHook 零收益, 却会制造上述不可恢复状态。因此一律保留。
 */
IsMouseHotkeyName(name) {
  k := LTrim(name, "*~$#!^+<>")
  if InStr(k, " ") {
    k := SubStr(k, 1, InStr(k, " ") - 1)
  }
  return (k = "LButton" || k = "RButton" || k = "MButton"
    || k = "XButton1" || k = "XButton2"
    || k = "lbutton" || k = "rbutton" || k = "mbutton"
    || k = "xbutton1" || k = "xbutton2")
}

/**
 * 兼容别名: 拖拽触发键(侧键)是鼠标按钮的子集。
 * 保留该名字供已有调用点与 harness 继续使用, 语义由 IsMouseHotkeyName 统一决定。
 */
IsDragTriggerHotkeyName(name) {
  return IsMouseHotkeyName(name)
}

/**
 * 关掉除侧键之外所有已启用的热键, 返回**实际关掉**的名字数组。
 *
 * 只读本进程的注册表(KeymapManager.Stack), 不做任何键态查询 ——
 * 后者的可靠性正是被质疑的对象(吞键时恒 0)。
 */
TurnOffHotkeysExceptDragTriggers() {
  turnedOff := []
  seen := Map()
  try {
    for km in KeymapManager.Stack {
      if !IsObject(km) || !HasProp(km, "M")
        continue
      for name, arr in km.M {
        for hk in arr {
          if !hk.enabled || InStr(hk.rawName, " up")
            continue
          if IsDragTriggerHotkeyName(hk.rawName)
            continue
          if seen.Has(hk.rawName)
            continue
          seen[hk.rawName] := true
          try {
            Hotkey(hk.rawName, "Off")
            turnedOff.Push(hk.rawName)
          } catch {
            ; 注册失败的鬼键: 本来就不存在, 忽略
          }
        }
      }
    }
  } catch {
    ; KeymapManager 不可用(单测宿主等): 退化为什么都不关
  }
  return turnedOff
}

/**
 * 把 TurnOffHotkeysExceptDragTriggers 关掉的热键逐个恢复。
 * 只恢复传入集合里的名字, 不碰其它任何热键。
 */
RestoreHotkeys(names) {
  for name in names {
    try Hotkey(name, "On")
  }
}

/**
 * 发送消息到命令提示框
 * @param msg 消息编号
 * @param {number} wParam 消息参数
 */
PostMessageToCpasAbbr(msg, wParam := 0) {
  temp := A_DetectHiddenWindows
  DetectHiddenWindows(1)
  ; 调用 WinExist 的耗时都不超过 2ms, 没必要做缓存了
  if WinExist("ahk_class MyKeymap_Command_Input ahk_exe MyKeymap-CommandInput.exe") {
    PostMessage(msg, wParam, 0)
  } else {
    Tip("无法找到命令框, 可能需要重启 MyKeymap", -3000)
  }
  DetectHiddenWindows(temp)
}

/**
 * 关闭顶部命令提示框
 */
HideCaspAbbr() {
  PostMessageToCpasAbbr(0x0400 + 0x0002)
}

/**
 *  将键入的值发送到输入框
 * @param ih InputHook 对象
 * @param char 发送的字符
 */
PostCharToCaspAbbr(ih?, char?) {
  PostMessageToCpasAbbr(0x0102, Ord(SubStr(char, -1)))
}

PostBackspaceToCaspAbbr(ih, vk, sc) {
  PostMessageToCpasAbbr(0x0102, 0x8)
}

/**
 * 判断当前窗口是不是桌面
 */
IsDesktop() {
  return WinActive("Program Manager ahk_class Progman") || WinActive("ahk_class WorkerW")
}

/**
 * 获取当前焦点在哪个显示器上
 * @param x 窗口X轴的长度
 * @param y 窗口y轴的长度
 * @param {number} default 显示器下标
 * @returns {string|number} 匹配的显示器下标
 */
GetMonitorAt(x, y, default := 1) {
  m := SysGet(80)
  loop m {
    MonitorGet(A_Index, &l, &t, &r, &b)
    if (x >= l && x <= r && y >= t && y <= b)
      return A_Index
  }
  return default
}

/**
 * 当前窗口是最大化还是最小化
 * @param {string} winTitle AHK中的WinTitle
 * @returns {number} 
 */
WindowMaxOrMin(winTitle := "A") {
  return WinGetMinMax(winTitle)
}

/**
 * 将文本转换为Html
 * @param text 需要转换的文本
 * @param color HEX颜色值
 * @param fontFamily 字体
 * @returns {string} 
 */
FormatHtmlStyle(text, color, fontFamily) {
  style := "Color: '" color "'; font-fontFamily: '" fontFamily ";"

  text := HtmlEncode(text)
  html := "<HTML> <head><meta http-equiv='Content-type' content='text/html;charset=UTF-8'></head> <body> <!--StartFragment-->"
  if (InStr(text, "`n")) {
    html .= "<span style='" style "'><pre>" text "</pre></span>"
  } else {
    html .= "<span style='" style "'>" text "</span>"
  }
  html .= "<!--EndFragment--></body></HTML>"
  return html
}

/**
 * Html编码
 * @param text 需要编码的文本
 * @returns {void} 
 */
HtmlEncode(text) {
  text := strReplace(text, "&", "&amp;")
  text := strReplace(text, "<", "&lt;")
  text := strReplace(text, ">", "&gt;")
  text := strReplace(text, "" "", "&quot;")
  text := strReplace(text, " ", "&nbsp;")
  return text
}

/**
 * Map根据值找到键
 * @param m Map
 * @param value 值
 */
MapFindKey(m, targetValue) {
  for key, value in m {
    if (value == targetValue)
      return key
  }
}

/**
 * 获取活动窗口的位置和宽高
 * @param hwnd 窗口句柄
 */
GetWindowPositionOffset(hwnd) {
  rect := Buffer(16, 0)
  er := DllCall("dwmapi\DwmGetWindowAttribute"
    , "UPtr", hwnd  ; HWND  hwnd
    , "UInt", 9     ; DWORD dwAttribute (DWMWA_EXTENDED_FRAME_BOUNDS)
    , "UPtr", rect.Ptr ; PVOID pvAttribute
    , "UInt", rect.size  ; DWORD cbAttribute
    , "UInt")       ; HRESULT
  If er
    DllCall("GetWindowRect", "UPtr", hwnd, "UPtr", rect.Ptr, "UInt")

  r := Object()
  ; 窗口左到屏幕左边
  r.x1 := NumGet(rect, 0, "Int")
  ; 窗口上到屏幕上边
  r.y1 := NumGet(rect, 4, "Int")
  ; 窗口左到屏幕右边
  r.x2 := NumGet(rect, 8, "Int")
  ; 窗口上到屏幕下边
  r.y2 := NumGet(rect, 12, "Int")
  ; 窗口宽度
  r.w := Abs(max(r.x1, r.x2) - min(r.x1, r.x2))
  ; 窗口长度
  r.h := Abs(max(r.y1, r.y2) - min(r.y1, r.y2))

  return r
}

/**
 * 将文本粘贴到当前程序中
 * @param text 文本
 */
PasteToPrograms(text) {
  A_Clipboard := text
  Send("{LShift down}{Insert down}{Insert up}{LShift up}")
}

/**
 * 没有活动窗口或是桌面返回True 反之返回false
 */
NotActiveWin() {
  return IsDesktop() || not WinExist("A")
}

; 依次激活窗口(params*) {
;   for index, param in params {
;     if !WinActive(param) && WinExist(param) {
;       WinActivate
;       return
;     }
;   }
; }

ShowFileInFoler(filepath) {
  ; Run Format('explorer.exe /select,"{1}"', filepath)
  DllCall("shell32\SHParseDisplayName", "Str", filepath, "Ptr", 0, "Ptr*", &pidl := 0, "UInt", 0, "Ptr", 0, "HRESULT")
  DllCall("shell32\SHOpenFolderAndSelectItems", "Ptr", pidl, "UInt", 0, "Ptr", 0, "UInt", 0, "HRESULT")
  DllCall("ole32\CoTaskMemFree", "Ptr", pidl)
}

Join(sep, params*) {
  str := ""

  for index, param in params
    str .= sep . param

  return SubStr(str, StrLen(sep) + 1)
}