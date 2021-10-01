#NoEnv
#SingleInstance Force
#MaxHotkeysPerInterval 70
#NoTrayIcon
#WinActivateForce               ; 解决「 winactivate 最小化的窗口时不会把窗口放到顶层(被其他窗口遮住) 」
#InstallKeybdHook               ; 可能是 ahk 自动卸载 hook 导致的丢失 hook,  如果用这行指令, ahk 是否就不会卸载 hook 了呢?
#include data/custom_functions.ahk
#include bin/functions.ahk

StringCaseSense, On
SetWorkingDir %A_ScriptDir%\..
requireAdmin()
closeOldInstance()

SetBatchLines -1
ListLines Off
process, Priority,, H
; 使用 sendinput 时,  通过 alt+3+j 输入 alt+1 时,  会发送 ctrl+alt
SendMode Input
; SetKeyDelay, 0
; SetMouseDelay, 0

SetMouseDelay, 0  ; 发送完一个鼠标后不会 sleep
SetDefaultMouseSpeed, 0
coordmode, mouse, screen
settitlematchmode, 2



SemicolonAbbrTip := true
time_enter_repeat = T0.2
delay_before_repeat = T0.01
fast_one := 110     
fast_repeat := 70
slow_one :=  10     
slow_repeat := 13

; Menu, Tray, NoStandard
Menu, Tray, Add, 视频教程, trayMenuHandler
Menu, Tray, Add, 参考/示例, trayMenuHandler 
Menu, Tray, Add 
Menu, Tray, Add, 打开设置, trayMenuHandler 
Menu, Tray, Add, 暂停, trayMenuHandler
Menu, Tray, Add, 退出, trayMenuHandler
Menu, Tray, Add 

Menu, Tray, Icon
Menu, Tray, Icon, bin\logo.ico,, 1
Menu, Tray, Tip, MyKeymap 1.0 by 咸鱼阿康12333
; processPath := getProcessPath()
; SetWorkingDir, %processPath%


CoordMode, Mouse, Screen
; 多显示器不同缩放比例导致的问题,  https://www.autohotkey.com/boards/viewtopic.php?f=14&t=13810
DllCall("SetThreadDpiAwarenessContext", "ptr", -3, "ptr")


global typoTip := new TypoTipWindow()

semiHook := InputHook("C", "{Space}", {{{ SemicolonAbbrKeys|join(',')|ahkString }}})
semiHook.OnChar := Func("onTypoChar")
semiHook.OnEnd := Func("onTypoEnd")
capsHook := InputHook("C", "{LControl}{RControl}{LAlt}{RAlt}{Space}{Esc}{LWin}{RWin}", {{{ CapslockAbbrKeys|join(',')|ahkString }}})
capsHook.OnChar := Func("capsOnTypoChar")
capsHook.OnEnd := Func("capsOnTypoEnd")

return

RAlt::LCtrl
!+'::
    Suspend, Permit
    toggleSuspend()
    return
!'::
    Suspend, Toggle
    ReloadProgram()
    return
+capslock::toggleCapslock()

*capslock::
    thisHotkey := A_ThisHotkey
    disableOtherHotkey(thisHotkey)
    CapslockMode := true
    keywait capslock
    CapslockMode := false
    if (A_PriorKey == "CapsLock" && A_TimeSinceThisHotkey < 450) {
        enterCapslockAbbr(capsHook)
    }
    enableOtherHotkey(thisHotkey)
    return


*j::
    thisHotkey := A_ThisHotkey
    disableOtherHotkey(thisHotkey)
    JMode := true
    keywait j
    JMode := false
    if (A_PriorKey == "j" && A_TimeSinceThisHotkey < 350)
            send  {blind}j
    enableOtherHotkey(thisHotkey)
    return


*`;::
    thisHotkey := A_ThisHotkey
    disableOtherHotkey(thisHotkey)
    PunctuationMode := true
    keywait `; 
    PunctuationMode := false
    if (A_PriorKey == ";" && A_TimeSinceThisHotkey < 350)
        enterSemicolonAbbr(semiHook)
    enableOtherHotkey(thisHotkey)
    return


