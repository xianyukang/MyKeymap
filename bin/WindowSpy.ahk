;
; Window Spy for AHKv2
;

#Requires AutoHotkey v2.0

#NoTrayIcon
#SingleInstance force
SetWorkingDir A_ScriptDir
CoordMode "Pixel", "Screen"

Global oGui

WinSpyGui()

WinSpyGui() {
    Global oGui

    try TraySetIcon "./icons/logo.ico"
    DllCall("shell32\SetCurrentProcessExplicitAppUserModelID", "wstr", "AutoHotkey.WindowSpy")

    oGui := Gui("AlwaysOnTop Resize MinSize +DPIScale", "")
    oGui.OnEvent("Close", WinSpyClose)
    oGui.OnEvent("Size", WinSpySize)

    oGui.BackColor := "FFFFFF"
    oGui.SetFont("s11")
    oGui.Add("Text", , "程序的窗口标识符有下面三种:")
    oGui.Add("Text", , "▷ 窗口名:      无标题 - 记事本")
    oGui.Add("Text", , "▷ 进程名:      ahk_exe notepad.exe")
    oGui.Add("Text", , "▷ 窗口类名:   ahk_class Notepad")
    oGui.Add("Text", , "➤ 一般选进程名")
    oGui.Add("Text", , "➤ 可以只使用部分窗口名: 记事")
    oGui.Add("Text", , "➤ 也可以组合两个标识符: 记事 ahk_exe notepad.exe (更精确")
    oGui.Add("Text", , "")

    oGui.Add("Text", , "当前窗口的三种标识符:")
    oGui.Add("Edit", "xm w640 r4 ReadOnly -Wrap vCtrl_Title")
    ; oGui.Add("Text",,"当前鼠标位置:")
    ; oGui.Add("Edit","w640 r4 ReadOnly vCtrl_MousePos")
    ; oGui.Add("Text",,"当前窗口位置:")
    ; oGui.Add("Edit","w640 r2 ReadOnly vCtrl_Pos")
    oGui.Add("Text", "w640 r1 vCtrl_Freeze", (txtNotFrozen := ""))
    oGui.Add("Checkbox", "yp+20 xp+400 h15 w240 Left vCtrl_FollowMouse", "跟随鼠标 (可按 Ctrl 暂停刷新)")

    oGui.Show("NoActivate")
    WinGetClientPos(&x_temp, &y_temp2, , , "ahk_id " oGui.hwnd)

    ; oGui.horzMargin := x_temp*96//A_ScreenDPI - 320 ; now using oGui.MarginX

    oGui.txtNotFrozen := txtNotFrozen       ; create properties for futur use
    oGui.txtFrozen := ""

    SetTimer Update, 250
}

WinSpySize(GuiObj, MinMax, Width, Height) {
    Global oGui

    If !oGui.HasProp("txtNotFrozen") ; WinSpyGui() not done yet, return until it is
        return

    SetTimer Update, (MinMax = 0) ? 250 : 0 ; suspend updates on minimize

    ctrlW := Width - (oGui.MarginX * 2) ; ctrlW := Width - horzMargin
    list := "Title,MousePos,Ctrl,Pos,SBText,VisText,AllText,Freeze"
}

WinSpyClose(GuiObj) {
    ExitApp
}

Update() { ; timer, no params
    Try TryUpdate() ; Try
}

