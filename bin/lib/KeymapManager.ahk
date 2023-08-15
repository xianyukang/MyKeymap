class KeymapManager {
  static Locked := false
  static GlobalKeymap := Keymap("GlobalKeymap")
  static Stack := Array(this.GlobalKeymap)

  static NewKeymap(globalHotkey) {
    ; 分配全局热键激活指定 keymap
    return this.AddSubKeymap(this.GlobalKeymap, globalHotkey)
  }

  static AddSubKeymap(parent, hk) {
    waitKey := this.ExtractWaitKey(hk)
    subKeymap := Keymap(hk, waitKey)
    handler(thisHotkey) {
      this.Activate(subKeymap)
      this._postHandler()
    }
    parent.Map(hk, handler)
    return subKeymap
  }

  static _postHandler() {
    ; 等松开全部按钮时才处理锁定逻辑
    if this.Stack.Length != 1 {
      return
    }
    ; 比如直接锁定 3 模式
    ; 比如锁住 3 模式然后使用 9 模式热键, 9 模式退出前要恢复 3 模式
    if KeymapManager.Locked {
      KeymapManager.Locked.Enable()

      ; 在系统 AltTab 窗口中激活 TaskSwitch 模式, 等 AltTab 窗口关闭后要关闭 TaskSwitch 模式
      if KeymapManager.Locked.AfterLocked {
        SetTimer(KeymapManager.Locked.AfterLocked, -1)
      }
    }
  }

  static Activate(keymap) {
    this.Stack.Push(keymap)
    keymap.Enable()
    startTick := A_TickCount
    KeyWait(keymap.WaitKey)
    if (A_PriorKey = keymap.WaitKey && (A_TickCount - startTick < 300)) {
      keymap.SinglePressAction()
    }
    this.Stack.Pop().Disable()
    this.Stack.Get(-1).Enable() ; 退出前, 恢复上一个模式
  }

  static LockKeymap(toLock, toggle, show) {
    ; 未锁定
    if !KeymapManager.Locked {
      this.ShowToolTip("已锁定 " toLock.Name, show)
      KeymapManager.Locked := toLock
      return
    }
    ; 已经锁定了自己
    if KeymapManager.Locked == toLock {
      if !toggle {
        return
      }
      this.ShowToolTip("取消锁定", show)
      KeymapManager.UnLock()
      return
    }
    ; 锁定了别的模式, 那么切换成锁定自己
    this.ShowToolTip("锁定切换: " KeymapManager.Locked.Name " -> " toLock.Name, show)
    KeymapManager.Locked.Disable()
    KeymapManager.GlobalKeymap.Enable()
    KeymapManager.Locked := toLock
  }

  static UnLock() {
    if KeymapManager.Locked {
      KeymapManager.Locked.Disable()
      KeymapManager.GlobalKeymap.Enable()
      KeymapManager.Locked := false
    }
  }

  static ClearLock() {
    KeymapManager.Locked := false
  }

  static ExtractWaitKey(hotkey) {
    waitKey := Trim(hotkey, " #!^+<>*~$")
    if InStr(waitKey, "&") {
      sp := StrSplit(waitKey, "&")
      waitKey := Trim(sp[2])
    }
    return waitKey
  }

  static ShowToolTip(msg, show := true) {
    if !show {
      return
    }
    ToolTip(msg)
  }
}


class Keymap {
  __New(name := "", waitKey := "") {
    this.Name := name
    this.WaitKey := waitKey
    this.SinglePressAction := NoOperation
    this.M := Map()
    this.ToggleLock := this._lockOrUnlock.Bind(this)
    this.AfterLocked := false
  }

  Map(hotkeyName, handler, keymapToLock := false, toggle := false) {
    wrapper(thisHotkey) {
      handler(thisHotkey)
      if !keymapToLock {
        return
      }
      KeymapManager.LockKeymap(keymapToLock, false, false)

      ; 锁住后直接执行热键, 没有按下任何引导键 ( 比如先锁住 Caps 然后直接按 E )
      if KeymapManager.Stack.Length == 1 {
        KeymapManager._postHandler()
      }
    }
    if hotkeyName == "SinglePress" {
      this.SinglePressAction := wrapper
      return
    }
    this.M[hotkeyName] := wrapper
  }

  MapSinglePress(handler) {
    this.Map("SinglePress", handler)
  }

  Enable() {
    for hotkeyName, handler in this.M {
      Hotkey(hotkeyName, handler, "On")
    }
  }

  Disable() {
    for hotkeyName, handler in this.M {
      Hotkey(hotkeyName, "Off")
    }
  }

  _lockOrUnlock(thiHotkey) {
    KeymapManager.LockKeymap(this, true, true)
  }

  RemapKey(a, b) {
    downHandler(thisHotkey) {
      Send "{Blind}{" b " DownR}"
    }
    upHandler(thisHotkey) {
      Send "{Blind}{" b " Up}"
    }
    this.Map("*" a, downHandler)
    this.Map("*" a " up", upHandler)
  }

  SendKeys(hk, keys) {
    handler(thisHotkey) {
      Send(keys)
    }
    this.Map(hk, handler)
  }
}

class MouseKeymap extends Keymap {

