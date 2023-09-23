﻿class KeymapManager {
  static GlobalKeymap := Keymap("GlobalKeymap")
  static Stack := Array(this.GlobalKeymap)
  static L := { toLock: false, locked: false, show: false, toggle: false }

  static NewKeymap(globalHotkey, name, delay) {
    if globalHotkey == "customHotkeys" {
      return this.GlobalKeymap
    }

    ; 分配全局热键激活指定 keymap
    return this.AddSubKeymap(this.GlobalKeymap, globalHotkey, name, delay)
  }

  static AddSubKeymap(parent, hk, name := "", delay := 0) {
    mask := False
    if InStr(hk, " Mask"){
      hk := StrReplace(hk," Mask")
      mask := True
    }
    waitKey := ExtractWaitKey(hk)
    subKeymap := Keymap(name, waitKey, hk, delay, mask)
    handler(thisHotkey) {
      this.Activate(subKeymap)
      this._postHandler()
    }
    parent.Map(hk, handler)
    return subKeymap
  }

  static _handleDelay(keymap) {
    if keymap.delay {
      ; Tip(keymap.Name " " keymap.delay)
      ih := InputHook("T" keymap.delay)
      ih.KeyOpt("{All}", "E")
      ih.Start()
      Suspend
      while true {
        if !ih.InProgress && ih.EndReason == "Timeout" {
          Suspend
          break
        }
        if !GetKeyState(keymap.WaitKey, "P") || (!ih.InProgress && ih.EndReason != "Timeout") {
          ih.Stop()
          Send("{blind}{" keymap.WaitKey "}{" ih.EndKey "}")
          KeyWait(keymap.WaitKey)
          Suspend
          return true
        }
      }
    }
  }

  static Activate(keymap) {
    if this._handleDelay(keymap) {
      return
    }
    parent := this.Stack[-1]
    ; 比如锁住 3 模式再按 3 键触发 3 模式应该没效果
    if keymap != parent {
      this.Stack.Push(keymap)
      keymap.Enable(parent)
    }
    startTick := A_TickCount
    ; 掩饰(屏蔽) Win 或 Alt 键松开事件
    if keymap.mask {
      Send "{Blind}{vkE8}"
    }
    KeyWait(keymap.WaitKey)
    if (A_PriorKey = keymap.WaitKey && (A_TickCount - startTick < 450)) {
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
      this.L.toLock := false ; 别忘了清除状态
      if !this.L.toggle {
        return
      }
      this.ShowToolTip("取消锁定", this.L.show)
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
      this.L.toLock.Enable(this.GlobalKeymap)
      this.Stack[1] := this.L.toLock
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


  static ShowToolTip(msg, show := true) {
    if !show {
      return
    }
    Tip(msg)
  }
}


class Keymap {
  __New(name := "", waitKey := "", hotkey := "", delay := 0, mask := False) {
    this.Name := name
    this.WaitKey := waitKey
    this.Hotkey := hotkey
    this.SinglePressAction := NoOperation
    this.M := Map()
    this.M.CaseSense := "Off"
    this.ToggleLock := this._lockOrUnlock.Bind(this)
    this.AfterLocked := false
    this.parent := false
    this.toRestore := Array()
    this.delay := delay
    this.mask := mask
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
    ; 用 = 表示忽略大小写进行字符串比较
    if hotkeyName = "singlePress" {
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
    ; 这种情况是, 锁住后直接执行热键, 没有按下任何引导键 ( 比如先锁住 Caps 然后直接按 E )
    if KeymapManager.Stack.Length == 1 {
      KeymapManager._postHandler()
    }
  }

  ; 启用 keymap
  Enable(parent := false) {
    if this.parent && parent {
      MsgBox "bug"
    }
    this.parent := parent

    ; 方案 1
    ; if parent {
    ;   if parent == KeymapManager.Stack[1] {
    ;     ; 只禁用同名的
    ;     for name in this.M {
    ;       km := parent
    ;       while km {
    ;         ; 遍历祖先, 如果首个 km 存在同名热键, 那么禁用掉
    ;         if km.DisableHotkey(name) {
    ;           item := { keymap: km, hotkey: name }
    ;           this.toRestore.Push(item)
    ;           break
    ;         }
    ;         km := km.parent
    ;       }
    ;     }
    ;   } else {
    ;     ; 直接禁用 parent 中所有热键
    ;     for name in parent.M {
    ;       if name == this.hotkey {
    ;         continue
    ;       }
    ;       parent.DisableHotkey(name)
    ;       item := { keymap: parent, hotkey: name }
    ;       this.toRestore.Push(item)
    ;     }
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
        name2 := LTrim(name, "*")
        if km.DisableHotkey(name2) {
          item := { keymap: km, hotkey: name2 }
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

  __New(name, keepMouseMode, mouseTip, single, repeat, delay1, delay2, scrollOnceLineCount, scrollDelay1, scrollDelay2, slowKeymap := false) {
    super.__New(name)
    this.keepMouseMode := keepMouseMode
    this.single := single
    this.repeat := repeat
    this.delay1 := delay1
    this.delay2 := delay2
    this.scrollOnceLineCount := scrollOnceLineCount
    this.scrollDelay1 := scrollDelay1
    this.scrollDelay2 := scrollDelay2
    this.slowKeymap := slowKeymap
    this.mouseTip := mouseTip

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
    key := ExtractWaitKey(thisHotkey)
    MouseMove(directionX * this.single, directionY * this.single, 0, "R")
    (this.mouseTip && this.mouseTip.Show("", 20, 16))
    release := KeyWait(key, this.delay1)
    if release {
      return
    }
    while !release {
      MouseMove(directionX * this.repeat, directionY * this.repeat, 0, "R")
      (this.mouseTip && this.mouseTip.Show("", 20, 16))
      release := KeyWait(key, this.delay2)
    }
  }

  _scrollWheel(direction, thisHotkey) {
    if this.slowKeymap {
      this.clearOrUnlock(false)
    }
    key := ExtractWaitKey(thisHotkey)
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

  clearOrUnlock(keepMouseMode) {
    ; 没有 slowKeymap 说明 this 是 slow 模式, 要解锁
    if !this.slowKeymap {
      ; 用户想点击后不退出鼠标模式
      if keepMouseMode {
        return
      }
      KeymapManager.Unlock()
      (this.mouseTip && this.mouseTip.Hide())
      return
    }
    ; slowKeymap 不为空说明 this 是 fast 模式, 如果发现已经锁定了 slow 模式, 要解锁
    if KeymapManager.L.locked == this.slowKeymap {
      if keepMouseMode {
        return
      }
      KeymapManager.SetLockRequest(this.slowKeymap, true, false) ; 通过 toggle 锁定状态实现解锁
      (this.mouseTip && this.mouseTip.Hide())
    } else {
      ; 清空锁定请求
      KeymapManager.ClearLockRequest()
      (this.mouseTip && this.mouseTip.Hide())
    }
  }

  LButton() {
    handler(thisHotkey) {
      Send("{blind}{LButton}")
      this.clearOrUnlock(this.keepMouseMode)
    }
    return handler
  }

  RButton() {
    handler(thisHotkey) {
      SendMouseButton("RButton")
      this.clearOrUnlock(this.keepMouseMode)
    }
    return handler
  }

  MButton() {
    handler(thisHotkey) {
      SendMouseButton("MButton")
      this.clearOrUnlock(this.keepMouseMode)
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
      this.clearOrUnlock(false)
    }
    return handler
  }

  ExitMouseKeyMap() {
    handler(thisHotkey) {
      this.clearOrUnlock(false)
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

ExtractWaitKey(hotkey) {
  waitKey := Trim(hotkey, " #!^+<>*~$")
  if InStr(waitKey, "&") {
    sp := StrSplit(waitKey, "&")
    waitKey := Trim(sp[2])
  }
  return waitKey
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

SendMouseButton(btn) {
  ; MyKeymap 输入的 RButton 被鼠标手势拦截, 鼠标手势认为用户想单击右键, 所以也发送 RButton
  ; 然而这个 RButton 又会触发 MyKeymap 的右键功能, 造成死循环, 所以在发送 RButton 前把右键暂停一下
  try Hotkey("*" btn, "Off")
  try Hotkey(btn, "Off")
  Send("{blind}{" btn "}")
  Sleep 50
  try Hotkey("*" btn, "On")
  try Hotkey(btn, "On")
}