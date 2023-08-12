; 慢速移动鼠标
SlowMoveMouse(key, directionX, directionY) {
  MoveMouse(key, directionX, directionY, slowMoveSingle, slowMoveRepeat, mousemovePrompt ?? false)
}

; 快速移动鼠标并进入移动鼠标模式
FastMoveMouse(key, directionX, directionY) {
  global mouseMode := true
  MoveMouse(key, directionX, directionY, fastMoveSingle, fastMoveRepeat)
}

; 左键按下
LbuttonDown() => MouseClickAndExit("{LButton Down}")

; 左键点击
LbuttonClick() => MouseClickAndExit("{Lbutton}")

; 左键双击
LbuttonDoubleClick() => MouseClickAndExit("{Lbutton 2}")

; 左键三击
LbuttonTrippleClick() => MouseClickAndExit("{Lbutton 3}")

; 右键点击
RbuttonClick() => MouseClickAndExit("{Rbutton}")

; 滚轮滑动
ScrollWheel(key, direction) {
  ScrollWheelOnce(direction, scrollOnceLineCount)

  WhileKeyWait(key, scrollDelay1, scrollDelay2, () => ScrollWheelOnce(direction, scrollOnceLineCount))
}

; 滚轮滑动一次
ScrollWheelOnce(direction, scrollCount := 1) {
  switch (direction) {
    case 1: MouseClick("WheelUp", , , scrollCount)
    case 2: MouseClick("WheelDown", , , scrollCount)
    case 3: MouseClick("WheelLeft", , , scrollCount)
    case 4: MouseClick("WheelRight", , , scrollCount)
  }
}

; 移动鼠标到活动窗口中心
MouseToActiveWindowCenter() {
  WinGetPos(&X, &Y, &W, &H, "A")
  MouseMove(x + w / 2, y + h / 2)
}

; 移动活动窗口位置
MouseMoveActiveWindowPos() {
  hwnd := WinExist("A")
  if (WinGetMinMax("A"))
    WinRestore("A")

  PostMessage("0x0112", "0xF010", 0)
  Sleep 50
  SendInput("{Right}")
}

; 锁定当前模式
LockCurrentMode() {
  global modeState, mouseMode

  if (modeState.locked) {
    mouseMode := false
    %modeState.currentRef% := false
    modeState.locked := false
    Tip(" 取消锁定 ", -400)
  } else {
    modeState.locked := true
    Tip(" 锁定 -> " modeState.currentName, -400)
  }
}

; 启动程序或切换到程序
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

; 切换程序窗口
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

; CapsLock缩写框
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

; semi缩写框
EnterSemicolonAbbr() {
  semiHookAbbrWindow.Show("    ")
  endReason := StartInputHook(semiHook)
  semiHookAbbrWindow.Hide

  if (semiHook.Match)
    ExecSemicolonAbbr(semiHook.Match)
}

; 启动InputHook，并返回EndReason
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

; 智能的关闭窗口
SmartCloseWindow() {
  if IsDesktopWindowActive()
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

; 开启任务切换模式
EnableTaskSwitchMode() {
  global TaskSwitchMode, modeState
  ; 关闭所有模式
  CloseAllMode()

  TaskSwitchMode := true
  send("^!{tab}")
  ; 等待选择完程序
  if (WinWaitActive("ahk_group taskSwitchGroup", , 0.5)) {
    WinWaitNotActive("ahk_group taskSwitchGroup")
  }
  TaskSwitchMode := false

  ; 恢复被锁定的模式
  if (modeState.locked) {
    %modeState.currentRef% := true
  }

}

; 窗口居中并修改其大小
CenterAndResizeWindow(width, height) {
  if (IsDesktopWindowActive())
    return

  ; 在 mousemove 时需要 PER_MONITOR_AWARE (-3), 否则当两个显示器有不同的缩放比例时, mousemove 会有诡异的漂移
  ; 在 winmove 时需要 UNAWARE (-1), 这样即使写死了窗口大小为 1200x800, 系统会帮你缩放到合适的大小
  DllCall("SetThreadDpiAwarenessContext", "ptr", -1, "ptr")

  WinExist("A")
  state := WinGetMinMax()
  if (state) 
    WinRestore

  WinGetPos &x, &y, &w, &h

  ms := GetMonitorAt(x+w/2, y+h/2)
  MonitorGetWorkArea(ms, &l, &t, &r, &b)
  w := r-l
  h := b-t

  winW := Min(width, w)
  winH := Min(height, h)
  winX := l + (w -winW) / 2
  winY := t + (h -winH) / 2

  WinMove(winX, winY, winW, winH)
  DllCall("SetThreadDpiAwarenessContext", "ptr", -3, "ptr")
}