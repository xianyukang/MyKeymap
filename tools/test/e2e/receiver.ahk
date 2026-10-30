#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn All, Off

; E2E 观察端: 焦点接收器(逐字符带时间戳)。
; 判据不看"总字符数"(本机会有真人输入), 只看**目标字符**出现次数:
;   CapsLock 模式下 q -> '[' , e -> ']' , 真人极少输入这两个字符。

outDir := A_ScriptDir "\out"
if !DirExist(outDir)
  DirCreate(outDir)
try FileDelete(outDir "\receiver.ready")
try FileDelete(outDir "\receive.log")
FileAppend("", outDir "\receive.log", "UTF-8")

g := Gui("+AlwaysOnTop -MaximizeBox -Resize", "E2E_RECEIVER")
g.SetFont("s14", "Consolas")
ed := g.AddEdit("w640 h300 -Wrap")
g.OnEvent("Close", (*) => ExitApp())
g.Show("x20 y20 w660 h340")
WinActivate("E2E_RECEIVER")
Sleep 300
ed.Focus()

; 关闭本窗口/子控件的输入法上下文: 本机 zh-CN 中文 IME 会把注入的 a 变成"话"
try DllCall("imm32\ImmAssociateContext", "ptr", g.Hwnd, "ptr", 0, "ptr")
try DllCall("imm32\ImmAssociateContext", "ptr", ed.Hwnd, "ptr", 0, "ptr")

T0 := A_TickCount
LAST := ""
LOGFILE := outDir "\receive.log"

FileAppend("READY hwnd=" g.Hwnd "`n", outDir "\receiver.ready", "UTF-8")
SetTimer(Scan, 15)
SetTimer(KeepFocus, 100)
SetTimer(CheckReset, 25)
SetTimer((*) => ExitApp(), -300000)

KeepFocus() {
  global g, ed
  if WinActive("E2E_RECEIVER") && !ed.Focused
    ed.Focus()
}

CheckReset() {
  global ed, LAST, outDir
  flag := outDir "\reset.flag"
  if !FileExist(flag)
    return
  try FileDelete(flag)
  ed.Value := ""
  LAST := ""
  FileAppend("RESET`n", outDir "\reset.ack", "UTF-8")
}

; 增量落盘: 每次新增的片段按字符逐个写, 保证时间戳是字符级
Scan() {
  global ed, LAST, LOGFILE, T0
  txt := ed.Value
  if (txt == LAST)
    return
  if (LAST != "" && InStr(txt, LAST) == 1) {
    added := SubStr(txt, StrLen(LAST) + 1)
    Loop Parse, added
      FileAppend((A_TickCount - T0) "`t" A_LoopField "`n", LOGFILE, "UTF-8")
  } else if (LAST == "") {
    Loop Parse, txt
      FileAppend((A_TickCount - T0) "`t" A_LoopField "`n", LOGFILE, "UTF-8")
  } else {
    FileAppend((A_TickCount - T0) "`t<RESET>`n", LOGFILE, "UTF-8")
    Loop Parse, txt
      FileAppend((A_TickCount - T0) "`t" A_LoopField "`n", LOGFILE, "UTF-8")
  }
  LAST := txt
}
