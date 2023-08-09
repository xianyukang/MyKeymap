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