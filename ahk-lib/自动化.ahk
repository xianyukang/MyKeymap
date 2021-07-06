#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.



; 设置焦点
controlfocus, ENAutoCompleteEditCtrl1, A

; 发送按键或字符串
send % "^a" text("intitle:`"`"`"`"") "{left}"

send {f2}+{tab}
send {lalt down}{lshift down}{=}{lshift up}{lalt up}
send {lalt down}{lshift down}{-}{lshift up}{lalt up}