#NoEnv
#notrayicon
#SingleInstance Force
#UseHook
#MaxHotkeysPerInterval 200

#include keymap/functions.ahk



SetBatchLines -1
ListLines Off
process, Priority, , A
SetWorkingDir %A_ScriptDir%  
SendMode Input

coordmode,  mouse,  screen
settitlematchmode, 2
SetDefaultMouseSpeed, 0


init()

#if







init()
{
    global
    DetectHiddenWindows, on
    winget, exeFullPath, ProcessPath, ahk_id %A_ScriptHwnd%
    winget, pid, PID, ahk_id %A_ScriptHwnd%
    pos := InStr(exeFullPath, "\",, 0)
    parentPath := substr(exeFullPath, 1, pos)
    SetWorkingDir, %parentPath%
    DetectHiddenWindows, off
}


