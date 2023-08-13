#Include TypoTipWindow.ahk
#Include TempFocusGui.ahk

; 托盘菜单被点击
TrayMenuHandler(ItemName, ItemPos, MyMenu) {
  switch ItemName {
    case "退出":
      ExitApp
    case "暂停":
      ToggleSuspend()
    case "重启程序":
      ReloadPropram()
    case "打开设置":
      OpenSettings()
    case "帮助文档":
      Run("https://xianyukang.com/MyKeymap.html")
    case "查看窗口标识符":
      run("MyKeymap.exe bin\WindowSpy.ahk")

  }
}

; 关闭程序
MyExit(ExitReason, ExitCode) {
  if (capsAbbrWindowPid)
    ProcessClose(capsAbbrWindowPid)
}

; 暂停
ToggleSuspend() {
  Suspend(!A_IsSuspended)
  if (A_IsSuspended) {
    TraySetIcon("./bin/icons/logo2.ico", , 1)
    A_TrayMenu.Check("暂停")
    Tip("  暂停 MyKeymap  ", -500)
  } else {
    TraySetIcon("./bin/icons/logo.ico", , 0)
    A_TrayMenu.UnCheck("暂停")
    Tip("  恢复 MyKeymap  ", -500)
  }
}

; 打开设置
OpenSettings() {
  if (!WinExist("\bin\settings.exe"))
    Run("./bin/settings.exe ./bin")

  try {
    WinActivate("MyKeymap Settings")
  } catch Error as e {
    Run("http://127.0.0.1:12333")
  }
}

; 重启程序
ReloadPropram() {
  Tip("Reload")
  Run("MyKeymap.exe")
}

; 关闭所有模式
CloseAllMode(Thrown?, Mode?) {
  customHotKey := true

  global capslockMode := false
  global jMode := false
  global semicolonMode := false
  global threeMode := false
  global nincMode := false
  global commaMode := false
  global dotModel := false
  global additionalMode1 := false
  global additionalMode2 := false
  global spaceMode := false
  global tabMode := false
  global rButtonMode := false
  global lButtonMode := false

  global capsFMode := false
  global capsSpaceMode := false
  global jKModel := false

  global mouseMode := false
  global TaskSwitchMode := false
}

; 自动关闭的提示窗口
Tip(message, time := -1500) {
  ToolTip(message)
  SetTimer(() => ToolTip(), time)
}

; 获取鼠标移动时的提示窗口
GetMouseMovePromptWindow() {
  return TypoTipWindow("🖱", 16, 4, 0)
}

; 移动鼠标
MoveMouse(key, directionX, directionY, moveSingle, moveRepeat, showTip := false) {
  oneX := directionX * moveSingle
  oneY := directionY * moveSingle
  repeatX := directionX * moveRepeat
  repeatY := directionY * moveRepeat
  MouseMove(oneX, oneY, 0, "R")

  if showTip
    showTip.Show(, 19, 17)

  f() {
    if showTip
      showTip.Show(, 19, 17)
    MouseMove(repeatX, repeatY, 0, "R")
  }

  WhileKeyWait(key, moveDelay1, moveDelay2, f)
}

; 当按键等待时执行的操作
WhileKeyWait(key, delay1, delay2, func) {
  i := KeyWait(key, delay1)
  while (!i) {
    func()

    i := KeyWait(key, delay2)
  }
}

; 退出鼠标移动模式
ExitMouseMode() {
  global mouseMode := false

  Send("{Blind}{LButton up}")

  if (IsSet(mousemovePrompt))
    mousemovePrompt.show
}

; 鼠标点击后推出
MouseClickAndExit(key) {
  Send("{blind}" key)
  if (needExitMouseMode)
    ExitMouseMode()
}

; 冻结非指定的模式
FreezeOtherMode(mode) {
  global activatedModes, customHotKey, altTabIsOpen, modeState
  customHotKey := true
  altTabIsOpen := false

  ; 比如锁定了 3, 但同时想用 9 模式的热键, 需要临时取消锁定
  if (modeState.locked) {
    %modeState.currentRef% := false
  }

  for index, value in activatedModes {
    if (value != mode) {
      Hotkey(value, "Off")
    }
  }
}

; 重置当前运行的热键
ResetCurrentMode(modeName, &modeRef) {
  global modeState
  if (modeState.locked)
    return

  modeState.currentName := modeName
  ; 指定其引用，不然后面无法改模式的状态
  modeState.currentRef := &modeRef
}

