#NoEnv
#SingleInstance, force
#NoTrayIcon
ListLines Off
SetWorkingDir %A_ScriptDir%
Menu, Tray, Icon, logo.ico
SendMode Input

layout := new CLayout()

ind := 1
while (ind < 2)
{
    layout.addItem(ind)
    SoundGet, master_volume
    layout.setBrightnessText(ind, Format("{:.0f}", master_volume))
    ind += 1
}


OnMessage(0x100, "WM_KEYDOWN")
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
        this.X := 180
        this.Y := 10
        this.W := 180
        this.H := 180
        this.margin := 30
        SysGet, c, MonitorCount
        this.count := c
        this.mon := []
        this.curr := 1
        Gui MyGui:New,  +HwndGuiHwnd
        Gui MyGui:+LabelMyGui_On
        ; Gui, Font,, Consolas
        Gui, Font, s12
        Gui Add, Text, x6 y296 w590 h20 +0x200, EDSF调节音量、AG上一首下一首、空格切换静音、C暂停/播放、V设置、X退出
    }
    show()
    {
        w :=  this.X + 166
        h :=  320
        Gui Show, w%w% h%h%, 声音控制
    }

    addItem(i)
    {
        m := new Mon(i, this.X, this.Y, this.W, this.H)
        this.mon.push(m)
        this.X += this.W + this.margin
    }

    mute(val) {
        this.mon[this.curr].mute(val)
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
        local master_volume
        SoundGet, master_volume
        layout.setBrightnessText(this.curr, Format("{:.0f}", master_volume))
        this.mon[this.curr].incBrightness(num)
    }
    decBrightness(num) {
        local master_volume
        SoundGet, master_volume
        layout.setBrightnessText(this.curr, Format("{:.0f}", master_volume))
        this.mon[this.curr].decBrightness(num)
    }
    setUseWmi(i, useWmi) {
        this.mon[i].setUseWmi(useWmi)
    }

}

class Mon
{

    __New(i, X, Y, W, H)
    {
        global muteText1
        global monitorText1
        global monitorText2
        global monitorText3
        global monitorText4
        global monitorIcon1
        global monitorIcon2
        global monitorIcon3
        global monitorIcon4

        Gui, Font, s128 c0
        Gui Add, Text, x%X% y%Y% w%W% h%H% +0x200 vMonitorIcon%i%, 🔊
        X += 62
        Y += 190
        W := 120
        H := 40
        this.i := i
        this.useWmi := false

        Gui, Font, s32 c0
        Gui Add, Text, x%X% y%Y% w%W% h%H% +0x200 vMonitorText%i%, 100
        GuiControl +BackgroundTrans, MonitorText%i%
    }

    mute(mute)
    {
        if (mute == "On") {
            this.setBrightnessText(this.brightness, "🔇")
        }
        if (mute == "Off") {
            this.setBrightnessText(this.brightness, "")
        }
    }

    activate()
    {
        i := this.i
        Gui, Font, s128 cFF6688
        GuiControl, Font, monitorIcon%i%
        Gui, Font, s32 c0
        GuiControl, Font, monitorText%i%
    }

    deactivate()
    {
        i := this.i
        Gui, Font, s128 c0
        GuiControl, Font, monitorIcon%i%
        Gui, Font, s32 c0
        GuiControl, Font, monitorText%i%
    }
    setBrightnessText(brightness, mute := "") {
        i := this.i
        this.brightness := brightness
        t := brightness . mute
        GuiControl, Text, monitorText%i%, %t%
    }
    incBrightness(num) {
        this.brightness := this.limitBrightness(this.brightness + num)
        SoundSet, this.brightness
        this.setBrightnessText(this.brightness)
    }
    decBrightness(num) {
        this.brightness := this.limitBrightness(this.brightness - num)
        SoundSet, this.brightness
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
        case "a": send {Media_Prev}
        case "g": send {Media_Next}
        case "v": 
            run, ms-settings:apps-volume
            ExitApp
        case "c": send {Media_Play_Pause}
        case "s": layout.decBrightness(1)
        case "f": layout.incBrightness(1)
        case "d": layout.decBrightness(5)
        case "e": layout.incBrightness(5)
        case "w": layout.prev()
        case "r": layout.next()
        case "Space": 
            SoundSet, +1,, Mute
            SoundGet, val, MASTER, MUTE
            layout.mute(val)
        case "x": ExitApp
        default: 
            ; sleep 500
        return 0
    }
    return 0
}



MyGui_OnClose:
ExitApp
return