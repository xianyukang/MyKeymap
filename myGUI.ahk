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

class TypoTipWindow
{
    __New()
    {

        text := "fuck"
        fontSize := 12
        Font_Colour := 0x0 ;0x2879ff
        Back_Colour := 0xffffe1 ; 0x34495e

        Gui, TYPO_TIP_WINDOW:New, +hwndhGui, ` 
        this.hwnd := hGui

        Gui, +Owner +ToolWindow +Disabled -SysMenu -Caption +E0x20 +AlwaysOnTop +Border
        GUI, Margin, %fontsize%, % fontsize / 5
        GUI, Color, % Back_Colour
        GUI, Font, c%Font_Colour% s%fontsize%, Microsoft Sans Serif

        static ControlID                            ; 存储控件 ID,  不同于 Hwnd
        GUI, Add, Text, vControlID center, %text%
        GuiControlGet, OutputVar, Hwnd , ControlID  ; 获取 Hwnd
        this.textHwnd := OutputVar                  ; 保存到对象属性

    }

    show(text) {
        GuiControl, Text, % this.textHwnd, %text%
        GuiControl, Show, % this.textHwnd
        MouseGetPos, xpos, ypos 
        Gui, TYPO_TIP_WINDOW:Show, AutoSize Center  NoActivate x%xpos% y%ypos%
    }
    
    hide() {
        GuiControl, Hide, % this.textHwnd
        Gui, TYPO_TIP_WINDOW:Show, Hide
    }
}

7::
    typoTip.show("11111111111")
    sleep 1000
    typoTip.hide()
    typoTip.show("22222222222")
    sleep 1000
    typoTip.hide()

return