; 优先解冻被锁定模式，如果没有被锁定模式则解冻全部
UnfreezeMode(mode) {
  global activatedModes, customHotKey, altTabIsOpen, modeState
  customHotKey := false

  if (altTabIsOpen) {
    altTabIsOpen := false
    Send("{Enter}")
  }

  ; 启动被锁定的模式
  if (modeState.locked) {
    %modeState.currentRef% := true
  }

  for index, value in activatedModes {
    if (value != mode)
      Hotkey(value, "On")
  }

}

; 启动指定Mode
EnableMode(&mode, modeName, mil?, func?, needFreezeOtherMode := true) {
  statrtTick := A_TickCount
  thisHotKey := A_ThisHotkey
  mode := true
  ; Caps F、Caps 空格之类的二级模式是不用触发冻结的
  if (needFreezeOtherMode) {
    FreezeOtherMode(ThisHotkey)
    ResetCurrentMode(modeName, &mode)
  }
  KeyWait(thisHotKey)
  mode := false

  if (IsSet(mil))
    if ((A_PriorKey != "" && A_PriorKey = thisHotkey) && A_TickCount - statrtTick < mil)
      if (IsSet(func))
        func()

  ; 因为没有触发冻结所以不需要解冻
  if (needFreezeOtherMode) {
    UnfreezeMode(ThisHotkey)
  }
}

; 获取程序名称
; 自带的WinGetProcessName无法获取到uwp应用的名称
; https://www.autohotkey.com/boards/viewtopic.php?style=7&t=112906
GetProcessName() {
  fn := (winTitle) => (WinGetProcessName(winTitle) == 'ApplicationFrameHost.exe')

  winTitle := "A"
  if fn(winTitle) {
    for hCtrl in WinGetControlsHwnd(winTitle)
      bool := fn(hCtrl)
    until !bool && winTitle := hCtrl
  }

  return WinGetProcessName(winTitle)
}

