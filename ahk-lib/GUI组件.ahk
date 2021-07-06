#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.



; 新建 ahk 线程
; thread0 := AhkThread()
; thread0.ahkdll("keymap\my_menu.ahk")
; menuWindowId := thread0.ahkgetvar.currentWindowId