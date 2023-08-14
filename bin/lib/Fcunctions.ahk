#Include TypoTipWindow.ahk
#Include TempFocusGui.ahk

/**
 * 托盘菜单被点击
 * @param ItemName 
 * @param ItemPos 
 * @param MyMenu 
 */
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

/**
 * 退出程序
 * @param ExitReason 退出原因
 * @param ExitCode 传递给 Exit 或 ExitApp 的退出代码.
 */
MyExit(ExitReason, ExitCode) {
  if (capsAbbrWindowPid)
    ProcessClose(capsAbbrWindowPid)
}

/**
 * 暂停
 */
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

/**
 * 打开设置
 */
OpenSettings() {
  if (!WinExist("\bin\settings.exe"))
    Run("./bin/settings.exe ./bin")

  try {
    WinActivate("MyKeymap Settings")
  } catch Error as e {
    Run("http://127.0.0.1:12333")
  }
}

/**
 * 重启程序
 */
ReloadPropram() {
  Tip("Reload")
  Run("MyKeymap.exe")
}

/**
 * 关闭所有模式
 * @param Thrown 抛出的值, 通常为 Error 对象
 * @param Mode 错误的模式: Return, Exit 或 ExitApp
 */
CloseAllMode(Thrown?, Mode?) {
  global customHotKey := true

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

  global modeState
  modeState.locked := false
}

/**
 * 自动关闭的提示窗口 
 * @param message 要提示的文本
 * @param {number} time 超时后关闭
 */
Tip(message, time := -1500) {
  ToolTip(message)
  SetTimer(() => ToolTip(), time)
}

/**
 * 获取鼠标移动时的提示窗口
 */
GetMouseMovePromptWindow() {
  return TypoTipWindow("🖱", 16, 4, 0)
}

/**
 * 移动鼠标
 * @param key 按下的值
 * @param directionX 向左-1 向右1
 * @param directionY 向上-1 向下1
 * @param moveSingle 首次移动的步长
 * @param moveRepeat 移动的步长
 * @param {number} showTip 是否提示当前为鼠标模式
 */
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

/**
 * 当按键等待时执行的操作
 * @param key 按下的值
 * @param delay1 首次等待的时间
 * @param delay2 等待的时间
 * @param func 当超过等待时间执行的方法
 */
WhileKeyWait(key, delay1, delay2, func) {
  i := KeyWait(key, delay1)
  while (!i) {
    func()

    i := KeyWait(key, delay2)
  }
}

/**
 * 退出鼠标移动模式
 */
ExitMouseMode() {
  global mouseMode := false

  Send("{Blind}{LButton up}")

  if (IsSet(mousemovePrompt))
    mousemovePrompt.show
}

/**
 * 模拟鼠标点击后推出
 * @param key 模拟鼠标的键
 */
MouseClickAndExit(key) {
  Send("{blind}" key)
  if (needExitMouseMode)
    ExitMouseMode()
}

/**
 * 滚轮滑动一次
 * @param direction 方向
 *   1:上
 *   2:下
 *   3:左
 *   4:右
 * @param {number} scrollCount 滑动次数
 */
ScrollWheelOnce(direction, scrollCount := 1) {
  switch (direction) {
    case 1: MouseClick("WheelUp", , , scrollCount)
    case 2: MouseClick("WheelDown", , , scrollCount)
    case 3: MouseClick("WheelLeft", , , scrollCount)
    case 4: MouseClick("WheelRight", , , scrollCount)
  }
}

/**
 * 冻结非指定的模式
 * @param modeName 模式名称
 */
FreezeOtherMode(modeName) {
  global activatedModes, customHotKey, altTabIsOpen, modeState
  customHotKey := true
  altTabIsOpen := false

  ; 比如锁定了 3, 但同时想用 9 模式的热键, 需要临时取消锁定
  if (modeState.locked) {
    %modeState.currentRef% := false
  }

  for index, value in activatedModes {
    if (value != modeName) {
      Hotkey(value, "Off")
    }
  }
}

/**
 * 重置当前运行的热键
 * @param modeName 模式的名称
 * @param modeRef 模式变量的引用
 * @returns {void} 
 */
