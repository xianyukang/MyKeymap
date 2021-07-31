#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.

SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.



if not A_IsAdmin
{
try{
   Run *RunAs "%A_ScriptFullPath%"  ; 需要 v1.0.92.01+
   ExitApp
   }
catch{
    msgbox 程序能以正常权限运行 ,  但程序会在高权限窗口中完全失效
    }
}


pname := "ahk.exe"
Loop
{
   prev := ErrorLevel
   Process, Close, %pname%
   Process, Close, %pname%
   Process, Exist, %pname%
}
until !ErrorLevel or (prev = ErrorLevel)

; run, "D:\project\win\command_bar\bin\Debug\KeyboardGeek.exe"
run, "ahk.exe" "keymap\caps.ahk"
; run, window.exe
; run, "tools\wgestures\WGestures.exe"
; run, D:\project\win\x64\Debug\window.bat, D:\project\win\x64\Debug\