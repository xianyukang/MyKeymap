/**
 * 移动鼠标到活动窗口中心
 */
MouseToActiveWindowCenter() {
  WinGetPos(&X, &Y, &W, &H, "A")
  MouseMove(x + w / 2, y + h / 2)
}

/**
 * 移动活动窗口位置
 */
MouseMoveActiveWindowPos() {
  hwnd := WinExist("A")
  if (WindowMaxOrMin())
    WinRestore("A")

  PostMessage("0x0112", "0xF010", 0)
  Sleep 50
  SendInput("{Right}")
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
ActivateOrRun(winTitle := "", target := "", args := "", workingDir := "", admin := false, isHide := false) {
  ; 如果是程序或参数中带有“选中的文件” 则通过该程序打开该连接
  if (InStr(target, "{selected_text}") || InStr(args, "{selected_text}")) {
    ; 没有获取到文字直接返回
    if not (ReplaceSelectedText(&target, &args))
      return
  }

  ; 切换程序
  winTitle := Trim(winTitle)
  if (winTitle && activateWindow(winTitle, isHide))
    return

  ; 程序没有运行，运行程序
  RunPrograms(target, args, workingDir, admin)
}

/**
 * 切换程序窗口
 * @param winTitle AHK中的WinTitle
 * @param hwnds 活动窗口的句柄数组
 * @returns {void|number} 
 */
SwitchWindows(winTitle?, hwnds?) {
  ; 如果没有传句柄数组则获取当前窗口的
  if not (IsSet(hwnds)) {
    hwnds := FindWindows("A")
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
 * CapsLock缩写框
 */
EnterCapslockAbbr() {
  static WM_USER := 0x0400
  static SHOW_COMMAND_INPUT := WM_USER + 0x0001
  static HIDE_COMMAND_INPUT := WM_USER + 0x0002
  static CANCEL_COMMAND_INPUT := WM_USER + 0x0003
  ; 显示命令框窗口
  PostMessageToCpasAbbr(SHOW_COMMAND_INPUT)

  endReason := StartInputHook(capsHook)
  if (InStr(endReason, "Match")) {
    char := SubStr(capsHook.Match, StrLen(capsHook.Match) - 1)
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
EnterSemicolonAbbr() {
  semiHookAbbrWindow.Show("    ")
  endReason := StartInputHook(semiHook)
  semiHookAbbrWindow.Hide

  if (semiHook.Match)
    ExecSemicolonAbbr(semiHook.Match)
}

/**
 * 智能的关闭窗口
 */
SmartCloseWindow() {
  if IsDesktop()
    return

  class := WinGetClass("A")
  name := GetProcessName()
  if (WinActive("- Microsoft Visual Studio ahk_exe devenv.exe")) {
    Send("^{F4}")
  } else {
    if (class == "ApplicationFrameWindow" || name == "explorer.exe") {
      Send("^{F4}")
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
  if (IsDesktop())
    return

  ; 在 mousemove 时需要 PER_MONITOR_AWARE (-3), 否则当两个显示器有不同的缩放比例时, mousemove 会有诡异的漂移
  ; 在 winmove 时需要 UNAWARE (-1), 这样即使写死了窗口大小为 1200x800, 系统会帮你缩放到合适的大小
  DllCall("SetThreadDpiAwarenessContext", "ptr", -1, "ptr")

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
  DllCall("SetThreadDpiAwarenessContext", "ptr", -3, "ptr")
}

/**
 * 窗口最大化
 */
WindowMaximize() {
  if IsDesktop()
    return

  if WindowMaxOrMin() {
    WinRestore("A")
  } else {
    WinMaximize("A")
  }
}

/**
 * 窗口最小化
 */
WindowMinimize() {
  if (IsDesktop() || WinGetProcessName("A") == "Rainmeter.exe")
    return

  WinMinimize("A")
}

/**
 * 窗口置顶
 */
WindowTop() {
  WinSetAlwaysOnTop(!(WinGetExStyle("A") & 0x8), "A")
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
  if IsDesktop()
    return

  name := WinGetProcessName("A")
  ; 如果删了explorer会导致桌面白屏
  if (name == "explorer.exe")
    return

  Run("taskkill /f /im " name, , "Hide")
}

/**
 * 将鼠标移动到光标的位置
 */
MouseMoveToCare() {
  GetCaretPos(&x, &y)
  (StrLen(x) | StrLen(y)) ? MouseMove(x, y) : MouseToActiveWindowCenter()
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
  text := RegExReplace(text, "([\x{4e00}-\x{9fa5}])(?=[a-zA-Z])|([a-zA-Z])(?=[\x{4e00}-\x{9fa5}])", "$0 ")
  PasteToPrograms(text)
}

/**
 * 按住左Shift
 */
HoldDownLShiftKey() {
  send("{LShift down}")
  key := LTrim(A_ThisHotkey, "*")
  keywait(key)
  send("{LShift up}")
}

/**
 * 按住右Shift
 */
HoldDownRShiftKey() {
  send("{RShift down}")
  key := LTrim(A_ThisHotkey, "*")
  keywait(key)
  send("{RShift up}")
}

/**
 * 绑定当前窗口到当前键上
 * @param key 当前键
 * @returns {void} 
 */
BindWindow() {
  window := false
  handler(thisHotKey) {
    waitkey := KeymapManager.ExtractWaitKey(thisHotKey)
    startTick := A_TickCount
    KeyWait(waitkey)
    if (A_TickCount - startTick > 300) {
      ; 绑定窗口
      window := WinGetID("A")
      Tip("已绑定当前窗口")
      return
    }

    if (window && WinExist("ahk_id " window)) {
      WinActivate(window)
    } else {
      Tip("请长按绑定窗口")
    }
  }

  return handler
}

/**
 * 关闭同应用的所有窗口
 */
CloseSameClassWindows() {
  if IsDesktop()
    return

  exe := WinGetProcessName("A")
  for i, hwnd in FindWindows("ahk_exe " exe) {
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
SlideToShutDown() {
  Run(SlideToShutDown)
  sleep(1300)
  MouseClick("Left", 100, 100)
}

/**
 * 重启
 */
SlideToReboot() {
  Shutdown(2)
}


/**
 * 切换Capslock状态
 */
toggleCapslock() {
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
    MsgBox("帮助文件未生成，需要打开设置点一下保存")
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
  if IsDesktop()
    return

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
ProcessExistSendKeyOrRun(process, key, target) {
  if (FindHiddenWindows("ahk_exe " process).Length) {
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