  __New(single, repeat, delay1, delay2, scrollOnceLineCount, scrollDelay1, scrollDelay2, lockHandler) {
    super.__New()
    this.single := single
    this.repeat := repeat
    this.delay1 := delay1
    this.delay2 := delay2
    this.scrollOnceLineCount := scrollOnceLineCount
    this.scrollDelay1 := scrollDelay1
    this.scrollDelay2 := scrollDelay2
    this.lockHandler := lockHandler

    this.MoveMouseUp := this._moveMouse.Bind(this, 0, -1)
    this.MoveMouseDown := this._moveMouse.Bind(this, 0, 1)
    this.MoveMouseLeft := this._moveMouse.Bind(this, -1, 0)
    this.MoveMouseRight := this._moveMouse.Bind(this, 1, 0)
    this.ScrollWheelUp := this._scrollWheel.Bind(this, 1)
    this.ScrollWheelDown := this._scrollWheel.Bind(this, 2)
    this.ScrollWheelLeft := this._scrollWheel.Bind(this, 3)
    this.ScrollWheelRight := this._scrollWheel.Bind(this, 4)
  }

  static SetMoveMouseKeys(km, fast, slow, up, down, left, right) {

    km.Map(up, fast.MoveMouseUp, slow)
    km.Map(down, fast.MoveMouseDown, slow)
    km.Map(left, fast.MoveMouseLeft, slow)
    km.Map(right, fast.MoveMouseRight, slow)

    slow.Map(up, slow.MoveMouseUp)
    slow.Map(down, slow.MoveMouseDown)
    slow.Map(left, slow.MoveMouseLeft)
    slow.Map(right, slow.MoveMouseRight)
  }

  static SetScrollWheelKeys(km, fast, slow, up, down, left, right) {

    km.Map(up, fast.ScrollWheelUp)
    km.Map(down, fast.ScrollWheelDown)
    km.Map(left, fast.ScrollWheelLeft)
    km.Map(right, fast.ScrollWheelRight)

    slow.Map(up, slow.ScrollWheelUp)
    slow.Map(down, slow.ScrollWheelDown)
    slow.Map(left, slow.ScrollWheelLeft)
    slow.Map(right, slow.ScrollWheelRight)

  }

  static SetMouseButtonKeys(km, fast, slow, lbutton, rbutton, lbuttonDown, lbuttonUp) {

    km.Map(lbutton, fast.LButton())
    km.Map(rbutton, fast.RButton())
    km.Map(lbuttonDown, fast.LButtonDown())

    slow.Map(lbutton, slow.LButton())
    slow.Map(rbutton, slow.RButton())
    slow.Map(lbuttonDown, slow.LButtonDown())

    slow.Map(lbuttonUp, slow.LButtonUp())
  }

  _moveMouse(directionX, directionY, thisHotkey) {
    key := KeymapManager.ExtractWaitKey(thisHotkey)
    MouseMove(directionX * this.single, directionY * this.single, 0, "R")
    release := KeyWait(key, this.delay1)
    if release {
      return
    }
    while !release {
      MouseMove(directionX * this.repeat, directionY * this.repeat, 0, "R")
      release := KeyWait(key, this.delay2)
    }
  }

  _scrollWheel(direction, thisHotkey) {
    key := KeymapManager.ExtractWaitKey(thisHotkey)
    switch (direction) {
      case 1: MouseClick("WheelUp", , , this.scrollOnceLineCount)
      case 2: MouseClick("WheelDown", , , this.scrollOnceLineCount)
      case 3: MouseClick("WheelLeft", , , this.scrollOnceLineCount)
      case 4: MouseClick("WheelRight", , , this.scrollOnceLineCount)
    }
    release := KeyWait(key, this.scrollDelay1)
    if release {
      return
    }
    while !release {
      switch (direction) {
        case 1: MouseClick("WheelUp", , , this.scrollOnceLineCount)
        case 2: MouseClick("WheelDown", , , this.scrollOnceLineCount)
        case 3: MouseClick("WheelLeft", , , this.scrollOnceLineCount)
        case 4: MouseClick("WheelRight", , , this.scrollOnceLineCount)
      }
      release := KeyWait(key, this.scrollDelay2)
    }
  }

  LButton() {
    handler(thisHotkey) {
      Send("{blind}{LButton}")
      this.lockHandler()
    }
    return handler
  }

  RButton() {
    handler(thisHotkey) {
      Send("{blind}{RButton}")
      this.lockHandler()
    }
    return handler
  }

  LButtonDown() {
    handler(thisHotkey) {
      Send("{blind}{LButton DownR}")
    }
    return handler
  }

  LButtonUp() {
    handler(thisHotkey) {
      Send("{blind}{LButton Up}")
      this.lockHandler()
    }
    return handler
  }

  ExitMouseKeyMap() {
    handler(thisHotkey) {
      this.lockHandler()
    }
    return handler
  }

}


class TaskSwitchKeymap extends Keymap {

  __New(up, down, left, right, delete, enter) {
    super.__New("TaskSwitchKeymap")
    this.RemapKey(up, "up")
    this.RemapKey(down, "down")
    this.RemapKey(left, "left")
    this.RemapKey(right, "right")
    this.RemapKey(delete, "delete")
    this.RemapKey(enter, "enter")
    this.AfterLocked := this.DeactivateTaskSwitch.Bind(this)
    GroupAdd("TASK_SWITCH_GROUP", "ahk_class MultitaskingViewFrame")
    GroupAdd("TASK_SWITCH_GROUP", "ahk_class XamlExplorerHostIslandWindow")
  }

  DeactivateTaskSwitch() {
    ; 先等 AltTab 窗口出现, 再等它消失, 然后解锁
    notTimedOut := WinWaitActive("ahk_group TASK_SWITCH_GROUP", , 1)
    if (notTimedOut) {
      WinWaitNotActive("ahk_group TASK_SWITCH_GROUP")
    }
    ; 在 AltTab 窗口出现时, 把锁定的模式切换到 3 模式, 这种情况无需解锁
    if KeymapManager.Locked == this {
      KeymapManager.UnLock()
    }
  }
}

NoOperation(thisHotkey) {
}