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