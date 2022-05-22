#NoEnv
#SingleInstance, force
#NoTrayIcon
ListLines Off
SetWorkingDir %A_ScriptDir%
Menu, Tray, Icon, logo.ico
SendMode Input

layout := new CLayout()
layout.show()
disableIME(layout.hwnd)

OnMessage(0x100, "handle_WM_KEYDOWN")

lastText := Trim(Clipboard, " `t`r`n")

while true
{
    ClipWait
    currText := Trim(Clipboard, " `t`r`n")
    if (currText && currText != lastText)
    {
        layout.addItem(currText)
        lastText := currText
        layout.show()
    }
    Sleep, 100
}

Return

class CLayout
{
    __New() 
    {
        this.X := 10
        this.Y := 10
        this.W := 600
        this.H := 180
        this.textList := []
        Gui MyGui:New, +HwndGuiHwnd
        Gui MyGui:+LabelMyGui_On
        this.hwnd := GuiHwnd
        Gui, +Resize +AlwaysOnTop -SysMenu
        ; Gui, Font,, Consolas
        Gui, Font, s12, Microsoft YaHei UI
        Gui Add, Text,, % "连续复制后,  在本窗口内按空格复制下面的文本:                                                             "
    }
    show()
    {
        w := this.W
        h := this.H
        Gui Show, AutoSize NoActivate, 用剪切板收集文本
    }

    addItem(i)
    {
        this.textList.push(i)
        space := "y+6"
        Gui Add, Text, %space% w700 +Wrap, % i
    }

}

Join(sep, params*) {
    for index,param in params
        str .= sep . param
    return SubStr(str, StrLen(sep)+1)
}


handle_WM_KEYDOWN(wParam, lParam)
{
    global layout
    ; tooltip, % GetKeyName(Format("vk{:x}", wParam))
    switch (GetKeyName(Format("vk{:x}", wParam)))
    {
    case "Space":
        res := Trim(Join("`n", layout.textList*), " `t`r`n")
        if (res)
            clipboard := res
        ExitApp
    default: 
        ; sleep 500
    return 0
}
return 0
}

disableIME(hwnd)
{
    WinExist("ahk_id " hwnd)
    ControlGetFocus, controlName
    ControlGet, controlHwnd, Hwnd,, %controlName%
    DllCall("Imm32\ImmAssociateContext", "ptr", controlHwnd, "ptr", 0, "ptr")
}

MyGui_OnClose:
ExitApp
return