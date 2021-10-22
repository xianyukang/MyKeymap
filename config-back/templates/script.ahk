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
{% if Settings.runAsAdmin %}
requireAdmin()
{% endif %}
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


scrollOnceLineCount := {{{ Settings.scrollOnceLineCount if Settings.scrollOnceLineCount else 3 }}}
scrollDelay1 = {{{ "T" + Settings.scrollDelay1 if Settings.scrollDelay1 else "T0.2" }}}
scrollDelay2 = {{{ "T" + Settings.scrollDelay2 if Settings.scrollDelay2 else "T0.03" }}}

fastMoveSingle := {{{ Settings.fastMoveSingle if Settings.fastMoveSingle else 110 }}}
fastMoveRepeat := {{{ Settings.fastMoveRepeat if Settings.fastMoveRepeat else 70 }}}
slowMoveSingle := {{{ Settings.slowMoveSingle if Settings.slowMoveSingle else 10 }}}
slowMoveRepeat := {{{ Settings.slowMoveRepeat if Settings.slowMoveRepeat else 13 }}}
moveDelay1 = {{{ "T" + Settings.moveDelay1 if Settings.moveDelay1 else "T0.2" }}}
moveDelay2 = {{{ "T" + Settings.moveDelay2 if Settings.moveDelay2 else "T0.01" }}}

SemicolonAbbrTip := true
; time_enter_repeat = T0.2
; delay_before_repeat = T0.01
; fast_one := 110     
; fast_repeat := 70
; slow_one :=  10     
; slow_repeat := 13

allHotkeys := []
{% if Settings.Mode3 %}
allHotkeys.Push("*3")
{% endif %}
{% if Settings.Mode9 %}
allHotkeys.Push("*9")
{% endif %}
{% if Settings.JMode %}
allHotkeys.Push("*j")
{% endif %}
{% if Settings.CapslockMode %}
allHotkeys.Push("*capslock")
{% endif %}
{% if Settings.SemicolonMode %}
allHotkeys.Push("*;")
{% endif %}
{% if Settings.LButtonMode %}
allHotkeys.Push("~LButton")
{% endif %}
{% if Settings.RButtonMode %}
allHotkeys.Push("RButton")
{% endif %}
{% if Settings.SpaceMode %}
allHotkeys.Push("*Space")
{% endif %}

Menu, Tray, NoStandard
Menu, Tray, Add, 暂停, trayMenuHandler
Menu, Tray, Add, 退出, trayMenuHandler
Menu, Tray, Add, 打开设置, trayMenuHandler 
Menu, Tray, Add, 视频教程, trayMenuHandler
Menu, Tray, Add, 帮助文档, trayMenuHandler 
Menu, Tray, Add, 检查更新, trayMenuHandler 
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

semiHook := InputHook("C", "{Space}{BackSpace}{Esc}", {{{ SemicolonAbbrKeys|join(',')|ahkString }}})
semiHook.OnChar := Func("onTypoChar")
semiHook.OnEnd := Func("onTypoEnd")
capsHook := InputHook("C", "{Space}{BackSpace}{Esc}", {{{ CapslockAbbrKeys|join(',')|ahkString }}})
capsHook.OnChar := Func("capsOnTypoChar")
capsHook.OnEnd := Func("capsOnTypoEnd")

return

{% if Settings.mapRAltToCtrl %}
RAlt::LCtrl
{% endif %}

!+'::
    Suspend, Permit
    toggleSuspend()
    return
!'::
    Suspend, Toggle
    ReloadProgram()
    return

{% if Settings.CapslockMode %}
+capslock::toggleCapslock()

*capslock::
    thisHotkey := A_ThisHotkey
    disableOtherHotkey(thisHotkey)
    CapslockMode := true
    keywait capslock
    CapslockMode := false
    if (A_ThisHotkey == "*capslock" && A_PriorKey == "CapsLock" && A_TimeSinceThisHotkey < 450) {
        enterCapslockAbbr(capsHook)
    }
    enableOtherHotkey(thisHotkey)
    return
{% endif %}


{% if Settings.JMode %}
*j::
    thisHotkey := A_ThisHotkey
    disableOtherHotkey(thisHotkey)
    JMode := true
    DisableCapslockKey := true
    keywait j
    JMode := false
    DisableCapslockKey := false
    if (A_PriorKey == "j" && A_TimeSinceThisHotkey < 350)
            send  {blind}j
    enableOtherHotkey(thisHotkey)
    return
{% endif %}


{% if Settings.SemicolonMode %}
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
{% endif %}

{% if Settings.Mode3 %}
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
{% endif %}
{% if Settings.Mode9 %}
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
{% endif %}

{% if Settings.SpaceMode %}
*Space::
    thisHotkey := A_ThisHotkey
    disableOtherHotkey(thisHotkey)
    SpaceMode := true
    keywait Space 
    SpaceMode := false
    if (A_PriorKey == "Space" && A_TimeSinceThisHotkey < 350)
        send {blind}{Space} 
    enableOtherHotkey(thisHotkey)
    return
{% endif %}

