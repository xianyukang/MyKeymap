#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir% ; Ensures a consistent starting directory.

#UseHook
#SingleInstance Force
#include keymap/functions.ahk
DetectHiddenWindows, 1

coordmode, mouse, screen
global typoTip := new TypoTipWindow()
return

7::
    typoTip.show("fuck")
    sleep 1000
    typoTip.hide()
    typoTip.show("shit")
    sleep 1000
    typoTip.hide()

return
