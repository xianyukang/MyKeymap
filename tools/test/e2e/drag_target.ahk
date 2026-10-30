#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn All, Off

; E2E 观察端: 被拖拽的目标窗口。独立进程, 普通可移动顶层窗口。
; 位置由 Python 端用 GetWindowRect 采样, 本脚本不记录任何东西。

outDir := A_ScriptDir "\out"
if !DirExist(outDir)
  DirCreate(outDir)
try FileDelete(outDir "\drag_target.ready")

g := Gui("+AlwaysOnTop +Resize", "E2E_DRAG_TARGET")
g.SetFont("s16", "Consolas")
g.AddText("w380 h40", "E2E DRAG TARGET")
g.AddEdit("w380 h180 ReadOnly", "target content (drag with XButton2)")
g.OnEvent("Close", (*) => ExitApp())
g.Show("x820 y300 w400 h260")

FileAppend("READY hwnd=" g.Hwnd "`n", outDir "\drag_target.ready", "UTF-8")