ResetCurrentMode(modeName, &modeRef) {
  global modeState
  if (modeState.locked)
    return

  modeState.currentName := modeName
  ; 指定其引用，不然后面无法改模式的状态
  modeState.currentRef := &modeRef
}

/**
 * 解冻非指定的模式
 * @param modeName 模式名称
 */
UnfreezeMode(modeName) {
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
    if (value != modeName)
      Hotkey(value, "On")
  }

}

/**
 * 启动指定Mode
 * @param modeRef 模式变量的引用
 * @param modeName 模式的名称
 * @param mil 超时时间
 * @param func 非超时执行的操作
 * @param {number} needFreezeOtherMode 是否需要解冻其他模式，二级模式不需要解冻，比如CaspF模式、CapsSpace模式等。
 */
EnableMode(&modeRef, modeName, mil?, func?, needFreezeOtherMode := true) {
  statrtTick := A_TickCount
  thisHotKey := A_ThisHotkey
  modeRef := true
  ; Caps F、Caps 空格之类的二级模式是不用触发冻结的
  if (needFreezeOtherMode) {
    FreezeOtherMode(ThisHotkey)
    ResetCurrentMode(modeName, &modeRef)
  }
  KeyWait(thisHotKey)
  modeRef := false

  if (IsSet(mil))
    if ((A_PriorKey != "" && A_PriorKey = thisHotkey) && A_TickCount - statrtTick < mil)
      if (IsSet(func))
        func()

  ; 因为没有触发冻结所以不需要解冻
  if (needFreezeOtherMode) {
    UnfreezeMode(ThisHotkey)
  }
}

/**
 * 获取当前程序名称
 * 自带的WinGetProcessName无法获取到uwp应用的名称
 * 来源：https://www.autohotkey.com/boards/viewtopic.php?style=7&t=112906
 * @returns {string} 
 */
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
    if (A_LoopField)
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
}

/**
 * 通过命令行去启动程序，防止会导致以管理员启动软件的问题
 * @param target 程序路径 
 * @param arguments 参数
 * @param directory 工作目录
 * @param operation 选项
 * @param show 是否显示
 */
ShellRun(target, arguments?, directory?, operation?, show?) {
  static VT_UI4 := 0x13, SWC_DESKTOP := ComValue(VT_UI4, 0x8)
  ComObject("Shell.Application").Windows.Item(SWC_DESKTOP).Document.Application
    .ShellExecute(target, arguments?, directory?, operation?, show?)
}

/**
 * 以管理员权限打开软件
 * @param target 程序路径
 * @param args 参数
 * @param workingDir 工作目录
 */
