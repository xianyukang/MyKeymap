/**
 * Midi.ahk — MyKeymap MIDI 音符动作运行时 (AutoHotkey v2)
 *
 * 作用:
 *   把按键的按下/松开翻译为 MIDI NoteOn/NoteOff, 输出到虚拟 MIDI 端口,
 *   使 MyKeymap 等同 MIDI 输入设备. 不依赖任何第三方 MIDI 库.
 *
 * 设计决策 (方案 1 — 仅精确匹配, 不自动创建, 不回退):
 *   - 只使用 winmm (midiOutOpen / midiOutShortMsg) 向系统已注册的输出端口发送;
 *   - 严格精确匹配配置的端口名 (忽略大小写), 匹配不到或打开失败即视为不可用,
 *     MidiInit 返回 false, 并写入 g_MidiLastError, 由调用方决定如何提示用户;
 *   - 明确不再回退到「名字含 loopMIDI 的端口」或 0 号设备, 避免端口名写错时
 *     意外从其它端口发声、让用户误以为配置成功;
 *   - 明确不再用 teVirtualMIDI 在本进程内自建端口. 原因: teVirtualMIDI 创建的
 *     是进程内私有端口, 它不会通过 winmm 向系统注册, 系统枚举 (midiOutGetNumDevs)
 *     看不到它, DAW / MIDI 监视器等外部程序根本无法枚举与打开, 数据只能自己发给自己,
 *     对用户毫无意义. 因此正确做法是让用户用 loopMIDI 创建持久端口.
 *
 * 对外函数:
 *   MidiInit(portName)                           精确匹配并打开 winmm 输出端口
 *   MidiShowNotReadyTip()                        端口不可用时弹出一次明确提示
 *   MidiNoteOn(note, channel := 1, velocity := 100)  发送 NoteOn (按下发声)
 *   MidiNoteOff(note, channel := 1)              发送 NoteOff (松开停声)
 *   MidiAllNotesOff()                            对全部 16 通道发送 CC123, 防卡音
 *   MidiClose()                                  关闭端口并清空状态
 *   MidiDebugPorts()                             仅调试: 返回所有输出端口名
 *
 * MIDI 通道名/编号映射:
 *   对外约定通道为 1–16 (与 midiOutGetDevCaps 的 wChannelMask 一致);
 *   winmm 消息字节低 4 位使用 0–15, 因此内部一律以 (channel - 1) 换算.
 *
 * MIDIOUTCAPS 结构体 (Unicode / 64 位, 4 字节对齐):
 *   偏移 0  WORD  wMid            2
 *   偏移 2  WORD  wPid            2
 *   偏移 4  UINT  vDriverVersion  4
 *   偏移 8  WCHAR szPname[32]     64   <- 端口名, 用 StrGet(ptr + 8, 32, "UTF-16") 读取
 *   偏移 72 WORD  wTechnology     2
 *   偏移 74 WORD  wVoices         2
 *   偏移 76 WORD  wNotes          2
 *   偏移 78 WORD  wChannelMask    2
 *   偏移 80 DWORD dwSupport       4
 *   合计 84 字节
 */

; ---- 模块级静态状态 (Super-global, 进程内共享, 保证只打开一次) ----
global g_MidiHandle := 0          ; HMIDIOUT 输出句柄; 0 表示未打开
global g_MidiDeviceID := -1       ; 当前已打开的 MIDI 设备号
global g_MidiPortName := ""       ; 当前已打开的端口名
global g_MidiLastError := ""      ; 最近一次失败原因
global g_MidiRequestedPortName := ""  ; 最近一次 MidiInit 请求的端口名 (供提示用)
; 当前处于「已按下 / 已 NoteOn」状态的音符集合, 键为 "note|channel".
; 用途: 过滤热键自动重复(键盘 AutoRepeat)带来的重复 NoteOn,
;       使长按只在首次按下发声, 松开才 NoteOff.
global g_MidiActiveNotes := Map()

; ---- MIDIOUTCAPS 布局常量 ----
global MIDI_CAPS_SIZE := 84             ; 结构体总大小 (字节)
global MIDI_CAPS_PNAME_OFFSET := 8      ; szPname 的偏移 (字节)
global MIDI_CAPS_PNAME_CCH := 32        ; szPname 的 WCHAR 数

/**
 * 初始化 MIDI 输出.
 *  - 已打开时直接复用, 进程内只初始化一次.
 *  - 枚举 winmm 输出设备, 仅精确匹配 portName (忽略大小写).
 *  - 匹配到则 midiOutOpen 并返回 true; 匹配不到或打开失败返回 false,
 *    原因写入 g_MidiLastError. 不回退到其它端口, 不自建端口.
 * 任何一步失败都不会抛错, 只会返回 false.
 * @param portName 期望的端口名 (必须非空才能匹配)
 * @return true 表示已成功打开; false 表示端口不可用 (原因见 g_MidiLastError)
 */