TryUpdate() {
    Global oGui

    If !oGui.HasProp("txtNotFrozen") ; WinSpyGui() not done yet, return until it is
        return

    Ctrl_FollowMouse := oGui["Ctrl_FollowMouse"].Value
    CoordMode "Mouse", "Screen"
    MouseGetPos &msX, &msY, &msWin, &msCtrl, 2 ; get ClassNN and hWindow
    actWin := WinExist("A")

    if (Ctrl_FollowMouse) {
        curWin := msWin, curCtrl := msCtrl
        WinExist("ahk_id " curWin) ; updating LastWindowFound?
    } else {
        curWin := actWin
        curCtrl := ControlGetFocus() ; get focused control hwnd from active win
    }
    curCtrlClassNN := ""
    Try curCtrlClassNN := ControlGetClassNN(curCtrl)

    t1 := WinGetTitle(), t2 := WinGetClass()
    if (curWin = oGui.hwnd || t2 = "MultitaskingViewFrame") { ; Our Gui || Alt-tab
        UpdateText("Ctrl_Freeze", oGui.txtFrozen)
        return
    }

    UpdateText("Ctrl_Freeze", oGui.txtNotFrozen)
    t3 := WinGetProcessName()

    WinDataText := t1 "`n" ; ZZZ
        . "ahk_class " t2 "`n"
        . "ahk_exe " t3 "`n"

    UpdateText("Ctrl_Title", WinDataText)
    CoordMode "Mouse", "Window"
    MouseGetPos &mrX, &mrY
    CoordMode "Mouse", "Client"
    MouseGetPos &mcX, &mcY
    mClr := PixelGetColor(msX, msY, "RGB")
    mClr := SubStr(mClr, 3)

    mpText := "Screen:`t" msX ", " msY "`n"
        . "Window:`t" mrX ", " mrY "`n"
        . "Client:`t" mcX ", " mcY " (default)`n"
        . "Color:`t" mClr " (Red=" SubStr(mClr, 1, 2) " Green=" SubStr(mClr, 3, 2) " Blue=" SubStr(mClr, 5) ")"

    UpdateText("Ctrl_MousePos", mpText)

    wX := "", wY := "", wW := "", wH := ""
    WinGetPos &wX, &wY, &wW, &wH, "ahk_id " curWin
    WinGetClientPos(&wcX, &wcY, &wcW, &wcH, "ahk_id " curWin)

    wText := "Screen:`tx: " wX "`ty: " wY "`tw: " wW "`th: " wH "`n"
        . "Client:`tx: " wcX "`ty: " wcY "`tw: " wcW "`th: " wcH

    UpdateText("Ctrl_Pos", wText)
    sbTxt := ""

    Loop {
        ovi := ""
        Try ovi := StatusBarGetText(A_Index)
        if (ovi = "")
            break
        sbTxt .= "(" A_Index "):`t" textMangle(ovi) "`n"
    }

    sbTxt := SubStr(sbTxt, 1, -1) ; StringTrimRight, sbTxt, sbTxt, 1
    UpdateText("Ctrl_SBText", sbTxt)
    bSlow := oGui["Ctrl_IsSlow"].Value ; GuiControlGet, bSlow,, Ctrl_IsSlow

    if (bSlow) {
        DetectHiddenText False
        ovVisText := WinGetText() ; WinGetText, ovVisText
        DetectHiddenText True
        ovAllText := WinGetText() ; WinGetText, ovAllText
    } else {
        ovVisText := WinGetTextFast(false)
        ovAllText := WinGetTextFast(true)
    }

    UpdateText("Ctrl_VisText", ovVisText)
    UpdateText("Ctrl_AllText", ovAllText)
}

; ===========================================================================================
; WinGetText ALWAYS uses the "slow" mode - TitleMatchMode only affects
; WinText/ExcludeText parameters. In "fast" mode, GetWindowText() is used
; to retrieve the text of each control.
; ===========================================================================================
WinGetTextFast(detect_hidden) {
    controls := WinGetControlsHwnd()

    static WINDOW_TEXT_SIZE := 32767 ; Defined in AutoHotkey source.

    buf := Buffer(WINDOW_TEXT_SIZE * 2, 0)

    text := ""

    Loop controls.Length {
        hCtl := controls[A_Index]
        if !detect_hidden && !DllCall("IsWindowVisible", "ptr", hCtl)
            continue
        if !DllCall("GetWindowText", "ptr", hCtl, "Ptr", buf.ptr, "int", WINDOW_TEXT_SIZE)
            continue

        text .= StrGet(buf) "`r`n" ; text .= buf "`r`n"
    }
    return text
}

; ===========================================================================================
; Unlike using a pure GuiControl, this function causes the text of the
; controls to be updated only when the text has changed, preventing periodic
; flickering (especially on older systems).
; ===========================================================================================
UpdateText(vCtl, NewText) {
    Global oGui
    static OldText := {}
    ctl := oGui[vCtl], hCtl := Integer(ctl.hwnd)

    if (!oldText.HasProp(hCtl) Or OldText.%hCtl% != NewText) {
        ctl.Value := NewText
        OldText.%hCtl% := NewText
    }
}

textMangle(x) {
    elli := false
    if (pos := InStr(x, "`n"))
        x := SubStr(x, 1, pos - 1), elli := true
    else if (StrLen(x) > 40)
        x := SubStr(x, 1, 40), elli := true
    if elli
        x .= " (...)"
    return x
}

suspend_timer() {
    Global oGui
    SetTimer Update, 0
    UpdateText("Ctrl_Freeze", oGui.txtFrozen)
}

~*Shift::
~*Ctrl:: suspend_timer()

~*Ctrl up::
~*Shift up:: SetTimer Update, 250