#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#SingleInstance, force


Gui, test:New
Gui, Add, Text,, Please enter your name:
Gui, Add, Text, voutput w400, 
Gui, test:Show, W800 H500

OnMessage(0x102, "wm_char_handler")
OnMessage(0x0100, "wm_keydown_handler")
return

wm_char_handler(wParam, lParam)
{
    ; tooltip, % "wParam: <" chr(wParam) ">"
    ;     . "`nlParam: <" lParam ">"
    ;     . "`nA_Gui: <" A_Gui ">"
    ;     . "`nA_EventInfo: <" A_EventInfo ">"
    ;     . "`nA_GuiEvent: <" A_GuiEvent ">"
    
    GuiControlGet, currentText,, output
    GuiControl,, output, % currentText . chr(wParam)
    return true
}


wm_keydown_handler(wParam, lParam)
{
    SetFormat IntegerFast, H
    tooltip, % "wParam: <" GetKeyName("VK" SubStr(wParam+0, 3)) ">"
        . "`nlParam: <" lParam ">"
        . "`nA_Gui: <" A_Gui ">"
        . "`nA_EventInfo: <" A_EventInfo ">"
        . "`nA_GuiEvent: <" A_GuiEvent ">"
    return true
}