{% if Settings.RButtonMode %}
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
		if (Abs(x - initialX) > 20 || Abs(y - initialY) > 20) {
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
{% endif %}


{% if Settings.LButtonMode %}
~LButton::
enterLButtonMode()
{
	global LButtonMode
    LButtonMode := true
    keywait LButton
    LButtonMode := false
    return
}
{% endif %}




{% if Settings.JMode %}
#if JMode
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
{% endif %}

    

{% if Settings.SemicolonMode %}
#if PunctuationMode
{% for key,value in Semicolon.items()|sort(attribute="1.value") %}
    {% if value.value %}
{{{ value.prefix }}}{{{ escapeAhkHotkey(key) }}}::{{{ value.value }}}
    {% endif %}
{% endfor %}
{% endif %}

{% if Settings.SpaceMode %}
#if SpaceMode
{% for key,value in SpaceMode.items()|sort(attribute="1.value") %}
    {% if value.value %}
{{{ value.prefix }}}{{{ escapeAhkHotkey(key) }}}::{{{ value.value }}}
    {% endif %}
{% endfor %}
{% endif %}


{% if Settings.Mode3 %}
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


#if FnMode
*r::return

{% for key,value in Mode3R.items()|sort(attribute="1.value") %}
    {% if value.value %}
{{{ value.prefix }}}{{{ escapeAhkHotkey(key) }}}::{{{ value.value }}}
    {% endif %}
{% endfor %}
{% endif %}


{% if Settings.Mode9 %}
#if Mode9
{% for key,value in Mode9.items()|sort(attribute="1.value") %}
    {% if value.value %}
{{{ value.prefix }}}{{{ escapeAhkHotkey(key) }}}::{{{ value.value }}}
    {% endif %}
{% endfor %}
{% endif %}


{% if Settings.CapslockMode %}
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
space::
    CapslockSpaceMode := true
    CapslockMode := false
    SLOWMODE := false
    keywait space
    CapslockSpaceMode := false
    return

WheelUp::send {blind}^#{left}
WheelDown::send {blind}^#{right}

#if SLOWMODE

{% for key,value in Capslock.items()|sort(attribute="1.value") %}
    {% if value.value and value.type == "鼠标操作" %}
{{{ value.prefix }}}{{{ escapeAhkHotkey(key) }}}::{{{ "rightClick(true)" if value.value == "rightClick()" else value.value | replace("fast", "slow") }}}
    {% endif %}
{% endfor %}


Esc::exitMouseMode()
*Space::exitMouseMode()


#if FMode
f::return

{% for key,value in CapslockF.items()|sort(attribute="1.value") %}
    {% if value.value %}
{{{ value.prefix }}}{{{ escapeAhkHotkey(key) }}}::{{{ value.value }}}
    {% endif %}
{% endfor %}

#if CapslockSpaceMode
space::return

{% for key,value in CapslockSpace.items()|sort(attribute="1.value") %}
    {% if value.value %}
{{{ value.prefix }}}{{{ escapeAhkHotkey(key) }}}::{{{ value.value }}}
    {% endif %}
{% endfor %}


#if DisableCapslockKey
*capslock::return
*capslock up::return
{% endif %}

{% if Settings.LButtonMode %}
#if LButtonMode
{% for key,value in LButtonMode.items()|sort(attribute="1.value") %}
    {% if value.value %}
{{{ value.prefix }}}{{{ escapeAhkHotkey(key) }}}::{{{ value.value }}}
    {% endif %}
{% endfor %}
{% endif %}

{% if Settings.RButtonMode %}
#if RButtonMode
{% for key,value in RButtonMode.items()|sort(attribute="1.value") %}
    {% if value.value %}
{{{ value.prefix }}}{{{ escapeAhkHotkey(key) }}}::{{{ value.value }}}
    {% endif %}
{% endfor %}

LButton::
; if WinActive("ahk_class MultitaskingViewFrame")
if ( A_PriorHotkey == "~LButton" || A_PriorHotkey == "LButton")
    send #{tab}
else
    send ^!{tab}
return
WheelUp::send ^+{tab}
WheelDown::send ^{tab}
{% endif %}

{% if Settings.CapslockMode %}
#IfWinActive, ahk_class MultitaskingViewFrame
*D::send, {blind}{down}
*E::send, {blind}{up}
*S::send, {blind}{left}
*F::send, {blind}{right}
*X::send,  {blind}{del}
*Space::send, {blind}{enter}
{% endif %}
#If




execSemicolonAbbr(typo) {
    switch typo 
    {
{% if Settings.SemicolonMode %}
{% for key,value in SemicolonAbbr.items()|sort(attribute="1.value") %}
    {% if value.value %}
        case {{{ key|ahkString }}}:
            {{{ value.value }}}
    {% endif %}
{% endfor %}
{% endif %}
        default: 
            return false
    }
    return true
}

execCapslockAbbr(typo) {
    switch typo 
    {
{% if Settings.CapslockMode %}
{% for key,value in CapslockAbbr.items()|sort(attribute="1.value") %}
    {% if value.value %}
        case {{{ key|ahkString }}}:
           {{{ value.value }}}
    {% endif %}
{% endfor %}
{% endif %}
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
