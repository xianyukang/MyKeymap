#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

#UseHook
#SingleInstance Force
#include functions.ahk

thread0 := AhkThread()
thread0.ahkdll("my_menu.ahk")
menuWindowId := thread0.ahkgetvar.currentWindowId

f8::
MsgBox,% A_Programs . "\Visual Studio Code\Visual Studio Code.lnk"
return

f9::
DetectHiddenWindows, on
SendMessage, 0x5555, 0x1, 0x2,, ahk_id %menuWindowId%
; WinGetTitle, title, ahk_id %menuWindowId%
; tooltip, %title%
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

loopWindows() {
    DetectHiddenWindows, off
    WinGet, id, list,,, ahk_exe Listary.exe
    Loop, %id%
    {
        this_id := id%A_Index%
        WinShow, ahk_id %this_id%
        WinActivate, ahk_id %this_id%
        WinGetClass, this_class, ahk_id %this_id%
        WinGetTitle, this_title, ahk_id %this_id%
        MsgBox, 4, , Visiting All Windows`n%a_index% of %id%`nahk_id %this_id%`nahk_class %this_class%`n%this_title%`n`nContinue?
        IfMsgBox, NO, break
    }
}

getWindow() {
    WinGet, id, ID, A
    sleep 2000
    WinShow, ahk_id %id%
    WinActivate, ahk_id %id%
}