class KeymapManager {
  static GlobalKeymap := Keymap("GlobalKeymap")
  static Stack := Array(this.GlobalKeymap)
  static L := { toLock: false, locked: false, show: false, toggle: false }

  static NewKeymap(globalHotkey, name := "") {
    if globalHotkey == "customHotkeys" {
      return this.GlobalKeymap
    }

    ; 分配全局热键激活指定 keymap
    return this.AddSubKeymap(this.GlobalKeymap, globalHotkey, name)
  }

  static AddSubKeymap(parent, hk, name := "") {
    waitKey := this.ExtractWaitKey(hk)
    subKeymap := Keymap(name, waitKey, hk)
    handler(thisHotkey) {
      this.Activate(subKeymap)
      this._postHandler()
    }
    parent.Map(hk, handler)
    return subKeymap
  }

  static Activate(keymap) {
    parent := this.Stack[-1]
    ; 比如锁住 3 模式再按 3 键触发 3 模式应该没效果
    if keymap != parent {
      this.Stack.Push(keymap)
      keymap.Enable(parent)
    }
    startTick := A_TickCount
    KeyWait(keymap.WaitKey)
    if (A_PriorKey = keymap.WaitKey && (A_TickCount - startTick < 300)) {
      keymap.SinglePressAction()
    }
    if keymap != parent {
      this.Stack.Pop()
      keymap.Disable()
    }
  }

  static _postHandler() {
    ; 等松开全部按钮时才处理锁定逻辑
    if this.Stack.Length != 1 || !this.L.toLock {
      return
    }

    ; 未锁定
    if !this.L.locked {
      this.ShowToolTip("已锁定 " this.L.toLock.Name, this.L.show)
      this._lock()
      ; 锁定时注册个函数, 用于自动关闭锁定, TaskSwitch 模式会用到这个
      if this.L.locked.AfterLocked {
        SetTimer(this.L.locked.AfterLocked, -1)
      }
      return
    }

    ; 已经锁定了自己
    if this.L.toLock == this.L.locked {
      if !this.L.toggle {
        return
      }
      this.ShowToolTip("取消锁定", this.L.show)
      this.L.toLock := false
      this.Unlock()
      return
    }

    ; 锁定了别的模式, 那么切换成锁定自己
    if this.L.toLock != this.L.locked {
      this.ShowToolTip("从 " this.L.locked.Name "`n切换到 " this.L.toLock.Name, this.L.show)
      this.Unlock()
      this._lock()
      return
    }

  }

  static SetLockRequest(toLock, toggle, show) {
    this.L.toLock := toLock
    this.L.toggle := toggle
    this.L.show := show
  }

  static ClearLockRequest() {
    KeymapManager.L.toLock := false
  }

  static _lock() {
    if this.L.toLock {
      this.Stack[1] := this.L.toLock
      this.L.toLock.Enable(this.GlobalKeymap)
      this.L.locked := this.L.toLock
      this.L.toLock := false
    }
  }

  static Unlock() {
    ; 这里不好用 this, 因为 Unlock 函数会被取出来, 然后 this 指向会变
    if KeymapManager.L.locked {
      KeymapManager.L.locked.Disable()
      KeymapManager.Stack[1] := KeymapManager.GlobalKeymap
      KeymapManager.L.locked := false
    }
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
    Tip(msg)
  }
}


class Keymap {
  __New(name := "", waitKey := "", hotkey := "") {
    this.Name := name
    this.WaitKey := waitKey
    this.Hotkey := hotkey
    this.SinglePressAction := NoOperation
    this.M := Map()
    this.ToggleLock := this._lockOrUnlock.Bind(this)
    this.AfterLocked := false
    this.parent := false
    this.toRestore := Array()
  }

  class _Hotkey {
    __New(name, handler, options, winTitle, conditionType) {
      this.name := name
      this.handler := handler
      this.options := options
      this.winTitle := winTitle
      this.conditionType := conditionType
      this.enabled := false
    }

    Enable() {
      if this.enabled {
        MsgBox "bug"
      }
      this.hotifContext(this.winTitle, this.conditionType)
      Hotkey(this.name, this.handler, "On" this.options)
      this.enabled := true
      HotIf()
    }

    Disable() {
      if !this.enabled {
        MsgBox "bug"
      }
      this.hotifContext(this.winTitle, this.conditionType)
      Hotkey(this.name, "Off")
      this.enabled := false
      HotIf()
    }

    hotifContext(winTitle, conditionType) {
      if winTitle == "" {
        return
      }
      switch conditionType {
        case 0: return
        case 1: HotIfWinactive(winTitle)
        case 2: HotIfWinExist(winTitle)
        case 3: HotIfWinNotactive(winTitle)
        case 4: HotIfWinNotExist(winTitle)
        case 5: HotIf(winTitle)
      }
    }
  }

