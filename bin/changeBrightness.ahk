; #Warn  ; Enable warnings to assist with detecting common errors.
; #Warn, UseUnsetLocal, off
; #Warn, LocalSameAsGlobal, off
#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, force
#NoTrayIcon
SetWorkingDir %A_ScriptDir% ; Ensures a consistent starting directory.
Menu, Tray, Icon, logo.ico
SendMode Input ; Recommended for new scripts due to its superior speed and reliability.

#Include, %A_ScriptDir%\Monitor.ahk

Gui, +LastFound
SysGet, monCount, MonitorCount
layout := new CLayout()

ind := 1
while (ind < monCount + 1)
{
    layout.addMon(ind)
    ind += 1
}


ind := 1
while (ind < monCount + 1)
{
    brightness := ""
    ; 笔记本的内置显示器应该是 1 号显示器(我猜的),  笔记本内置显示器要用 wmi 操作亮度
    ; 只有 1 号显示器会尝试两种获取亮度的方式
    if (ind == 1) {
        brightness := GetCurrentBrightNess()
        if (brightness != "") {
            layout.setUseWmi(ind, true)
        }
    }

    if (brightness == "") {
        brightness := Monitor.GetBrightness(ind)["Current"]
    }
    layout.setBrightnessText(ind, brightness)
    ind += 1
}

OnMessage(0x100, "WM_KEYDOWN")
layout.activate(1)
layout.show()
SetTimer, IfLoseFocusThenExit, 700
Return

IfLoseFocusThenExit()
{
    global GuiHwnd
    if not WinActive("ahk_id " GuiHwnd)
        ExitApp
}

class CLayout
{
    __New() 
    {
        this.X := 50
        this.Y := 50
        this.W := 160
        this.H := 160
        this.margin := 30
        SysGet, c, MonitorCount
        this.count := c
        this.mon := []
        this.curr := 1
        Gui MyGui:New, +HwndGuiHwnd
        Gui MyGui:+LabelMyGui_On
        Gui, Font, s12
        Gui Add, Text, x10 y280 w290 h20 +0x200, EDSF调节亮度、WR切换显示器、X退出
        Gui Add, Text, x10 y300 w490 h20 +0x200, 如果不起作用, 用 Win+P 断开并重连该显示器, 然后重启本程序试试
        
    }
    show()
    {
        w :=  this.X + 70
        h :=  320
        Gui Show, w%w% h%h%, 显示器亮度调节
    }

    addMon(i)
    {
        m := new CMon(i, this.X, this.Y, this.W, this.H)
        this.mon.push(m)
        this.X += this.W + this.margin
    }

    activate(i) {
        this.mon[i].activate()
    }
    deactivate(i) {
        this.mon[i].deactivate()
    }
    next() {
        if (this.curr >= this.count) 
            return
        this.mon[this.curr].deactivate()
        this.curr += 1
        this.mon[this.curr].activate()
    }
    prev() {
        if (this.curr <= 1) 
            return
        this.mon[this.curr].deactivate()
        this.curr -= 1
        this.mon[this.curr].activate()
    }
    setBrightnessText(i, brightness) {
        this.mon[i].setBrightnessText(brightness)
    }
    incBrightness(num) {
        this.mon[this.curr].incBrightness(num)
    }
    decBrightness(num) {
        this.mon[this.curr].decBrightness(num)
    }
    setUseWmi(i, useWmi) {
        this.mon[i].setUseWmi(useWmi)
    }

}

class CMon
{

    __New(i, X, Y, W, H)
    {
        global monitorText1
        global monitorText2
        global monitorText3
        global monitorText4
        global monitorIcon1
        global monitorIcon2
        global monitorIcon3
        global monitorIcon4

        Gui, Font, s128 c0
        Gui Add, Text, x%X% y%Y% w%W% h%H% +0x200 vMonitorIcon%i%, 🖥️
        X += 62
        Y += 70
        W := 70
        H := 32
        this.i := i
        this.useWmi := false

        Gui, Font, s32 cFFFFFF
        Gui Add, Text, x%X% y%Y% w%W% h%H% +0x200 vMonitorText%i%, 100
        GuiControl +BackgroundTrans, MonitorText%i%
    }

    activate()
    {
        i := this.i
        Gui, Font, s128 cFF6688
        GuiControl, Font, monitorIcon%i%
        Gui, Font, s32 cFFFFFF
        GuiControl, Font, monitorText%i%
    }

    deactivate()
    {
        i := this.i
        Gui, Font, s128 c0
        GuiControl, Font, monitorIcon%i%
        Gui, Font, s32 cFFFFFF
        GuiControl, Font, monitorText%i%
    }
    setBrightnessText(brightness) {
        i := this.i
        this.brightness := brightness
        GuiControl, Text, monitorText%i%, %brightness%
    }
    incBrightness(num) {
        this.brightness := this.limitBrightness(this.brightness + num)
        if (this.useWmi) {
            ChangeBrightness(this.brightness)
        } else {
            Monitor.SetBrightness(this.brightness, this.i)
        }
        this.setBrightnessText(this.brightness)
    }
    decBrightness(num) {
        this.brightness := this.limitBrightness(this.brightness - num)
        if (this.useWmi) {
            ChangeBrightness(this.brightness)
        } else {
            Monitor.SetBrightness(this.brightness, this.i)
        }
        this.setBrightnessText(this.brightness)
    }
    setUseWmi(useWmi) {
        this.useWmi := useWmi
    }
	limitBrightness(b) {
		if (b <= 0) {
			return 0
		}
		if (b >= 100) {
			return 100
		}
		return b
	}
}

WM_KEYDOWN(wParam, lParam)
{
    global layout

    ; tooltip, % GetKeyName(Format("vk{:x}", wParam))
    switch (GetKeyName(Format("vk{:x}", wParam)))
    {
        case "s": layout.decBrightness(5)
        case "f": layout.incBrightness(5)
        case "d": layout.decBrightness(10)
        case "e": layout.incBrightness(10)
        case "w": layout.prev()
        case "r": layout.next()
        case "x": ExitApp
        default: 
            ; sleep 500
        return 0
    }
    return 0
}

; msgbox, % monCount
; msgbox, % CurrentBrightness
; msgbox, % Monitor.GetBrightness(1)["Current"]
; msgbox, % Monitor.GetBrightness(2)["Current"]

; Hot Keys
; F6::ChangeBrightness( CurrentBrightness -= Increments ) ; decrease brightness
; F7::ChangeBrightness( CurrentBrightness += Increments ) ; increase brightness

; Functions
ChangeBrightness( ByRef brightness, timeout = 1 )
{

	For property in ComObjGet( "winmgmts:\\.\root\WMI" ).ExecQuery( "SELECT * FROM WmiMonitorBrightnessMethods" )
		property.WmiSetBrightness( timeout, brightness )	

}

GetCurrentBrightNess()
{
    For property in ComObjGet( "winmgmts:\\.\root\WMI" ).ExecQuery( "SELECT * FROM WmiMonitorBrightness" )
        currentBrightness := property.CurrentBrightness	

    return currentBrightness
}

MyGui_OnClose:
ExitApp
return