; 从环境中补全程序的绝对路径
; https://autohotkey.com/board/topic/20807-fileexist-in-path-environment/
CompleteProgramPath(fileName) {

  ; 工作目录下的程序
  PathName := A_WorkingDir "\" fileName
  if FileExist(PathName)
    return PathName

  ; 本身便是绝对路径
  if FileExist(fileName)
    return fileName

  ; 从环境变量 PATH 中获取
  DosPath := EnvGet("PATH")
  loop parse DosPath, "`;" {
    if (A_LoopField)
      continue

    if FileExist(A_LoopField "\" fileName)
      return A_LoopField "\" fileName
  }

  ; 从安装的程序中获取
  try {
    PathName := RegRead("HKLM", "SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\" fileName)
    if FileExist(PathName)
      return PathName
  }
}

; 通过命令行去启动程序，即使脚本以管理员模式启动也不会造成软件也是以管理员启动的问题
ShellRun(filePath, arguments?, directory?, operation?, show?) {
  static VT_UI4 := 0x13, SWC_DESKTOP := ComValue(VT_UI4, 0x8)
  ComObject("Shell.Application").Windows.Item(SWC_DESKTOP).Document.Application
    .ShellExecute(filePath, arguments?, directory?, operation?, show?)
}

; 以管理员权限打开软件
RunAsAdmin(target, args, workingDir) {
  try {
    Run("*RunAs " target " " args, workingDir)
  } catch Error as e {
    Tip("使用管理启动失败 " target ", " e.Message)
  }
}

; 运行程序或打开目录，用于解决打开的程序无法获取焦点的问题
RunPrograms(target, args := "", workingDir := "", admin := false) {
  ; 记录当前窗口的hwnd，当软件启动失败时还原焦点
  currentHwnd := WinExist("A")
  ; 通过一个界面先获取焦点再执行启动程序，当失去焦点时自己关闭
  TempFocusGui().ShowGui()

  try {
    ; 补全程序路径
    programPath := CompleteProgramPath(target)
    if not (programPath) {
      ; 没有找到程序，可能是ms-setting: 之类的连接
      Run(target " " args, workingDir)
      return
    }

    ; 如果是文件夹直接打开
    if (InStr(FileExist(programPath), "D")) {
      Run(programPath)
      return
    }

    if (admin) {
      runAsAdmin(programPath, args, workingDir)
    } else {
      ShellRun(programPath, args, workingDir)
    }

  } catch Error as e {
    Tip(e.Message)
    ; 还原窗口焦点
    WinActivate(currentHwnd)
    return
  }
}

; 激活窗口
ActivateWindow(winTitle := "", isHide := false) {
  ; 如果匹配不到窗口且认为窗口为隐藏窗口时查找隐藏窗口
  hwnds := FindWindows(winTitle, (hwnd) => WinGetTitle(hwnd) != "")
  if ((!hwnds.Length) && isHide) {
    hwnd := FindHiddenWindow(winTitle)
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
    SwitchWindows(winTitle, hwnds)
  }

  return 1
}

; 查找隐藏窗口返回窗口的HWND
FindHiddenWindow(winTitle) {
  WS_MINIMIZEBOX := 0x00020000
  WS_MINIMIZE := 0x20000000

  ; 窗口过滤条件
  ; 标题不为空、窗口大小大于400包含最小化按钮或被最小化了
  Predicate(hwnd) {
    if (WinGetTitle(hwnd) = "")
      return false

    style := WinGetStyle(hwnd)
    if not (style & WS_MINIMIZEBOX)
      return false

    WinGetPos(&x, &y, &windth, &height, hwnd)
    return (height > 400 && windth > 400) || (style & WS_MINIMIZE)
  }

  ; 开启可以查找到隐藏窗口
  DetectHiddenWindows true
  hwnds := FindWindows(winTitle, Predicate)
  DetectHiddenWindows false

  return hwnds
}

; 返回与指定条件匹配的所有窗口
FindWindows(winTitle, predicate?) {
  temps := WinGetList(winTitle)
  hwnds := []

  for hwnd in temps {
    hwnd := temps.Get(A_Index)
    ; 当有谓词条件且满足时添加这个hwnd
    if (IsSet(predicate) && (predicate(hwnd))) {
      hwnds.Push(hwnd)
    }
  }
  return hwnds
}

; 将参数中的{selected_text} 替换为被选中的文字
ReplaceSelectedText(&target, &args) {
  text := GetSelectedText()
  if not (text) {
    return
  }

  if InStr(args, "://") || InStr(target, "://") {
    text := URLEncode(text)
  }
  args := strReplace(args, "{selected_text}", text)
  target := strReplace(target, "{selected_text}", text)

  return 1
}

; 获取选中的文字
GetSelectedText() {
  temp := A_Clipboard
  ; 清空剪贴板
  A_Clipboard := ""

  Send("^c")
  if not (ClipWait(0.5)) {
    Tip("没有获取到文本", -700)
    return
  }
  text := A_Clipboard

  A_Clipboard := temp
  return RTrim(text, "`r`n")
}

; url 编码
; https://www.autohotkey.com/boards/viewtopic.php?t=112741
URLEncode(Uri, encoding := "UTF-8") {
  var := Buffer(StrPut(Uri, encoding), 0)
  StrPut(Uri, var, encoding)
  pos := 1
  While pos <= StrLen(Uri) {
    code := NumGet(var, pos - 1, "UChar")
    if (code >= 0x30 && code <= 0x39) || (code >= 0x41 && code <= 0x5A) || (code >= 0x61 && code <= 0x7A)
      res .= Chr(code)
    else
      res .= "%" . Format("{:02X}", code)
    pos++
  }
  return res
}

; 发送消息到命令提示框
PostMessageToCpasAbbr(type, wParam := 0) {
  temp := A_DetectHiddenWindows
  DetectHiddenWindows(1)
  PostMessage(type, wParam, 0, , "ahk_pid " capsAbbrWindowPid)
  DetectHiddenWindows(temp)
}

; 关闭顶部命令提示框
HideCaspAbbr() {
  HIDE_COMMAND_INPUT := 0x0400 + 0x0002
  PostMessageToCpasAbbr(HIDE_COMMAND_INPUT)
}

; 将键入的值发送到输入框
PostCharToCaspAbbr(ih?, char?) {
  static SEND_CHAR := 0x0102
  PostMessageToCpasAbbr(SEND_CHAR, Ord(char))
}

; 判断当前窗口是不是桌面
IsDesktop() {
  return WinActive("Program Manager ahk_class Progman") || WinActive("ahk_class WorkerW")
}

; 获取当前焦点在哪个显示器上
GetMonitorAt(x, y, default := 1) {
  m := SysGet(80)
  loop m {
    MonitorGet(A_Index, &l, &t, &r, &b)
    if (x >= l && x <= r && y >= t && y <= b)
      return A_Index
  }
  return default
}

; 当前窗口是最大化还是最小化
WindowMaxOrMin(winTitle := "A") {
  return WinGetMinMax(winTitle)
}