MidiInit(portName) {
  ; AHK v2 中函数内一旦赋值即视为局部变量, 访问模块级静态状态必须显式 global
  global g_MidiHandle, g_MidiDeviceID, g_MidiPortName, g_MidiLastError, g_MidiRequestedPortName
  ; 已打开则复用
  if (g_MidiHandle != 0) {
    return true
  }

  g_MidiRequestedPortName := portName

  if (portName = "") {
    g_MidiLastError := "未配置 MIDI 端口名"
    OutputDebug("MidiInit: " g_MidiLastError)
    return false
  }

  numDevs := DllCall("winmm\midiOutGetNumDevs", "UInt")
  matchExact := -1    ; 精确匹配 portName 的设备号

  if (numDevs > 0) {
    caps := Buffer(MIDI_CAPS_SIZE, 0)
    i := 0
    while (i < numDevs) {
      res := DllCall("winmm\midiOutGetDevCapsW", "UPtr", i, "Ptr", caps, "UInt", MIDI_CAPS_SIZE, "UInt")
      if (res = 0) {
        name := StrGet(caps.Ptr + MIDI_CAPS_PNAME_OFFSET, MIDI_CAPS_PNAME_CCH, "UTF-16")
        ; 用 = 表示忽略大小写进行字符串比较
        if (name = portName) {
          matchExact := i
          break
        }
      } else {
        OutputDebug("MidiInit: midiOutGetDevCapsW 失败, 设备 " i ", 错误码 " res)
      }
      i++
    }
  }

  ; 精确匹配到目标端口, 打开并返回
  if (matchExact != -1) {
    return MidiOpenWinmm(matchExact, portName)
  }

  g_MidiLastError := "未找到 MIDI 端口 '" portName "' (系统输出端口数 " numDevs ")"
  OutputDebug("MidiInit: " g_MidiLastError)
  return false
}

/**
 * 内部: 按设备号打开 winmm 输出端口.
 * @param devID winmm 设备号
 * @param portName 记录用的端口名
 * @return true 表示打开成功
 */
MidiOpenWinmm(devID, portName) {
  global g_MidiHandle, g_MidiDeviceID, g_MidiPortName, g_MidiLastError
  hMidi := 0
  res := DllCall("winmm\midiOutOpen", "Ptr*", &hMidi, "UInt", devID, "Ptr", 0, "Ptr", 0, "UInt", 0, "UInt")
  if (res != 0) {   ; MMSYSERR_NOERROR = 0
    g_MidiLastError := "midiOutOpen 失败, 设备 " devID ", 错误码 " res
    OutputDebug("MidiInit: " g_MidiLastError)
    return false
  }
  g_MidiHandle := hMidi
  g_MidiDeviceID := devID
  g_MidiPortName := portName
  g_MidiLastError := ""
  return true
}

/**
 * 端口不可用时, 用项目既有的 Tip() 弹出一条明确提示, 告诉用户去 loopMIDI 创建端口.
 *  - 提示只表达「MIDI 动作当前不生效」, 不做任何端口创建/回退.
 *  - Tip 可能未加载 (精简构建) 或本身异常, 用 try 包裹保证不崩溃.
 */
MidiShowNotReadyTip() {
  global g_MidiRequestedPortName
  name := (g_MidiRequestedPortName != "") ? g_MidiRequestedPortName : "loopMIDI Port"
  msg := '未找到 MIDI 端口 "' name '", 请在 loopMIDI 中创建该端口并保持其运行'
  try Tip(msg, -3000)
}

/**
 * 发送 NoteOn (按下发声).
 * dwMsg = (0x90 | ((channel-1) & 0x0F)) | (note << 8) | (velocity << 16)
 * @param note 音符号 0–127
 * @param channel MIDI 通道 1–16
 * @param velocity 力度 1–127
 * @return true 表示消息已提交; false 表示端口未打开或发送失败
 */
MidiNoteOn(note, channel := 1, velocity := 100) {
  global g_MidiActiveNotes
  if (!MidiReady()) {
    return false
  }
  ; 该 (note, channel) 已处于发声状态: 这是热键自动重复(按住不放)触发的重复 down,
  ; 直接忽略, 不再重发 NoteOn, 避免听感上的「连打」.
  key := MidiNoteKey(note, channel)
  if (g_MidiActiveNotes.Has(key)) {
    return false
  }
  ch := (channel - 1) & 0x0F
  msg := (0x90 | ch) | ((note & 0x7F) << 8) | ((velocity & 0x7F) << 16)
  ok := MidiSend(msg)
  ; 仅在成功发出后登记, 保证发送失败时后续重试仍能发声
  if (ok) {
    g_MidiActiveNotes[key] := true
  }
  return ok
}