*3::
    thisHotkey := A_ThisHotkey
    disableOtherHotkey(thisHotkey)
    DigitMode := true
    keywait 3 
    DigitMode := false
    if (A_PriorKey == "3" && A_TimeSinceThisHotkey < 350)
        send {blind}3 
    enableOtherHotkey(thisHotkey)
    return

*9::
    thisHotkey := A_ThisHotkey
    disableOtherHotkey(thisHotkey)
    Mode9 := true
    keywait 9 
    Mode9 := false
    if (A_PriorKey == "9" && A_TimeSinceThisHotkey < 350)
        send {blind}9 
    enableOtherHotkey(thisHotkey)
    return

RButton::
enterRButtonMode()
{
	global RButtonMode
    thisHotkey := A_ThisHotkey
    RButtonMode := true
	timeOut = T0.01
	movedMouse := false
	MouseGetPos, initialX, initialY

	; 当按下右键时跑一个循环,  移动鼠标 / 弹起鼠标右键才能跳出这个循环
	keywait, RButton, %timeOut%
    while (errorlevel != 0)
    {
		MouseGetPos, x, y
		if (Abs(x - initialX) > 3 || Abs(y - initialY) > 3) {
			movedMouse := true
			break
		}
		keywait, RButton, %timeOut%
    }

    RButtonMode := false
	triggerOtherHotkey := thisHotkey != A_ThisHotkey
	Hotkey, %thisHotkey%, Off

	; 如果移动了鼠标,  那么按下鼠标右键,  以兼容其他软件的鼠标手势,  需要等待 RButton 弹起后才能重新启用热键
	if (!triggerOtherHotkey && movedMouse) {
		SendInput, {Blind}{RButton down}
		keywait, RButton
	} 
	else if (!triggerOtherHotkey) {
		SendInput, {Blind}{RButton}
	}
    ; 这里睡眠很重要, 否则会触发无限循环的 bug, 因为发送 RButton 触发 RButton 热键
    sleep, 70
	Hotkey, %thisHotkey%, On
    return

}


~LButton::
enterLButtonMode()
{
	global LButtonMode
    LButtonMode := true
    keywait LButton
    LButtonMode := false
    return
}

#if DisableCapslockKey
*capslock::return
*capslock up::return

#if JMode
*capslock::return
*capslock up::return
    ^l::return
    +k::return
    *k::
        send {blind}{Rshift down}
        keywait k
        send {Rshift up}
        return
    *l::
        send {blind}{Lctrl down}
        keywait l
        send {Lctrl up}
        return

{% for key,value in JMode.items()|sort(attribute="1.value") %}
    {% if value.value %}
{{{ value.prefix }}}{{{ escapeAhkHotkey(key) }}}::{{{ value.value }}}
    {% endif %}
{% endfor %}

    


#if PunctuationMode
{% for key,value in Semicolon.items()|sort(attribute="1.value") %}
    {% if value.value %}
{{{ value.prefix }}}{{{ escapeAhkHotkey(key) }}}::{{{ value.value }}}
    {% endif %}
{% endfor %}


#if DigitMode

{% for key,value in Mode3.items()|sort(attribute="1.value") %}
    {% if value.value %}
{{{ value.prefix }}}{{{ escapeAhkHotkey(key) }}}::{{{ value.value }}}
    {% endif %}
{% endfor %}

*r::
    DigitMode := false
    FnMode := true
    keywait r
    FnMode := false
    return

*2::send {blind}{backspace}

#if Mode9
{% for key,value in Mode9.items()|sort(attribute="1.value") %}
    {% if value.value %}
{{{ value.prefix }}}{{{ escapeAhkHotkey(key) }}}::{{{ value.value }}}
    {% endif %}
{% endfor %}

#if FnMode
*r::return

{% for key,value in Mode3R.items()|sort(attribute="1.value") %}
    {% if value.value %}
{{{ value.prefix }}}{{{ escapeAhkHotkey(key) }}}::{{{ value.value }}}
    {% endif %}
{% endfor %}


#if CapslockMode

{% for key,value in Capslock.items()|sort(attribute="1.value") %}
    {% if value.value %}
{{{ value.prefix }}}{{{ escapeAhkHotkey(key) }}}::{{{ value.value }}}
    {% endif %}
{% endfor %}


