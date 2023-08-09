#Include TypoTipWindow.ahk

; 托盘菜单被点击
TrayMenuHandler(ItemName, ItemPos, MyMenu) {
  switch ItemName {
    case "退出":
      MyExit()
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
MyExit() {
  thisPid := DllCall("GetCurrentProcessId")
  ProcessClose(thisPid)
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

; 自动关闭的提示窗口
Tip(message, time := -1500) {
  ToolTip(message)
  SetTimer(() => ToolTip(), time)
}

; 获取鼠标移动时的提示窗口
GetMouseMovePromptWindow() {
  return TypoTipWindow("🖱", 16, 4, 0)
}

; 慢速移动鼠标
SlowMoveMouse(key, directionX, directionY) {
  MoveMouse(key, directionX, directionY, slowMoveSingle, slowMoveRepeat, mousemovePrompt ?? false)
}

; 快速移动鼠标并进入移动鼠标模式
FastMoveMouse(key, directionX, directionY) {
  global MouseMode := true
  MoveMouse(key, directionX, directionY, fastMoveSingle, fastMoveRepeat)
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

; 退出鼠标移动模式
ExitMouseMode() {
  global MouseMode := false

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