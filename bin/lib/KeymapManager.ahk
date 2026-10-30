class KeymapManager {
  static GlobalKeymap := Keymap("GlobalKeymap")
  static Stack := Array(this.GlobalKeymap)
  static L := { toLock: false, locked: false, show: false, toggle: false }

  static NewKeymap(globalHotkey, name, delay, disableAt) {
    if globalHotkey == "customHotkeys" {
      return this.GlobalKeymap
    }

    ; 在全局 keymap 中添加一个 globalHotkey, 用来激活指定的 keymap, 例如 CapsLock 模式
    ; 让这些 globalHotkey 在特定程序中被禁用, 也就实现了 MyKeymap 在特定程序中被禁用
    winTitle := this.GlobalKeymap.DisabledAt
    if disableAt {
      winTitle := disableAt
    }
    conditionType := winTitle ? 3 : 0
    return this.AddSubKeymap(this.GlobalKeymap, globalHotkey, name, delay, winTitle, conditionType)
  }

  static AddSubKeymap(parent, hk, name := "", delay := 0, winTitle := "", conditionType := 0) {
    waitKey := ExtractWaitKey(hk)
    subKeymap := Keymap(name, waitKey, hk, delay)
    handler(thisHotkey) {
      this.Activate(subKeymap)
      this._postHandler()
    }
    parent.Map(hk, handler, , winTitle, conditionType)
    return subKeymap
  }

  static _handleDelay(keymap) {
    if keymap.delay {
      ; Tip(keymap.Name " " keymap.delay)
      ih := InputHook("T" keymap.delay)
      ih.KeyOpt("{All}", "E")
      ih.Start()
      ; Suspend
      while true {
        if !ih.InProgress && ih.EndReason == "Timeout" {
          ; Suspend
          break
        }
        if !GetKeyState(keymap.WaitKey, "P") || (!ih.InProgress && ih.EndReason != "Timeout") {
          ih.Stop()
          Send("{blind}{" keymap.WaitKey "}{" ih.EndKey "}")
          ; B-4: 原来是无参 KeyWait, 只要对应的 up 事件被吞掉(或由别的钩子先行消费),
          ; 这里就会永久阻塞, Activate 再也回不去, Stack.Pop/Disable 永远不执行。
          ; 改为带超时 + 物理键态兜底, 保证本函数必定返回。
          KeymapWaitRelease(keymap.WaitKey)
          ; Suspend
          return true
        }
      }
    }
  }

  static Activate(keymap) {
    ; B-6 防重入: 按住触发键时键盘自动重复会反复走到这里。
    ; 旧实现每次都会 Push + Enable 一份同名 keymap, 而 Enable/Disable 都是对
    ; 同一个物理热键做 Hotkey(name,"On"/"Off"), 于是"注销 -> 重新注册"之间留下
    ; 一个穿透窗口, 那正是"漏键": 落在这个窗口里的 down 没有任何钩子接住它。
    ;
    ; 第一轮只挡了"栈顶 == 自己", 漏掉了更常见的一种: 自己还在栈中但不是栈顶。
    ; 现场: CapsLock down -> Activate(A)；A 阻塞在 Wait 时按 Tab -> Activate(B) 压栈;
    ; 此时 CapsLock 自动重复再次 Activate(A) —— Stack[-1] 是 B 不是 A, 旧条件不成立,
    ; 于是 A 被第二次 Push + Enable, 又对同一物理热键做了一次 Off->On,
    ; 重新打开"漏键穿透窗口"(实测栈深 3->4)。
    ;
    ; 因此判定改为「keymap 已存在于 Stack 的任意位置 => 早退」, 并保留锁定模式例外:
    ;  - 在任意位置(栈顶或祖先) => 它这一层还活着, 本次必是自动重复, 丢弃;
    ;  - 排除 Stack[1] => 锁定模式(TaskSwitch 等)下 keymap 长期占 Stack[1],
    ;    此时按下触发键应该照常执行 Wait + singlePress, 不能早退。
    ; 早退不做任何状态变更, 因此不会漏掉谁能收尾: 持有者(那一层)负责 Pop/Disable。
    ; 栈深很小, 线性查找的代价可以忽略。
    ; 注意: 不能用 Stack.Has(keymap) —— AHK v2 的 Array.Has() 判的是**下标键**
    ; (实测: Has(2)=1 但 Has(对象)=0), 拿它做值查找会恒为 false,
    ; 断言会假装通过而实际没修。这里显式线性查找对象身份。
    if (keymap != this.Stack[1] && _stackContains(this.Stack, keymap)) {
      OutputDebug("[MyKeymap] reentrant Activate ignored: " keymap.Name)
      return
    }
    if this._handleDelay(keymap) {
      return
    }
    parent := this.Stack[-1]
    locked := this.Stack[1]
    ; 比如锁住 3 模式再按 3 键触发 3 模式应该没效果
    if keymap != locked {
      this.Stack.Push(keymap)
      keymap.Enable(parent)
    }
    startTick := A_TickCount
    ; B-4: Wait 里即使抛错或提前返回, 也必须走完 Pop/Disable, 保证 Activate 必定返回
    ; 且激活栈不残留(否则后续所有热键都会落在错误的前台 keymap 上)。
    try {
      keymap.Wait(startTick)
    } finally {
      if keymap != locked {
        this.Stack.Pop()
        keymap.Disable()
      }
    }
  }

  static _postHandler() {
    ; 等松开全部按钮时才处理锁定逻辑
    if this.Stack.Length != 1 || !this.L.toLock {
      return
    }

    ; 未锁定
    if !this.L.locked {
      this.ShowToolTip("Lock " this.L.toLock.Name, this.L.show)
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
      this.ShowToolTip("Lock: Off", this.L.show)
      this.Unlock()
      return
    }

    ; 锁定了别的模式, 那么切换成锁定自己
    if this.L.toLock != this.L.locked {
      this.ShowToolTip("从 " this.L.locked.Name "`n切换到 " this.L.toLock.Name, this.L.show)
      this.Unlock()
      this._lock()
      ; 锁定时注册个函数, 用于自动关闭锁定, TaskSwitch 模式会用到这个
      if this.L.locked.AfterLocked {
        SetTimer(this.L.locked.AfterLocked, -1)
      }
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

  class ActionList {
    actions := []
    static conditionMap := Map(
      0, _ => true,
      1, winTitle => WinActive(winTitle),
      2, winTitle => WinExist(winTitle),
      3, winTitle => !WinActive(winTitle),
      4, winTitle => !WinExist(winTitle),
    )

    Run() {
      m := KeymapManager.ActionList.conditionMap
      for a in this.actions {
        if !m.Has(a.conditionType) {
          continue
        }
        if a.conditionType == 0 && !IsSet(fn) {
          fn := a.fn
          continue
        }
        if m.Get(a.conditionType)(a.winTitle) {
          fn := a.fn
          break
        }
      }
      if IsSet(fn) {
        fn()
      }
    }

    Add(conditionType, winTitle, fn) {
      this.actions.Push({
        conditionType: conditionType,
        winTitle: winTitle,
        fn: fn,
      })
    }
  }
}


class Keymap {
  __New(name := "", waitKey := "", hotkey := "", delay := 0) {
    this.Name := name
    this.WaitKey := waitKey
    this.Hotkey := hotkey
    this.SinglePressAction := KeymapManager.ActionList()
    this.M := Map()
    this.M.CaseSense := "Off"
    this.ToggleLock := this._lockOrUnlock.Bind(this)
    this.AfterLocked := false
    this.parent := false
    this.toRestore := Array()
    this.delay := delay
  }

  class _Hotkey {
    __New(name, handler, options, winTitle, conditionType) {
      this.name := ExtractWaitKey(name) ; 把带修饰符的热键视为同名热键
      this.rawName := name
      this.handler := handler
      this.options := options
      this.winTitle := winTitle
      this.conditionType := conditionType
      this.enabled := false
    }

    Enable() {
      if this.enabled {
        ; B-5: 生产路径禁止模态 MsgBox. 弹窗会挂住当前热键线程(single thread),
        ; 触发键的 up 因此得不到处理, 表现为"前置触发键长时间滞留". 改为非阻塞日志.
        OutputDebug("[MyKeymap] unexpected state: _Hotkey.Enable 时 enabled 已为 true, hk=" this.rawName)
      }
      ; R3: 「设上下文 -> 注册 -> 复位上下文」必须是原子的。
      ; 复位走 finally: 只要 Hotkey() 抛错就一定会执行, 否则 #HotIf 会留在当前线程,
      ; 后续注册的热键被挂到错误条件上 => "某些键在某些窗口莫名失效"(用户描述成漏键)。
      ;
      ; 关于 enabled: AHK 的 Hotkey() 对非法键名抛的 ValueError 是"延迟抛"
      ; (实测: 抛错语句**之后**的语句仍然执行, 之后才把异常抛出)。
      ; 所以 `this.enabled := true` 会先跑掉, 单靠语句顺序分不清成败, 必须显式 catch
      ; 把状态回滚 —— 否则会留下"状态说自己在生效、实际没有任何热键"的鬼键,
      ; 之后 Disable 判定错乱。这里也不再把异常冒泡出去: 上层 Keymap.Enable() 负责
      ; 逐键隔离, 单个坏键不该让整个脚本起不来。
      this.hotifContext(this.winTitle, this.conditionType, true)
      try {
        Hotkey(this.rawName, this.handler, "On" this.options)
        this.enabled := true
      } catch as e {
        this.enabled := false
        OutputDebug("[MyKeymap] _Hotkey.Enable 注册失败, 跳过: hk=" this.rawName
          . " err=" Type(e) ": " e.Message)
      } finally {
        this.hotifContext(this.winTitle, this.conditionType, false)
      }
    }

    Disable() {
      if !this.enabled {
        ; B-5: 同上. 该分支在 Keymap.Disable() 遍历全部热键时很容易命中,
        ; 原来每次都会弹窗, 是"滞留"最频繁的来源.
        OutputDebug("[MyKeymap] unexpected state: _Hotkey.Disable 时 enabled 已为 false, hk=" this.rawName)
      }
      ; R3: 同上, 复位进 finally。并且允许"从未注册成功"的键走到这里:
      ; 那种键在 AHK 侧不存在, Hotkey(...,"Off") 会抛 TargetError(Nonexistent hotkey),
      ; 而 Keymap.Disable() 是在 Activate 的 finally 里被调用的 —— 这里抛错就会跳过
      ; 收尾(Pop/恢复上级热键), 栈从此残留。吞掉并记录即可: 目标状态(未注册)本就成立。
      this.hotifContext(this.winTitle, this.conditionType, true)
      try {
        Hotkey(this.rawName, "Off")
      } catch as e {
        OutputDebug("[MyKeymap] _Hotkey.Disable 跳过未注册键: hk=" this.rawName
          . " err=" Type(e) ": " e.Message)
      } finally {
        this.enabled := false
        this.hotifContext(this.winTitle, this.conditionType, false)
      }
    }

    hotifContext(winTitle, conditionType, begin) {
      if winTitle == "" || conditionType == 0 {
        HotIf()
      }
      switch conditionType {
        case 1: begin ? HotIfWinactive(winTitle) : HotIfWinactive()
        case 2: begin ? HotIfWinExist(winTitle) : HotIfWinExist()
        case 3: begin ? HotIfWinNotactive(winTitle) : HotIfWinNotactive()
        case 4: begin ? HotIfWinNotExist(winTitle) : HotIfWinNotExist()
        case 5: begin ? HotIf(winTitle) : HotIf()
      }
    }
  }

  Map(hotkeyName, handler, keymapToLock := false, winTitle := "", conditionType := 0, options := "") {
    wrapper := Keymap._wrapHandler(handler, keymapToLock)
    ; 用 = 表示忽略大小写进行字符串比较
    if hotkeyName = "singlePress" {
      this.SinglePressAction.Add(conditionType, winTitle, wrapper.Bind("singlePress"))
      return
    }
    ; If Action is a hotkey name, its original function is used;
    ; This is usually used to restore a hotkey's original function after having changed it
    if handler == "handled_in_hot_if" {
      wrapper := hotkeyName
    }

    hk := Keymap._Hotkey(hotkeyName, wrapper, options, winTitle, conditionType)
    if !this.M.Has(hk.name) {
      this.M[hk.name] := Array()
    }
    ; B-6: 同一个物理热键的重复注册会产生两个 _Hotkey 实例指向同一个热键变体,
    ; 于是 enabled 标志各记一份: 先 Disable 的那个把热键关了并置 false, 后一个
    ; 再 Disable 时必然落进 "enabled 已为 false" 分支, 状态从此错乱。
    ; 注册阶段就去重: 后注册的覆盖先注册的(最后一个定义生效), 保持数组其它项不变。
    ;
    ; 去重键不能只用 rawName(第一轮就是这么写的, 那是错的):
    ;   AHK 原生允许同一物理键在**不同 #HotIf 条件**下共存, 按 rawName 去重会把
    ;   Map("*F13", h1, , "WinA", 1) 和 Map("*F13", h2, , "WinB", 1) 合并成一条,
    ;   后者覆盖前者 => 用户在 WinA 下的绑定凭空消失(实测 Length=1, 只剩 WinB)。
    ; 正确语义是「同一物理热键 + 同一生效条件」才算重复, 因此三项一起做键。
    ; 比较仍按 M.CaseSense = "Off" 的大小写不敏感语义(沿用本文件既有约定)。
    dedupKey := hk.rawName . "/" . hk.winTitle . "/" . hk.conditionType
    arr := this.M[hk.name]
    for i, existing in arr {
      existingKey := existing.rawName . "/" . existing.winTitle . "/" . existing.conditionType
      if existingKey = dedupKey {
        if existing.enabled {
          existing.Disable()
        }
        arr[i] := hk
        return
      }
    }
    arr.Push(hk)
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

  Wait(startTick) {
    ; 先处理一般情况, 不用鼠标按钮作为触发键
    if !InStr(this.Hotkey, "button") {
      ; B-4: 原来是无参 KeyWait, 一旦对应的 up 被吞掉(或已被别的钩子消费)就永久阻塞,
      ; Activate 再也回不去, Activate 的 finally 收尾也就永远轮不到。
      KeymapWaitRelease(this.WaitKey)
      if (A_PriorKey = this.WaitKey && (A_TickCount - startTick < 450)) {
        this.SinglePressAction.Run()
      }
      return
    }
    ; 使用鼠标按钮作为触发键, 尝试兼容其他鼠标手势软件
    mouseMoved := false
    thisHotkey := A_ThisHotkey
    CoordMode("Mouse", "Screen")

    MouseGetPos(&x1, &y1)
    while !KeyWait(this.WaitKey, "T0.01") {
      ; B-4: 这个等待循环原本没有总时长上限, up 永久丢失时会一直占住热键线程。
      ; ★ 上限从 600000ms(10 分钟) 收紧到 20000ms(20s)。
      ;   10 分钟对用户等同"永久卡住": 这段时间里热键线程被占, 后续按键无人处理,
      ;   用户感受就是"点了没反应, 只能 Win+L"。20s 与 KeymapWaitRelease 的
      ;   默认上限一致, 既能覆盖真实长按(正常按鼠标触发键不会超过几秒),
      ;   又保证异常时一定在可接受时间内收尾。
      if (A_TickCount - startTick > 20000) {
        OutputDebug("[MyKeymap] 鼠标触发键等待累计超时, 强制收尾: key=" this.WaitKey
          . " 时长=20000ms(原上限 600000ms)")
        break
      }
      MouseGetPos(&x2, &y2)
      if Abs(x2 - x1) > 10 || Abs(y2 - y1) > 10 {
        mouseMoved := true
        break
      }
      if thisHotkey != A_ThisHotkey {
        ; B-4: 同上, 加超时兜底
        KeymapWaitRelease(this.WaitKey)
        break
      }
    }

    if (thisHotkey = A_ThisHotkey && (A_TickCount - startTick < 450)) {
      if !mouseMoved {
        this.SinglePressAction.Run()
      } else {
        Send("{blind}{" this.WaitKey " Down}")
        ; B-4: 上面已经送出 Down, 一旦 up 丢失这里就是永久的"按键卡在按下状态",
        ; 所以必须有上限并在超时后照样补 Up。
        KeymapWaitRelease(this.WaitKey)
        Send("{blind}{" this.WaitKey " Up}")
      }
    }
  }
  ; 启用 keymap
  Enable(parent := false) {
    if this.parent && parent {
      ; B-5: 生产路径禁止模态 MsgBox(会挂住热键线程), 改为非阻塞日志。
      OutputDebug("[MyKeymap] unexpected state: Enable 时 parent 已存在, name=" this.Name)
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
        km := km.parent
      }
      ; R3: per-key 隔离。原来这里没有 try, 一个坏键名(用户配置里写了不存在的键)
      ; 抛 ValueError 就会中断整轮注册并冒泡到 InitKeymap(), 而生成物里
      ; InitKeymap() 在 OnExit 注册之前执行 => 脚本直接启动失败,
      ; 表现为 MyKeymap 完全不可用(而不是"少了一个键")。
      ; 现在: 记录日志, 继续下一个键。
      try {
        this.EnableHotkey(name)
      } catch as e {
        OutputDebug("[MyKeymap] EnableHotkey 失败, 跳过该键: name=" name " keymap=" this.Name
          . " err=" Type(e) ": " e.Message)
      }
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
    if b ~= "i)control|ctrl|shift|alt|win" {
      downHandler(thisHotkey) {
        HoldDownModifierKey(b)
      }
      this.Map("*" a, downHandler, , winTitle, conditionType)
      return
    }

    ; Remap 容易让按键卡在按下状态, 改成 Send 好一点
    hk := "*" a
    keys := b
    if keys ~= "^\w+$" {
      keys := "{blind}{" b "}"
    }
    this.SendKeys(hk, keys, winTitle, conditionType)

    ; downHandler(thisHotkey) {
    ;   SetKeyDelay -1
    ;   Send "{Blind}{" b " DownR}"
    ; }
    ; upHandler(thisHotkey) {
    ;   SetKeyDelay -1
    ;   Send "{Blind}{" b " Up}"
    ; }
    ; this.Map("*" a, downHandler, , winTitle, conditionType)
    ; this.Map("*" a " up", upHandler, , winTitle, conditionType)
  }

  SendKeys(hk, keys, winTitle := "", conditionType := 0) {
    handler(thisHotkey) {
      Send(keys)
    }
    this.Map(hk, handler, , winTitle, conditionType)
  }

  RemapInHotIf(a, b, winTitle := "", conditionType := 0) {
    h := "handled_in_hot_if"
    ; 跳过这两个特殊玩意, 因为无法引用他们的 handler
    if b = "AltTab" || b = "ShiftAltTab" {
      return
    }
    ; 如果 b 的名字不是键名, 那么不构成重映射
    if GetKeyName(ExtractWaitKey(b)) == "" {
      this.Map(a, h, , winTitle, conditionType)
    } else {
      this.Map("*" a, h, , winTitle, conditionType)
      this.Map("*" a " up", h, , winTitle, conditionType)
    }
  }

  /**
   * 把按键映射为 MIDI 音符: 按下发声 (NoteOn), 松开停声 (NoteOff).
   * 由模板生成的调用形如: km.MapMidi("*q", 60, 1, 100, , "ahk_exe code.exe", 1)
   * @param hotkeyName 热键名 (如 "*q")
   * @param note 音符号 0-127
   * @param channel MIDI 通道 1-16
   * @param velocity 力度 1-127
   * @param keymapToLock 动作触发后要锁定的 keymap; 该参数刻意与 Map 对齐,
   *        以便 Go 侧 ", , winTitle, conditionType" 的空占位自然落在此处
   * @param winTitle 生效的窗口标题/条件
   * @param conditionType 窗口条件类型
   */
  MapMidi(hotkeyName, note, channel := 1, velocity := 100, keymapToLock := false, winTitle := "", conditionType := 0) {
    ; singlePress 没有物理松开语义, 注册会导致 MIDI 卡音, 直接跳过
    if InStr(hotkeyName, "singlePress") {
      return
    }
    ; 每个 MapMidi 独占一份本地状态, 同由 down/up 两个嵌套函数捕获共享:
    ;  - down: 仅在 armed 为 false (首次按下) 时送出 NoteOn, 并置 armed := true;
    ;          按住物理键时 AHK 会随后续自动重复(键盘 AutoRepeat)反复调用 down 热键,
    ;          此时 armed 已是 true, 直接 return, 不再重复 NoteOn, 消除「连打」听感.
    ;  - up:   送出 NoteOff 并把 armed 复位, 使下次按下能重新发声.
    ; 状态按 MapMidi 调用各持一份, 天然以 (note, channel) 为粒度, 多音/多通道互不影响.
    ; 注: MidiNoteOn / MidiNoteOff 内部另有 (note, channel) 状态寄存器做第二层保护,
    ;     即使某个热键被重复注册导致多个闭包同时运行, 也不会叠加触发.
    armed := false
    downHandler(thisHotkey) {
      if armed {
        return
      }
      armed := true
      MidiNoteOn(note, channel, velocity)
    }
    upHandler(thisHotkey) {
      armed := false
      MidiNoteOff(note, channel)
    }
    ; 成对注册 down / up, 对标 RemapInHotIf;
    ; keymapToLock 只作用于按下, 松开时不重复锁定
    this.Map(hotkeyName, downHandler, keymapToLock, winTitle, conditionType)
    this.Map(hotkeyName . " up", upHandler, false, winTitle, conditionType)
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

    ; 鼠标模式中按任意键退出, 经常会忘记按 N/Space 键退出
    keys := "abcdefghijklmnopqrstuvwxyz"
    h := this.ExitAndSendThisKey()
    for _, k in StrSplit(keys) {
      this.Map("*" k, h)
    }
  }

  /**
   * 按住方向键连续移动鼠标。
   *
   * 节奏参数来自用户配置(见 config-server/templates/mykeymap.tmpl:39-40):
   *   delay1 -> 首次重复前的等待(原实现: KeyWait(key, this.delay1), 超时未松开才开始重复)
   *   delay2 -> 每一次重复之间的间隔(原实现: 每轮 KeyWait(key, this.delay2) 定节奏)
   * 两者的原始形态都是 "T0.13"/"T0.01" 这种带 T 前缀的秒字符串, 由 MouseDelayMs 解析成毫秒。
   *
   * 退出条件统一交给 _holdRepeat(见其注释): 吞键走 up 事件, 未吞键走物理键态,
   * 外加硬上限。这样"移动"与"滚动"是同一套语义, 不存在上下/左右不对称。
   */
  _moveMouse(directionX, directionY, thisHotkey) {
    key := ExtractWaitKey(thisHotkey)
    MouseMove(directionX * this.single, directionY * this.single, 0, "R")
    (this.mouseTip && this.mouseTip.Show())
    this._holdRepeat(key, MouseDelayMs(this.delay1), MouseDelayMs(this.delay2)
      , () => this._moveOnce(directionX, directionY), "move")
  }

  _moveOnce(directionX, directionY) {
    MouseMove(directionX * this.repeat, directionY * this.repeat, 0, "R")
    (this.mouseTip && this.mouseTip.Show())
  }

  /**
   * 按住方向键连续滚动滚轮。节奏参数同 _moveMouse, 取 scrollDelay1 / scrollDelay2
   * (配置项 "T0.2" / "T0.03")。
   *
   * 上下左右四个方向全部走同一个 _holdRepeat, 因此不存在"向下会无限滚、向上不会"
   * 这类不对称 —— 差别只可能来自触发键本身被吞与否(由 _holdRepeat 内部统一处理)。
   */
  _scrollWheel(direction, thisHotkey) {
    if this.slowKeymap {
      this.clearOrUnlock(false)
    }
    key := ExtractWaitKey(thisHotkey)
    this._wheelOnce(direction)
    if InStr(key, "Wheel") {
      return ; 滚轮按钮没有 up 事件所以不能 KeyWait
    }
    this._holdRepeat(key, MouseDelayMs(this.scrollDelay1), MouseDelayMs(this.scrollDelay2)
      , () => this._wheelOnce(direction), "scroll")
  }

  _wheelOnce(direction) {
    switch (direction) {
      case 1: MouseClick("WheelUp", , , this.scrollOnceLineCount)
      case 2: MouseClick("WheelDown", , , this.scrollOnceLineCount)
      case 3: MouseClick("WheelLeft", , , this.scrollOnceLineCount)
      case 4: MouseClick("WheelRight", , , this.scrollOnceLineCount)
    }
  }

  /**
   * 鼠标"按住 = 连续动作"的统一闸门。**这是本文件里唯一的鼠标长按退出实现**,
   * _moveMouse 与 _scrollWheel 都经它, 保证上下/左右/移动/滚动语义完全一致。
   *
   * ── 为什么不能只靠物理键态(实测定论) ────────────────────────────────────
   * 当 key 正被本进程的热键吞掉时(生产: Tab 模式下的 `*w`、`*2` 等), 系统键态表
   * **不可信**: 实测 (*w 吞键 + keybd_event 注入 w) 出现两类结果 ——
   *   (a) GetAsyncKeyState(w) 恒 0, 于是"看起来已松开";
   *   (b) 注入 down 后 0x8000 位被置 1, 而随后注入的 up 被钩子抑制、系统表不复位,
   *       于是 GetAsyncKeyState(w) **永久停在 1**。
   * 旧实现(`while KeymapKeyPhysicallyDown(key)`)在 (a) 下"只滚一格就停"、在 (b) 下
   * **松手后继续滚到 60s 硬上限**(实测 _probe_d5 case2: 松手后整整 60203ms 才返回)。
   * 这正是用户报的"tab+w 松手后一直向下滚"。
   *
   * ── 所以: 吞键时只认该键自己的 up 热键事件 ──────────────────────────────
   * 实测 up 事件 100% 成对到达(见 KeymapWaitUpEvent 注释里的数据)。这里在会话期间
   * 装一个临时 `*key up` 热键把 released 置位, 循环体用 Sleep 让出线程, up 回调
   * 才有机会插进来(紧循环会让它永远排不上队)。会话结束后 try/finally 卸载。
   *
   * ── 硬上限 ──────────────────────────────────────────────────────────────
   * 无论信号如何, 连续动作最长 MouseRepeatHardCapMs() 毫秒(默认 6s)。这是
   * "松手后不停"的最终防线: 上游判据全失效时也一定在 6s 内收尾, 而不是 60s 或永不。
   *
   * ── 让出线程 ────────────────────────────────────────────────────────────
   * 循环体每轮都有 Sleep(intervalMs), 首段等待也用 Sleep 10 步进, 所以 up 热键线程
   * 与定时器线程都能进来。旧实现的 KeyWait 路径在吞键时被抑制逻辑坑掉(立刻返回 1),
   * 不可用。
   *
   * @param key 触发键名(已由 ExtractWaitKey 去掉修饰符)
   * @param delay1Ms 首段等待: 在此期间松手 = 短按, 只动作一次
   * @param intervalMs 连续动作的间隔
   * @param stepFn 单次动作(无参闭包)
   * @param tag 日志用标签("move"/"scroll")
   */
  _holdRepeat(key, delay1Ms, intervalMs, stepFn, tag) {
    ; 是否被本进程吞键 —— 决定"松开"信号从哪来。只读本进程注册表, 不查键态。
    swallowed := KeymapIsKeySwallowed(key)
    watcher := false
    if swallowed {
      watcher := MouseHoldWatcher()
      try {
        Hotkey("*" key " up", watcher.OnUp.Bind(watcher), "On")
      } catch {
        ; 装不上(非法键名等): 退化为键态判据 + 硬上限
        watcher := false
      }
    }
    try {
      ; ── 首段: 短按判定 ──
      if this._holdShouldStop(key, watcher)
        return
      firstDeadline := A_TickCount + (delay1Ms > 0 ? delay1Ms : 0)
      while (A_TickCount < firstDeadline) {
        Sleep 10                    ; 必须让出: up 回调要在这一步插进来
        if this._holdShouldStop(key, watcher)
          return
      }
      ; ── 连续动作 ──
      startTick := A_TickCount
      maxMs := MouseRepeatHardCapMs()
      while true {
        if this._holdShouldStop(key, watcher)
          break
        if (A_TickCount - startTick >= maxMs) {
          OutputDebug("[MyKeymap] 鼠标连续动作到达硬上限, 强制收尾: tag=" tag
            . " key=" key " 时长=" maxMs "ms")
          break
        }
        stepFn()
        Sleep (intervalMs > 0 ? intervalMs : 1)   ; 同样必须让出
      }
    } finally {
      ; 无论正常结束 / 硬上限 / 异常, 都把临时 up 热键卸掉, 否则会顶掉上层映射
      if watcher {
        try Hotkey("*" key " up", "Off")
      }
    }
  }

  /**
   * 是否应当停止连续动作。
   *  - 吞键时: 键态不可信, **只认** up 事件(released);
   *  - 未吞键时: 物理键态可信, 用 KeymapKeyPhysicallyDown。
   */
  _holdShouldStop(key, watcher) {
    if watcher
      return watcher.released
    return !KeymapKeyPhysicallyDown(key)
  }

  clearOrUnlock(keepMouseMode) {
    ; 没有 slowKeymap 说明 this 是 slow 模式, 要解锁
    if !this.slowKeymap {
      ; 用户想点击后不退出鼠标模式
      if keepMouseMode {
        return
      }
      ; 进行解锁的前提是没有按下其他模式, 否则会两次禁用同一热键
      if KeymapManager.Stack.Length > 1 {
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

  ExitAndSendThisKey() {
    handler(thisHotkey) {
      this.clearOrUnlock(false)
      Send("{blind}{" ExtractWaitKey(thisHotkey) "}")
    }
    return handler
  }
}


class TaskSwitchKeymap extends Keymap {

  __New(up, down, left, right, delete, enter) {
    super.__New("Task Switch")
    this.SendKeys("x", "{delete}") ; 为了不影响之前习惯了 x 键关闭的用户
    this.SendKeys(up, "{up}")
    this.SendKeys(down, "{down}")
    this.SendKeys(left, "{left}")
    this.SendKeys(right, "{right}")
    this.SendKeys(delete, "{delete}")
    this.SendKeys(enter, "{enter}")
    this.AfterLocked := this.DeactivateTaskSwitch.Bind(this)
    GroupAdd("TASK_SWITCH_GROUP", "ahk_class MultitaskingViewFrame")
    GroupAdd("TASK_SWITCH_GROUP", "ahk_class XamlExplorerHostIslandWindow")
  }

  DeactivateTaskSwitch() {
    ; 先等 AltTab 窗口出现, 再等它消失, 然后解锁
    notTimedOut := WinWaitActive("ahk_group TASK_SWITCH_GROUP", , 0.5)
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

/**
 * 数组里是否**按对象身份**包含 target(按值/按引用比较, 不做内容比较)。
 * 不用 Array.Has(): AHK v2 里 Array.Has(n) 判的是下标键存在性
 * (实测: 长度 3 的数组 Has(2)=1、Has(元素)=0), 语义不符。
 * 栈深很小, 线性扫描足够。
 */
_stackContains(arr, target) {
  for item in arr {
    if (item == target) {
      return true
    }
  }
  return false
}

/**
 * 把配置里的鼠标节奏参数解析成毫秒。
 *
 * 参数原始形态由 config-server/templates/mykeymap.tmpl:39-40 决定:
 *   MouseKeymap(..., "T{{ .Options.Mouse.Delay1 }}", "T{{ .Options.Mouse.Delay2 }}", ...)
 * 即 **带 "T" 前缀的秒字符串**, 例如 "T0.13" / "T0.01" / "T0.2" / "T0.03"。
 * 前缀 T 是 AutoHotkey KeyWait 的"超时(秒)"记号, 不是数值的一部分, 解析时必须剥掉。
 *
 * 容错: 用户可能手工写成 "0.13" 或纯数字; 也允许已经是毫秒的非字符串入参。
 * 非法/空值回退到 15 毫秒 —— 与旧版固定节拍等价, 保证不会退化成 0 忙等。
 *
 * @param {string|number} raw 配置值, 如 "T0.13"
 * @returns {integer} 毫秒数, 至少 1
 */
MouseDelayMs(raw) {
  if !IsSet(raw) || raw = "" {
    return 15
  }
  s := Trim(String(raw))
  if (SubStr(s, 1, 1) = "T" || SubStr(s, 1, 1) = "t") {
    s := SubStr(s, 2)
  }
  s := Trim(s)
  if s = "" {
    return 15
  }
  sec := 0
  try sec := Number(s)
  catch {
    return 15
  }
  if !IsNumber(sec) || sec < 0 {
    return 15
  }
  ms := Round(sec * 1000)
  return ms < 1 ? 1 : ms
}

/**
 * 等待按键释放, 最多 timeoutMs 毫秒。
 * @returns {boolean} true = 在超时内观察到松开; false = 超时(仍按下)
 *
 * 用 KeyWait 的 "T" 形式(让出线程, 不忙等)。超时后再用物理键态复核一次,
 * 因为 KeyWait 的超时判定可能早于钩子送达 up 事件。
 */
MouseWaitRelease(key, timeoutMs) {
  timeoutMs := (IsSet(timeoutMs) && timeoutMs > 0) ? timeoutMs : 15
  if KeyWait(key, "T" (timeoutMs / 1000)) {
    return true
  }
  return !KeymapKeyPhysicallyDown(key)
}

/**
 * 按键是否"物理按下"(GetAsyncKeyState)。
 * 用于 MouseKeymap._scrollWheel / _moveMouse 收尾: up 事件丢失时 AHK 内部键态可能卡住, 物理键态更可靠。
 * 鼠标键无 VK 码, 需显式映射到 Win32 VK_XBUTTON1/2 等, 避免在定时器线程里 GetKeyState(,"P") 失效。
 * 增加大小写不敏感查找, 兼容 A_ThisHotkey 可能返回的不同大小写。
 *
 * ⚠ 重要局限(实测, 见 tools/e2e/probe_mask_external.py / probe_timer_keywait.py):
 *   当该键被**本进程的热键吞掉**(例如生产里的 `*CapsLock`)时, AHK 的键盘钩子会抑制
 *   这个事件, 系统键态表从头到尾都不会被置位 —— 外部进程与本进程内
 *   GetAsyncKeyState(VK_CAPSLOCK) 都是 0(实测: 吞键 0/60 采样为真, 非吞键 39/62)。
 *   所以本函数对它返回 false 的含义是"看不到按下的痕迹", 而**不是**"用户已松开"。
 *   判断"是否已松开"不能用本函数, 必须等该键自己的 up 热键事件
 *   (见 KeymapWaitUpEvent)。
 */
KeymapKeyPhysicallyDown(key) {
  static vkMap := Map(
    "LButton", 0x01, "RButton", 0x02, "MButton", 0x04,
    "XButton1", 0x05, "XButton2", 0x06,
    "lbutton", 0x01, "rbutton", 0x02, "mbutton", 0x04,
    "xbutton1", 0x05, "xbutton2", 0x06
  )
  vk := vkMap.Get(key, "")
  if !vk
    vk := GetKeyVK(key)
  if vk
    return (DllCall("GetAsyncKeyState", "int", vk, "short") & 0x8000) ? true : false
  return GetKeyState(key, "P")
}

/**
 * 等待按键释放(B-4)。替代裸 KeyWait。
 *
 * 为什么不直接用 KeyWait(key): 只要对应的 up 事件被别的钩子消费/丢弃,
 * 裸 KeyWait 就永久阻塞, 热键线程被占住, Activate 无法返回, 收尾的
 * Stack.Pop()/Disable() 永远轮不到 —— 外部表现就是"前置触发键长时间滞留"。
 *
 * 这里不改用 while(GetKeyState(...,"P")) 紧循环(会占满线程, 且鼠标键需要钩子才准),
 * 而是分段 KeyWait + 物理键态复核:
 *  - 每段超时后先用 GetAsyncKeyState 复核: 已松开 => 视为收到 up, 正常返回;
 *  - 仍按下 => 说明是真长按, 继续等下一段(不误伤正常长按);
 *  - 到达截止时刻仍在按下 => 判定 up 永久丢失, 返回 false 让调用方强制收尾。
 * 这样 Activate 在任何情况下都能返回, 同时不牺牲长按体验。
 *
 * 两处数量级修正(R2, 都是第一轮引入的):
 *  1) 首段必须短。旧实现每段都等 perRoundSec(默认 30s), 于是"up 丢了但物理键其实
 *     早松了"这个最常见场景要白等 30s 才做第一次物理键态复核 —— 对用户就是卡住 30 秒。
 *     现在首段固定用 min(perRoundSec, 0.2), 200ms 内就能返回;
 *     之后仍退回 perRoundSec 的长段, 不牺牲真长按的响应经济性。
 *  2) 上限是**截止时刻**语义。旧实现把 maxTotalSec 放在"每段超时之后"比较,
 *     实际最坏耗时 ≈ perRoundSec + maxTotalSec(实测 perRound=1s/上限=0.3s 用了 1000ms)。
 *     现在先算 deadline, 循环条件直接看 A_TickCount < deadline。
 *
 * 默认上限从 600s 收到 20s: 这个函数占着热键线程, 而热键线程同时负责处理触发键的 up。
 * 600s 意味着"前置键滞留"最长能挂十分钟(用户抱怨的正是这个);20s 足够覆盖真实的长按
 * (按住 CapsLock 二十秒不松手已是极端), 又保证最坏情况下 20s 内必定收尾。
 *
 * @param key 等待释放的键名(通常是已由 ExtractWaitKey 去修饰符的 WaitKey)
 * @param perRoundSec 首段之后的单段等待秒数
 * @param maxTotalSec 累计上限秒数(截止时刻语义)
 * @returns {boolean} 是否观察到(或判定为)已释放
 */
KeymapWaitRelease(key, perRoundSec := 30, maxTotalSec := 20) {
  deadline := A_TickCount + maxTotalSec * 1000

  ; ── 路径选择: 该键是否正被本进程的热键吞掉? ──
  ; 这是唯一能区分两种"看起来一样"的情况的本地信息(不是键态查询):
  ;   A) 该键在本进程注册了 down 热键(生产里的 `*CapsLock` 就是)
  ;      => 钩子抑制它, 三条键态查询 + KeyWait 全部误报"已松开";
  ;         只有它自己的 up 热键事件可信, 必须走 KeymapWaitUpEvent。
  ;   B) 没注册 => 键态查询可信, 走 KeyWait 快路径(且"已松开"能立刻返回)。
  ; 不做这个区分就会出现两个坏结果之一:
  ;   - 一律信键态查询: 吞键时 200ms 就返回 -> 提前 Disable -> 长按只生效一个键(原故障);
  ;   - 一律等 up 事件:  键在调用前就已松开时 up 不会再来 -> 白等到 20s 截止。
  if KeymapIsKeySwallowed(key) {
    upResult := KeymapWaitUpEvent(key, deadline)
    if IsSet(upResult) && upResult != "" {
      return upResult
    }
    ; 装不上 up 热键(非法名等)时继续走下面的退化路径
  }

  ; 退化路径: 该键没有被本进程吞键(或装不上 up 热键)。
  ; 此时 KeyWait 与键态查询都是可信的。
  firstRound := perRoundSec < 0.2 ? perRoundSec : 0.2
  round := firstRound
  loop {
    remainMs := deadline - A_TickCount
    if (remainMs <= 0) {
      OutputDebug("[MyKeymap] KeyWait 到达截止时刻, 强制收尾: key=" key)
      return false
    }
    roundMs := round * 1000
    if (roundMs > remainMs) {
      roundMs := remainMs
    }
    if KeyWait(key, "T" (roundMs / 1000)) {
      return true
    }
    ; 本段超时: 键态查询在此可信(该键未被本进程接管), 可以用来判定 up 丢失。
    if !KeymapKeyPhysicallyDown(key) {
      return true
    }
    if (A_TickCount >= deadline) {
      OutputDebug("[MyKeymap] KeyWait 到达截止时刻, 强制收尾: key=" key)
      return false
    }
    round := perRoundSec
  }
}

/**
 * 等待 key 的 up 事件, 直到 deadline。返回 true = 等到了 up, false = 到点仍未松开。
 *
 * 为什么不能继续用 KeyWait 或键态查询(实测数据):
 *   - 该键被本进程热键接管时, KeyWait(key,"T0.2") 在**任何**线程里都立刻返回 1
 *     (probe_timer_keywait.py: swallow/passthru 27 次采样全是 kw=1 dt=0);
 *   - GetAsyncKeyState / GetKeyState(P) / GetKeyState 同一时刻全为 0
 *     (probe_mask_external.py: 吞键 0/60 为真, 未吞键 39/62 为真);
 *   - 但同一个键的 up 热键事件 100% 可靠成对到达
 *     (probe_up_event.py: 3/3 次都是 d_n/u_n 成对)。
 * 所以"是否已经松开"只能由 up 事件回答。
 *
 * 实现: 装一个临时 up 热键, 用短 Sleep 轮询标志位。Sleep 会正常让出热键线程,
 * 因此 up 回调可以正常插进来(这与 KeyWait 不同 —— 后者被上面的抑制逻辑坑了)。
 * 必须保底恢复: 无论成功/超时/异常, 都把自己的 up 热键关掉并恢复入参前的状态,
 * 否则会把上层 keymap 原有的 `*X up` 映射顶掉(那是 RemapInHotIf/MapMidi 会用的)。
 */
KeymapWaitUpEvent(key, deadline) {
  ; 用一个局部对象承载标志位, 并把它绑成热键回调。
  ; 实测过的失败写法(别重走):
  ;   1) 函数内 `global x` + 首段赋值            -> UnsetError
  ;   2) 嵌套函数里改外层局部变量(闭包捕获)      -> UnsetError
  ;   3) 本文件顶层加 `global x := ...` 初始化   -> 与顶层 class 混排导致脚本起不来
  ; 用 Object + Bind(方法) 两者都避开: 回调不捕获任何外层变量, 只操作自己的属性。
  watcher := KeymapUpWatcher()
  upName := "*" key " up"
  ; 装不上(非法键名)才返回 ""(未决), 让调用方走退化路径。
  ; 不能先用 Hotkey(upName) 去"查询" —— AHK v2 里单参 Hotkey(name)
  ; 的语义是**注销该热键**, 用它探路会把上层的 `*X up` 映射顺手删掉。
  try {
    Hotkey(upName, watcher.OnUp.Bind(watcher), "On")
  } catch {
    return ""
  }
  try {
    while (A_TickCount < deadline) {
      if watcher.released {
        return true
      }
      ; Sleep 会让出热键线程, up 回调才能插进来(KeyWait 那条路被抑制逻辑坑了)。
      Sleep 10
    }
    return false
  } finally {
    try Hotkey(upName, "Off")
  }
}

/**
 * KeymapWaitUpEvent 的回调载体: 只持有一个 released 标志。
 * 单独成类是为了让热键回调不依赖任何外层作用域(AHK v2 闭包/全局有坑, 见上)。
 */
class KeymapUpWatcher {
  __New() {
    this.released := false
  }
  OnUp(thisHotkey) {
    this.released := true
  }
}

/**
 * MouseKeymap._holdRepeat 的回调载体: 只持有一个 released 标志。
 *
 * 与 KeymapUpWatcher 结构相同但**刻意分成两个类**: 两者生命周期不同
 * (_holdRepeat 的 watcher 覆盖整个连续动作会话, KeymapWaitUpEvent 的只覆盖一次等待),
 * 分开也便于 harness 直接断言"泄漏的是哪一个"。
 */
class MouseHoldWatcher {
  __New() {
    this.released := false
  }
  OnUp(thisHotkey) {
    this.released := true
  }
}

/**
 * 鼠标"按住连续动作"的硬上限(毫秒)。**这是"松手后不停"的最终防线**:
 * 即使 up 事件与键态判据同时失效, 连续动作也一定在这个时长内收尾。
 *
 * 取值依据:
 *   - 正常使用里"按住连续滚/移动"很少超过 2~3 秒, 6s 已远超正常需要;
 *   - 旧值是 60000ms(60s), 故障时用户感知就是"一直在滚"(实测 _probe_d5 case2:
 *     松手后整整 60203ms 才返回), 必须收紧;
 *   - 又不能太小, 否则正常的"按住慢慢滚"会被截断。
 * 6s 同时满足两侧, 且比 60s 快一个数量级地结束异常会话。
 */
MouseRepeatHardCapMs() {
  return 6000
}

/**
 * 该键当前是否正被本进程的热键吞掉(有已启用的 down 热键)。
 *
 * 判断方式: 遍历 KeymapManager.Stack 中所有 keymap 的 M 表, 看是否存在
 * 键名 == key 且 enabled == true 的 _Hotkey。`*CapsLock` 这类会吞键;
 * 未注册的键(或只注册了 `... up` 的)不吞键。
 *
 * 为什么需要它: 只有"被吞键"的键才必须靠 up 事件判断松开 —— 那种情况下
 * 三条键态查询与 KeyWait 都会误报"已松开"。反过来, 对一个没被吞的键去等
 * up 事件, 会在"它其实早就松开了"时白等到截止(实测 3000ms 才返回)。
 *
 * 注意: 这里只读本进程的注册表, 不做任何键态查询 —— 后者的可靠性正是被质疑的对象。
 */
KeymapIsKeySwallowed(key) {
  for km in KeymapManager.Stack {
    if !IsObject(km) || !HasProp(km, "M")
      continue
    hks := km.M.Get(key, false)
    if !hks
      continue
    for hk in hks {
      ; 只认 down 热键: 名字里带 " up" 的是松开热键, 它不吞 down 事件
      if InStr(hk.rawName, " up")
        continue
      if hk.enabled
        return true
    }
  }
  return false
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

/**
 * 发送一个鼠标按键, 同时避免"自己发的键再次触发自己的热键"造成的死循环。
 *
 * ── 为什么不能用 Suspend(true) 做这件事(实测, 这是"卡死别的窗口"的真因) ──
 * Suspend(true) 是**全局**停用所有热键, 其中包括 `*XButton1` / `*XButton2`
 * 这两个"吞键"热键。热键一停, 钩子就不再拦截侧键 down, 它会直接落到前台窗口。
 * 若前台恰好是 VB6 控件(实测 freeze_log.txt: class=ThunderRT6PictureBoxDoc),
 * 控件收到 down 就 SetCapture, 而只在收到对应的 up 时才 ReleaseCapture。
 * 于是:
 *   - down 落在 Suspend 窗口内 -> 泄漏 -> 前台拿到捕获;
 *   - up   落在 Suspend 窗口外 -> 本进程钩子重新生效, up 被吞掉;
 *   - 前台永远等不到 up -> 捕获永久滞留 -> 其它窗口全部点不动 -> 必须 Win+L。
 * 实验数据(tools/probe_xbleak, 独立进程受害者窗口 + 自身 GetCapture 采样):
 *   Suspend(true)  窗口内注入 5 次 -> 泄漏 5, 出现 CAPTURE 0x0 -> 0xB80958 且不释放
 *   空闲态(无 Suspend) 注入 5 次 -> 泄漏 0
 *   纯阻塞 Sleep 3000 / 紧循环 3000 -> 泄漏 0 (顺带排除"钩子回调超时放行"假设)
 *   不对称(down 进窗口 / up 出窗口) -> down=1 up=0, 捕获滞留
 *
 * ── 现在的做法: 只关掉"会被本次 Send 自激"的那一个键 ──
 * 需要防的只是"自己发出的 btn 又触发自己的 btn 热键"这一条回路,
 * 所以只对 btn 本身做 Hotkey Off/On, 侧键与其它全部热键照常生效。
 * 实测(同窗口宽度对照, 各投 12 次):
 *   Suspend(true)        -> 侧键泄漏 12/12, 自激 0
 *   精准 Hotkey Off/On   -> 侧键泄漏 0/12,  自激 0
 *
 * 恢复走 finally, 且**只恢复本次确实关掉的那些**: 若某个键本来就没注册成功
 * (Hotkey() 抛 TargetError/ValueError), 不能盲目 "On" 把它凭空打开。
 */
SendMouseButton(btn) {
  ; MyKeymap 输入的 RButton 被鼠标手势拦截, 鼠标手势认为用户想单击右键, 所以也发送 RButton
  ; 然而这个 RButton 又会触发 MyKeymap 的右键功能, 造成死循环, 所以在发送前把同名热键暂停一下
  turnedOff := []
  for name in ["*" btn, btn] {
    try {
      Hotkey(name, "Off")
      turnedOff.Push(name)
    } catch {
      ; 该键没有注册过(或名字非法): 本来就不存在自激回路, 忽略即可
    }
  }
  try {
    Send("{blind}{" btn "}")
    Sleep 50
  } finally {
    for name in turnedOff {
      try Hotkey(name, "On")
    }
  }
}