f::
    FMode := true
    CapslockMode := false
    SLOWMODE := false
    keywait f
    FMode := false
    return




#if SLOWMODE

{% for key,value in Capslock.items()|sort(attribute="1.value") %}
    {% if value.value and value.type == "鼠标操作" %}
{{{ value.prefix }}}{{{ escapeAhkHotkey(key) }}}::{{{ "rightClick(true)" if value.value == "rightClick()" else value.value | replace("fast", "slow") }}}
    {% endif %}
{% endfor %}


esc::exitMouseMode()
space::exitMouseMode()


#if FMode
f::return

{% for key,value in CapslockF.items()|sort(attribute="1.value") %}
    {% if value.value %}
{{{ value.prefix }}}{{{ escapeAhkHotkey(key) }}}::{{{ value.value }}}
    {% endif %}
{% endfor %}

#IfWinActive, ahk_exe explorer.exe ahk_class MultitaskingViewFrame
d::send, {blind}{down}
e::send, {blind}{up}
s::send, {blind}{left}
f::send, {blind}{right}
*x::send,  {blind}{del}
space::send, {blind}{enter}

#if LButtonMode
{% for key,value in LButtonMode.items()|sort(attribute="1.value") %}
    {% if value.value %}
{{{ value.prefix }}}{{{ escapeAhkHotkey(key) }}}::{{{ value.value }}}
    {% endif %}
{% endfor %}

#if RButtonMode
{% for key,value in RButtonMode.items()|sort(attribute="1.value") %}
    {% if value.value %}
{{{ value.prefix }}}{{{ escapeAhkHotkey(key) }}}::{{{ value.value }}}
    {% endif %}
{% endfor %}

LButton::send ^!{tab}
WheelUp::send ^+{tab}
WheelDown::send ^{tab}

#If




execSemicolonAbbr(typo) {
    switch typo 
    {
{% for key,value in SemicolonAbbr.items()|sort(attribute="1.value") %}
    {% if value.value %}
        case {{{ key|ahkString }}}:
            {{{ value.value }}}
    {% endif %}
{% endfor %}
        default: 
            return false
    }
    return true
}

execCapslockAbbr(typo) {
    switch typo 
    {
{% for key,value in CapslockAbbr.items()|sort(attribute="1.value") %}
    {% if value.value %}
        case {{{ key|ahkString }}}:
           {{{ value.value }}}
    {% endif %}
{% endfor %}
        default: 
            return false
    }
    return true
}

enterSemicolonAbbr(ih) 
{
    global DisableCapslockKey
    DisableCapslockKey := true

    typoTip.show("    ") 
    ih.Start()
    ih.Wait()
    ih.Stop()
    typoTip.hide()
    DisableCapslockKey := false


    if (ih.Match)
        execSemicolonAbbr(ih.Match)
}

onTypoChar(ih, char) {
    typoTip.show(ih.Input)
}

onTypoEnd(ih) {
    ; typoTip.show(ih.Input)
}
capsOnTypoChar(ih, char) {
    postCharToTipWidnow(char)
}

capsOnTypoEnd(ih) {
    ; typoTip.show(ih.Input)
}

enterCapslockAbbr(ih) 
{
    WM_USER := 0x0400
    SHOW_TYPO_WINDOW := WM_USER + 0x0001
    HIDE_TYPO_WINDOW := WM_USER + 0x0002

    postMessageToTipWidnow(SHOW_TYPO_WINDOW)
    result := ""


    ih.Start()
    endReason := ih.Wait()
    ih.Stop()
    if InStr(endReason, "EndKey") {
    }
    if InStr(endReason, "Match") {
        lastChar := SubStr(ih.Match, ih.Match.Length-1)
        postCharToTipWidnow(lastChar)
        SetTimer, delayedHideTipWindow, -50
    } else {
        postMessageToTipWidnow(HIDE_TYPO_WINDOW)
    }
    if (ih.Match)
        execCapslockAbbr(ih.Match)
}

delayedHideTipWindow()
{
    HIDE_TYPO_WINDOW := 0x0400 + 0x0002
    postMessageToTipWidnow(HIDE_TYPO_WINDOW)
}
