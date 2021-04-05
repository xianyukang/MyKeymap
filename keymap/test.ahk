#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

#UseHook
#SingleInstance Force
#include functions.ahk

f8::
SwitchWindows()
return


SwitchWindows()
{
    wingetclass, class, A
    if (class == "ApplicationFrameWindow")
        to_check := "ahk_class "  class  "ahk_exe "  GetProcessName()
    else
        to_check := "ahk_exe "  GetProcessName()

    MyGroupActivate(to_check)
    return
}