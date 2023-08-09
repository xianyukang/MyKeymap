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