/**
 * 发送 NoteOff (松开停声).
 * dwMsg = (0x80 | ((channel-1) & 0x0F)) | (note << 8)
 * @param note 音符号 0–127
 * @param channel MIDI 通道 1–16
 * @return true 表示消息已提交; false 表示端口未打开或发送失败
 */
MidiNoteOff(note, channel := 1) {
  global g_MidiActiveNotes
  if (!MidiReady()) {
    return false
  }
  ; 无论先前是否成功 NoteOn, 松开都应发出 NoteOff:
  ;  - 清理状态寄存器, 使同一 note/channel 的下一次按下能重新发声;
  ;  - 防止端口重新打开等边缘情况下残留发声.
  key := MidiNoteKey(note, channel)
  if (g_MidiActiveNotes.Has(key)) {
    g_MidiActiveNotes.Delete(key)
  }
  ch := (channel - 1) & 0x0F
  msg := (0x80 | ch) | ((note & 0x7F) << 8)
  return MidiSend(msg)
}

/**
 * 对全部 16 个通道发送 CC123 (All Notes Off), 用于退出/重载前防止残留发声.
 * dwMsg = (0xB0 | ((channel-1) & 0x0F)) | (123 << 8)
 * @return true 表示已尝试发送; false 表示端口未打开
 */
MidiAllNotesOff() {
  global g_MidiActiveNotes
  if (!MidiReady()) {
    return false
  }
  ch := 0
  while (ch < 16) {
    msg := (0xB0 | ch) | (123 << 8)
    MidiSend(msg)
    ch++
  }
  ; 已全部静音, 同步清空发声状态, 避免残留状态导致后续按下被误判为重复而吞掉
  g_MidiActiveNotes := Map()
  return true
}

/**
 * 内部: 生成 (note, channel) 状态寄存器的键.
 * Channel 归一化到 1–16, 保证 channel=0 与 channel=16 等写法不产生歧义.
 * @param note 音符号
 * @param channel MIDI 通道
 * @return 形如 "60|1" 的字符串键
 */
MidiNoteKey(note, channel) {
  if (channel <= 0) {
    channel := 1
  } else if (channel > 16) {
    channel := 16
  }
  return (note & 0x7F) "|" channel
}

/**
 * 内部: 当前是否已有可发送的端口 (winmm 句柄有效).
 */
MidiReady() {
  global g_MidiHandle
  return g_MidiHandle != 0
}

/**
 * 关闭 MIDI 输出端口并清空状态.
 * @return true 表示关闭成功或本就未打开; false 表示底层关闭失败
 */
MidiClose() {
  global g_MidiHandle, g_MidiDeviceID, g_MidiPortName, g_MidiLastError, g_MidiActiveNotes
  ok := true

  if (g_MidiHandle) {
    res := DllCall("winmm\midiOutClose", "Ptr", g_MidiHandle, "UInt")
    if (res != 0) {
      g_MidiLastError := "midiOutClose 失败, 错误码 " res
      OutputDebug("MidiClose: " g_MidiLastError)
      ok := false
    }
  }

  g_MidiHandle := 0
  g_MidiDeviceID := -1
  g_MidiPortName := ""
  ; 端口已关闭, 发声状态全部失效, 清空避免残留
  g_MidiActiveNotes := Map()
  return ok
}

/**
 * 内部: 发送一条已打包的 32 位 MIDI 短消息 (winmm.midiOutShortMsg).
 * @param dwMsg 32 位 MIDI 短消息
 * @return true 表示发送成功
 */
MidiSend(dwMsg) {
  global g_MidiHandle, g_MidiLastError
  if (!g_MidiHandle) {
    return false
  }
  res := DllCall("winmm\midiOutShortMsg", "Ptr", g_MidiHandle, "UInt", dwMsg, "UInt")
  if (res != 0) {
    g_MidiLastError := "midiOutShortMsg 失败, 错误码 " res
    return false
  }
  return true
}

/**
 * 仅调试用: 返回所有 MIDI 输出端口名的多行文本. 正常流程不会调用.
 */
MidiDebugPorts() {
  numDevs := DllCall("winmm\midiOutGetNumDevs", "UInt")
  caps := Buffer(MIDI_CAPS_SIZE, 0)
  out := "MIDI 输出设备数量: " numDevs "`n"
  i := 0
  while (i < numDevs) {
    res := DllCall("winmm\midiOutGetDevCapsW", "UPtr", i, "Ptr", caps, "UInt", MIDI_CAPS_SIZE, "UInt")
    if (res = 0) {
      name := StrGet(caps.Ptr + MIDI_CAPS_PNAME_OFFSET, MIDI_CAPS_PNAME_CCH, "UTF-16")
      out .= i ": " name "`n"
    } else {
      out .= i ": <读取失败, 错误码 " res ">`n"
    }
    i++
  }
  return out
}