  Map(hotkeyName, handler, keymapToLock := false, winTitle := "", conditionType := 0, options := "") {
    wrapper := Keymap._wrapHandler(handler, keymapToLock)
    if hotkeyName == "singlePress" {
      this.SinglePressAction := wrapper
      return
    }
    ; If Action is a hotkey name, its original function is used;
    ; This is usually used to restore a hotkey's original function after having changed it
    if handler == "handled_in_hot_if" {
      wrapper := hotkeyName
    }

    if !this.M.Has(hotkeyName) {
      this.M[hotkeyName] := Array()
    }
    this.M[hotkeyName].Push(Keymap._Hotkey(hotkeyName, wrapper, options, winTitle, conditionType))
  }


  static _wrapHandler(handler, keymapToLock) {
    wrapper(thisHotkey) {
      handler(thisHotkey)
      ; 执行完热键动作后, 可能要锁定某个 keymap
      if !keymapToLock {
        return
      }
      KeymapManager.SetLockRequest(keymapToLock, false, false)

      ; 这种情况是, 锁住后直接执行热键, 没有按下任何引导键 ( 比如先锁住 Caps 然后直接按 E )
      if KeymapManager.Stack.Length == 1 {
        KeymapManager._postHandler()
      }
    }
    return wrapper
  }

  _lockOrUnlock(thiHotkey) {
    KeymapManager.SetLockRequest(this, true, true)
  }

  ; 启用 keymap
  Enable(parent := false) {
    if this.parent && parent {
      MsgBox "bug"
    }
    this.parent := parent

    ; 方案 1 直接禁用 parent 中所有热键 ( 这样就无法同时使用两个模式了 )
    ; if parent {
    ;   for name in parent.M {
    ;     if name == this.hotkey {
    ;       continue
    ;     }
    ;     parent.DisableHotkey(name)
    ;     item := { keymap: parent, hotkey: name }
    ;     this.toRestore.Push(item)
    ;   }
    ; }

    for name in this.M {
      ; 方案 2 只禁用同名热键
      km := parent
      while km {
        ; 遍历祖先, 如果首个 km 存在同名热键, 那么禁用掉
        if km.DisableHotkey(name) {
          item := { keymap: km, hotkey: name }
          this.toRestore.Push(item)
          break
        }
        km := km.parent
      }
      this.EnableHotkey(name)
    }
  }


  Disable() {
    for name in this.M {
      this.DisableHotkey(name)
    }
    while this.toRestore.Length > 0 {
      item := this.toRestore.Pop()
      item.keymap.EnableHotkey(item.hotkey)
    }
    this.parent := false
  }

  ; 启用 keymap 中所有名为 name 的热键
  EnableHotkey(name) {
    if !this.M.Has(name) {
      return
    }
    for hk in this.M[name] {
      hk.Enable()
    }
  }

  DisableHotkey(name) {
    hks := this.M.Get(name, false)
    if !hks {
      return
    }
    for hk in hks {
      hk.Disable()
    }
    return hks.Length > 0
  }

  RemapKey(a, b, winTitle := "", conditionType := 0) {
    downHandler(thisHotkey) {
      SetKeyDelay -1
      Send "{Blind}{" b " DownR}"
    }
    upHandler(thisHotkey) {
      SetKeyDelay -1
      Send "{Blind}{" b " Up}"
    }
    this.Map("*" a, downHandler, , winTitle, conditionType)
    this.Map("*" a " up", upHandler, , winTitle, conditionType)
  }

  SendKeys(hk, keys, winTitle := "", conditionType := 0) {
    handler(thisHotkey) {
      Send(keys)
    }
    this.Map(hk, handler, , winTitle, conditionType)
  }

  RemapInHotIf(a, b, winTitle := "", conditionType := 0) {
    h := "handled_in_hot_if"
    ; 如果 b 的名字不是键名, 那么不构成重映射
    if GetKeyName(b) == "" {
      this.Map(a, h, , winTitle, conditionType)
    } else {
      this.Map("*" a, h, , winTitle, conditionType)
      this.Map("*" a " up", h, , winTitle, conditionType)
    }
  }
}

class MouseKeymap extends Keymap {

  __New(name, single, repeat, delay1, delay2, scrollOnceLineCount, scrollDelay1, scrollDelay2, lockHandler) {
    super.__New(name)
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

  ; todo 快速模式移动鼠标后, 并且没有进行过任何其他操作, 此时才进入两级变速
  ; 换句话说, 快速模式除了上下左右之外, 全都得清空锁定状态
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

  MButton() {
    handler(thisHotkey) {
      Send("{blind}{MButton}")
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
    super.__New("Task Switch")
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
    if KeymapManager.L.locked == this {
      KeymapManager.Unlock()
    }
  }
}

NoOperation(thisHotkey) {
}

matchWinTitleCondition(winTitle, conditionType) {
  switch conditionType {
    case 1:
      return WinActive(winTitle)
    case 2:
      return WinExist(winTitle)
    case 3:
      return !WinActive(winTitle)
    case 4:
      return !WinExist(winTitle)
    case 5:
      return winTitle
  }
  return false
}