RunAsAdmin(target, args, workingDir) {
  try {
    Run("*RunAs " target " " args, workingDir)
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
    hwnd := FindHiddenWindows(winTitle)
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

/**
 * 查找隐藏窗口返回窗口的Hwnd 
 * @param winTitle AHK中的WinTitle
 * @returns {array} 
 */
FindHiddenWindows(winTitle) {
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

/**
 * 返回与指定条件匹配的所有窗口
 * @param winTitle AHK中的WinTitle
 * @param predicate 过滤窗口方法，传过Hwnd，返回bool
 * @returns {array} 
 */
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

/**
 *  将程序路径或参数中的{selected_text} 替换为选中的文字
 * @param target 程序路径的引用
 * @param args 参数的引用
 * @returns {void|number} 
 */
ReplaceSelectedText(&target, &args) {
  text := GetSelectedText()
  if not (text) {
    return
  }

  if InStr(args, "://") || InStr(target, "://") {
    text := URIEncode(text)
  }
  args := strReplace(args, "{selected_text}", text)
  target := strReplace(target, "{selected_text}", text)

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
  if not (ClipWait(0.5)) {
    Tip("没有获取到文本", -700)
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

/**
 * 启动InputHook，并返回EndReason
 * @param ih InputHook对象
 * @returns {void} 
 */
StartInputHook(ih) {
  ; 禁用所有热键
  Suspend(true)

  ; RAlt 映射到 LCtrl 后,  按下 RAlt 再触发 Capslock 命令会导致 LCtrl 键一直处于按下状态
  if GetKeyState("LCtrl") {
    Send("{LCtrl Up}")
  }

  ; 启动监听等待输入匹配后关闭监听
  ih.Start()
  endReason := ih.Wait()
  ih.Stop()
  ; 恢复所有热键
  Suspend(false)

  return endReason
}

/**
 * 发送消息到命令提示框
 * @param msg 消息编号
 * @param {number} wParam 消息参数
 */
PostMessageToCpasAbbr(msg, wParam := 0) {
  temp := A_DetectHiddenWindows
  DetectHiddenWindows(1)
  PostMessage(msg, wParam, 0, , "ahk_pid " capsAbbrWindowPid)
  DetectHiddenWindows(temp)
}

/**
 * 关闭顶部命令提示框
 */
HideCaspAbbr() {
  HIDE_COMMAND_INPUT := 0x0400 + 0x0002
  PostMessageToCpasAbbr(HIDE_COMMAND_INPUT)
}

/**
 *  将键入的值发送到输入框
 * @param ih InputHook 对象
 * @param char 发送的字符
 */
PostCharToCaspAbbr(ih?, char?) {
  static SEND_CHAR := 0x0102
  PostMessageToCpasAbbr(SEND_CHAR, Ord(char))
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
 * 获取光标的位置
 * 来源：https://github.com/Ixiko/AHK-libs-and-classes-collection/blob/e5e1666d016c219dc46e7fc97f2bcbf40a9c0da5/AHK_V2/Misc.ahk#L328 GetCaretPos 方法
 * @param X 光标相对于屏幕X轴的位置
 * @param Y 光标相对于屏幕Y轴的位置
 * @param W 光标的宽度
 * @param H 光标的高度
 * @returns {void} 
 */
GetCaretPos(&X?, &Y?, &W?, &H?) {
  ; UIA2 caret
  static IUIA := ComObject("{e22ad333-b25f-460c-83d0-0581107395c9}", "{34723aff-0c9d-49d0-9896-7ab52df8cd8a}")
  try {
    ComCall(8, IUIA, "ptr*", &FocusedEl := 0) ; GetFocusedElement
    ComCall(16, FocusedEl, "int", 10024, "ptr*", &patternObject := 0), ObjRelease(FocusedEl) ; GetCurrentPattern. TextPatternElement2 = 10024
    if patternObject {
      ComCall(10, patternObject, "int*", &IsActive := 1, "ptr*", &caretRange := 0), ObjRelease(patternObject) ; GetCaretRange
      ComCall(10, caretRange, "ptr*", &boundingRects := 0), ObjRelease(caretRange) ; GetBoundingRectangles
      if (Rect := ComValue(0x2005, boundingRects)).MaxIndex() = 3 { ; VT_ARRAY | VT_R8
        X := Round(Rect[0]), Y := Round(Rect[1]), W := Round(Rect[2]), H := Round(Rect[3])
        return
      }
    }
  }

  ; Acc caret
  static _ := DllCall("LoadLibrary", "Str", "oleacc", "Ptr")
  try {
    idObject := 0xFFFFFFF8 ; OBJID_CARET
    if DllCall("oleacc\AccessibleObjectFromWindow", "ptr", WinExist("A"), "uint", idObject &= 0xFFFFFFFF
      , "ptr", -16 + NumPut("int64", idObject == 0xFFFFFFF0 ? 0x46000000000000C0 : 0x719B3800AA000C81, NumPut("int64", idObject == 0xFFFFFFF0 ? 0x0000000000020400 : 0x11CF3C3D618736E0, IID := Buffer(16)))
      , "ptr*", oAcc := ComValue(9, 0)) = 0 {
      x := Buffer(4), y := Buffer(4), w := Buffer(4), h := Buffer(4)
      oAcc.accLocation(ComValue(0x4003, x.ptr, 1), ComValue(0x4003, y.ptr, 1), ComValue(0x4003, w.ptr, 1), ComValue(0x4003, h.ptr, 1), 0)
      X := NumGet(x, 0, "int"), Y := NumGet(y, 0, "int"), W := NumGet(w, 0, "int"), H := NumGet(h, 0, "int")
      if (X | Y) != 0
        return
    }
  }

  ; Default caret
  savedCaret := A_CoordModeCaret, W := 4, H := 20
  CoordMode "Caret", "Screen"
  CaretGetPos(&X, &Y)
  CoordMode "Caret", savedCaret
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
