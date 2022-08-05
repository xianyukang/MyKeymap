#NoEnv
#SingleInstance, force
#NoTrayIcon
ListLines Off
SetWorkingDir %A_ScriptDir%
Menu, Tray, Icon, logo.ico
SendMode Input

resetGUI()
OnMessage(0x100, "handle_WM_KEYDOWN")
SetTimer, onClipboardChange, 100
Return

resetGUI(title := "连续复制后、在本窗口内按空格键")
{
    global
    lastText := Trim(Clipboard, " `t`r`n")
    Gui, Destroy
    layout := new CLayout()
    layout.show(title)
    disableIME(layout.hwnd)
    SetTimer, resetTitle, -5000
}

onClipboardChange()
{
    global layout, lastText
    currText := Trim(Clipboard, " `t`r`n")

    if (currText && currText != lastText)
    {
        layout.addItem(currText)
        lastText := currText
        layout.show()
    }
}

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
        Gui Add, Text, y-20, % "连续复制后,  在本窗口内按空格复制下面的文本:                                                             "
    }
    show(title := "连续复制后、在本窗口内按空格键")
    {
        w := this.W
        h := this.H
        Gui MyGui:Show, AutoSize NoActivate, %title%
    }

    addItem(i)
    {
        this.textList.push(i)
        space := "y+6"
        Gui MyGui:Add, Text, %space% w700 +Wrap, % i
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
        SetTimer, onClipboardChange, Off
        resetGUI("已把收集到的 " layout.textList.Length() " 行文本挪入剪切板")
        SetTimer, onClipboardChange, On
    case "Escape":
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


resetTitle() {
    global layout
    layout.show()
}

MyGui_OnClose:
ExitApp
return