class KeymapManager {
  static M := Map()
  static Locked := false

  static NewKeymap(globalHotkey) {
    ; 创建 keymap, 并注册它的全局触发热键
    waitKey := this.ExtractWaitKey(globalHotkey)
    km := Keymap(globalHotkey, waitKey)
    Hotkey(globalHotkey, km.Handler, "On")

    ; keymap 激活时可能会改掉全局热键的功能
    ; 所以要记住全局热键的功能, 以便在 Activate 方法返回前恢复全局热键
    this.M[globalHotkey] := km
    return km
  }

  static Activate(keymap) {
    ; 临时关掉锁定, 避免两个模式同时启用
    ; 如果同时存在 *a 和 a 两个热键, 执行哪个是未定义的
    if KeymapManager.Locked {
      KeymapManager.Locked.Disable()
    }

    keymap.Enable()
    startTick := A_TickCount
    KeyWait(keymap.WaitKey)
    if (A_PriorKey = keymap.WaitKey && (A_TickCount - startTick < 300)) {
      keymap.SinglePressAction()
    }
    keymap.Disable()
    KeymapManager.RestoreGlobalHotkey()

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

  static AddSubKeymap(parent, theHotkey, subKeymap := false) {
    waitKey := this.ExtractWaitKey(theHotkey)
    if !subKeymap {
      subKeymap := Keymap(theHotkey, waitKey)
    }

    ; 进入子模式时执行如下代码
    handler(arg) {
      startTick := A_TickCount
      parent.Disable()
      KeymapManager.RestoreGlobalHotkey()
      subKeymap.Enable()
      KeyWait(subKeymap.WaitKey)
      if (A_PriorKey = subKeymap.WaitKey && (A_TickCount - startTick < 300)) {
        subKeymap.SinglePressAction()
      }
      if KeymapManager.Locked == subKeymap {
        return
      }
      subKeymap.Disable()
      parent.Enable()
    }

    ; 在 parent 中添加一个 theHotkey, 用来激活 sub keymap
    parent.Map(theHotkey, handler)
    return subKeymap
  }

  static EndInit() {
    ; 在按住 Caps 模式的情况下, 临时使用 3 模式输入数字, 当 3 模式退出时应该还原到 Caps 模式
    ; 具体做法是让 3 成为 Caps 的子模式 ( 如果 Caps 模式已经分配了 3 键, 则不做这个处理 )
    for hk, km in this.M {
      for hk2, km2 in this.M {
        if km == km2 || km.M.Has(hk2) {
          continue
        }
        this.AddSubKeymap(km, hk2, km2)
      }
    }
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
    KeymapManager.Locked := toLock
  }

  static UnLock() {
    if KeymapManager.Locked {
      KeymapManager.Locked.Disable()
      KeymapManager.RestoreGlobalHotkey()
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

  static RestoreGlobalHotkey() {
    ; 恢复全局热键
    for globalHotkey, km in this.M {
      Hotkey(globalHotkey, km.Handler, "On")
    }
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
    this.Handler := this._handler.Bind(this)
  }

  _handler(thisHotkey) {
    KeymapManager.Activate(this)
  }

  Map(hotkeyName, handler, keymapToLock := false, toggle := false) {
    wrapper(thisHotkey) {
      handler(thisHotkey)
      if !keymapToLock {
        return
      }
      KeymapManager.LockKeymap(keymapToLock, false, false)
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