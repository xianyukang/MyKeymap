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



*3::
    DigitMode := true
    keywait 3 
    DigitMode := false
    if (A_PriorKey == "3" && A_TimeSinceThisHotkey < 350)
        send {blind}3 
    return


#if DigitMode
*h::send  {blind}0
*j::send  {blind}1
*k::send  {blind}2
*l::send  {blind}3
*p::send {blind}7
*u::send  {blind}4
*i::send  {blind}5
*o::send  {blind}6
*n::send  {blind}8
*m::send  {blind}9



*r::
    DigitMode := false
    FnMode := true
    keywait r
    FnMode := false
    return



*space::f1
*2::backspace



#if FnMode
*r::return
*j::send   {blind}{f1}
*k::send   {blind}{f2}
*l::send   {blind}{f3}
*u::send   {blind}{f4}
*i::send   {blind}{f5}
*o::send   {blind}{f6}
*n::send   {blind}{f8}
*m::send   {blind}{f9}
*h::send   {blind}{f10}
*,::send   {blind}{f11}
*/::send   {blind}{f12}
*p::send  {blind}{f7}
w::lalt


;::sd::shutdown, 1
::rb::shutdown, 2


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


