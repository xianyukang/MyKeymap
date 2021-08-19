#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

#UseHook
#SingleInstance Force
#include keymap/functions.ahk
DetectHiddenWindows, 1


time_enter_repeat = T0.2
delay_before_repeat = T0.01
fast_one := 110     
fast_repeat := 70
slow_one :=  10     
slow_repeat := 13

WinGet, winList, List, ahk_exe idea64.exe
result := ""
loop %winList%
{
    item := winList%A_Index%
    WinGetTitle, title, ahk_id %item%
    result := result . item . "-> " . "'"  . title . "'" . "`n"
}
; str = 1j        %A_ProgramsCommon%\Google Chrome.lnk      k
; tooltip, % str
; MsgBox, %result%
SetTimer, toggleHook, 1000

return

getActiveWindow() {
    ToolTip, % WinExist("A")
}

toggleHook()
{
    Hotkey, *f21, Toggle
}

8::
send % text("")
send {blind} a b c
return
9::
activateVolumne()
return

*f21::return


f9::
return
0::Reload

; 打开特定设置页面
; https://docs.microsoft.com/en-us/windows/uwp/launch-resume/launch-settings-app

activateNetwork()
{
    send #b{sleep 200}#b{sleep 10}{left 5}{sleep 10}{space}
}

activateVolumne()
{
    ; send #b{sleep 200}#b{sleep 10}{left 4}{sleep 10}{space}
    send #b
    WinExist("ahk_class Shell_TrayWnd ahk_exe Explorer.EXE")
    WinActivate
    WinWaitActive, , , 1
    send #b{left 4}{sleep 10}{space}
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


onTypoChar(ih, char) {
    ToolTip, % surroundWithSpace(ih.Input),,,17
}

onTypoEnd(ih) {
    ToolTip, % surroundWithSpace(ih.Input),,,17
}



inputHookTest() {

    ih := InputHook("C", "{Space}", "xk,sk,af")
    ih.OnChar := Func("onTypoChar")
    ih.OnEnd := Func("onTypoEnd")

    ToolTip, % surroundWithSpace("   ") 
    hotkey, *`j, off
    ih.Start()
    ih.Wait()
    ih.Stop()
    hotkey, *`j, on
    ToolTip, ` , , , 17
    WinHide, ahk_class tooltips_class32 ahk_exe MyKeymap.exe
    if (ih.Match)
    return
}


