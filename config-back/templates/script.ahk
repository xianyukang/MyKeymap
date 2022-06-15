#NoEnv
#SingleInstance Force
#MaxHotkeysPerInterval 70
#NoTrayIcon
#WinActivateForce               ; 解决「 winactivate 最小化的窗口时不会把窗口放到顶层(被其他窗口遮住) 」
#InstallKeybdHook               ; 可能是 ahk 自动卸载 hook 导致的丢失 hook,  如果用这行指令, ahk 是否就不会卸载 hook 了呢?
#include bin/functions.ahk
#include bin/actions.ahk

{## 定义可重用的模板,  减少代码重复 ##}
{% macro keymapToAhk(keymap) %}
{% for key,value in keymap.items()|sort(attribute="1.value") %}
    {% if value.value %}
{{{ value.prefix }}}{{{ escapeAhkHotkey(key) }}}::{{{ value.value }}}
    {% endif %}
{% endfor %}
{% endmacro %}

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

; win10、win11 任务切换、任务视图
GroupAdd, TASK_SWITCH_GROUP, ahk_class MultitaskingViewFrame
GroupAdd, TASK_SWITCH_GROUP, ahk_class XamlExplorerHostIslandWindow

scrollOnceLineCount := {{{ Settings.scrollOnceLineCount if Settings.scrollOnceLineCount else 3 }}}
scrollDelay1 = {{{ "T" + Settings.scrollDelay1 if Settings.scrollDelay1 else "T0.2" }}}
scrollDelay2 = {{{ "T" + Settings.scrollDelay2 if Settings.scrollDelay2 else "T0.03" }}}

{% if Settings.showMouseMovePrompt %}
global mouseMovePrompt := newMouseMovePromptWindow()
{% endif %}
fastMoveSingle := {{{ Settings.fastMoveSingle if Settings.fastMoveSingle else 110 }}}
fastMoveRepeat := {{{ Settings.fastMoveRepeat if Settings.fastMoveRepeat else 70 }}}
slowMoveSingle := {{{ Settings.slowMoveSingle if Settings.slowMoveSingle else 10 }}}
slowMoveRepeat := {{{ Settings.slowMoveRepeat if Settings.slowMoveRepeat else 13 }}}
moveDelay1 = {{{ "T" + Settings.moveDelay1 if Settings.moveDelay1 else "T0.2" }}}
moveDelay2 = {{{ "T" + Settings.moveDelay2 if Settings.moveDelay2 else "T0.01" }}}

SemicolonAbbrTip := true

allHotkeys := []
{% if Settings.Mode3 %}
allHotkeys.Push("*3")
{% endif %}
{% if Settings.Mode9 %}
allHotkeys.Push("*9")
{% endif %}
{% if Settings.CommaMode %}
allHotkeys.Push("*,")
{% endif %}
{% if Settings.DotMode %}
allHotkeys.Push("*.")
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
{% if Settings.TabMode %}
allHotkeys.Push("$Tab")
{% endif %}

Menu, Tray, NoStandard
Menu, Tray, Add, 暂停, trayMenuHandler
Menu, Tray, Add, 退出, trayMenuHandler
Menu, Tray, Add, 重启程序, trayMenuHandler
Menu, Tray, Add, 打开设置, trayMenuHandler 
Menu, Tray, Add, 帮助文档, trayMenuHandler 
Menu, Tray, Add, 查看窗口标识符, trayMenuHandler 
Menu, Tray, Default, 暂停
Menu, Tray, Click, 1
Menu, Tray, Add 

Menu, Tray, Icon
Menu, Tray, Icon, bin\logo.ico,, 1
Menu, Tray, Tip, MyKeymap 1.1 by 咸鱼阿康
; processPath := getProcessPath()
; SetWorkingDir, %processPath%


CoordMode, Mouse, Screen
; 多显示器不同缩放比例导致的问题,  https://www.autohotkey.com/boards/viewtopic.php?f=14&t=13810
DllCall("SetThreadDpiAwarenessContext", "ptr", -3, "ptr")


global typoTip := new TypoTipWindow()

semiHook := InputHook("C", "{CapsLock}{Space}{BackSpace}{Esc}", {{{ SemicolonAbbrKeys|join(',')|ahkString }}})
semiHook.KeyOpt("{CapsLock}", "S")
semiHook.OnChar := Func("onSemiHookChar")
semiHook.OnEnd := Func("onSemiHookEnd")
capsHook := InputHook("", "{CapsLock}{BackSpace}{Esc}", {{{ CapslockAbbrKeys|join(',')|ahkString }}})
capsHook.KeyOpt("{CapsLock}", "S")
capsHook.OnChar := Func("onCapsHookChar")
capsHook.OnEnd := Func("onCapsHookEnd")

#include data/custom_functions.ahk
return

{% if Settings.mapRAltToCtrl %}
RAlt::LCtrl
{% endif %}

!F21::
    Suspend, Permit
    MyRun2(run_target, run_args, run_workingdir)
    ; tip(A_TickCount - run_start)
    Return
!F22::
    Suspend, Permit
    ActivateOrRun2(run_to_activate, run_target, run_args, run_workingdir)
    ; tip(A_TickCount - run_start)
    Return

{% for key,value in CustomHotkeys.items()|sort(attribute="1.value") %}
    {% if value.value %}
{{{ escapeAhkHotkey(key) }}}::{{{ value.value }}}
    {% endif %}
{% endfor %}

{% if Settings.CapslockMode %}
*capslock::
    thisHotkey := A_ThisHotkey
    disableOtherHotkey(thisHotkey)
    CapslockMode := true
    keywait capslock
    CapslockMode := false
    if (A_ThisHotkey == "*capslock" && A_PriorKey == "CapsLock" && A_TimeSinceThisHotkey < 450) {
        {{{ SpecialKeys["Caps Up"].value }}}
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
            send,  {blind}j
    enableOtherHotkey(thisHotkey)
    return
{% endif %}


{% if Settings.SemicolonMode %}
*`;::
    thisHotkey := A_ThisHotkey
    disableOtherHotkey(thisHotkey)
    PunctuationMode := true
    DisableCapslockKey := true
    keywait `; 
    PunctuationMode := false
    DisableCapslockKey := false
    if (A_PriorKey == ";" && A_TimeSinceThisHotkey < 350) {
         {{{ SpecialKeys["; Up"].value }}}       
    }
    enableOtherHotkey(thisHotkey)
    return
{% endif %}

{% if Settings.Mode3 %}
*3::
    start_tick := A_TickCount
    thisHotkey := A_ThisHotkey
    disableOtherHotkey(thisHotkey)
    DigitMode := true
    keywait 3 
    DigitMode := false
    if (A_PriorKey == "3" && (A_TickCount - start_tick < 250))
        send, {blind}3 
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
        send, {blind}9 
    enableOtherHotkey(thisHotkey)
    return
{% endif %}

; RAlt::
;     disableOtherHotkey(thisHotkey)
;     CommaMode := true
;     keywait RAlt
;     CommaMode := false
;     enableOtherHotkey(thisHotkey)
;     return
{% if Settings.CommaMode %}
*,::
    thisHotkey := A_ThisHotkey
    disableOtherHotkey(thisHotkey)
    CommaMode := true
    keywait `, 
    CommaMode := false
    if (A_PriorKey == "," && A_TimeSinceThisHotkey < 350)
        send, {blind}`, 
    enableOtherHotkey(thisHotkey)
    return
{% endif %}

{% if Settings.DotMode %}
*.::
    thisHotkey := A_ThisHotkey
    disableOtherHotkey(thisHotkey)
    DotMode := true
    keywait `. 
    DotMode := false
    if (A_PriorKey == "." && A_TimeSinceThisHotkey < 350)
        send, {blind}`. 
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
        send, {blind}{Space} 
    enableOtherHotkey(thisHotkey)
    return
{% endif %}

{% if Settings.TabMode %}
$Tab::
    thisHotkey := A_ThisHotkey
    disableOtherHotkey(thisHotkey)
    TabMode := true
    keywait Tab 
    TabMode := false
    if (A_PriorKey == "Tab" && A_TimeSinceThisHotkey < 350)
        send, {blind}{Tab} 
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


#if JModeK
k::return
{{{ keymapToAhk(JModeK) }}}

#if JMode
k::enterJModeK()
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

{% if Settings.TabMode %}
#if TabMode
{% for key,value in TabMode.items()|sort(attribute="1.value") %}
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

{% endif %}


{% if Settings.Mode9 %}
#if Mode9
{% for key,value in Mode9.items()|sort(attribute="1.value") %}
    {% if value.value %}
{{{ value.prefix }}}{{{ escapeAhkHotkey(key) }}}::{{{ value.value }}}
    {% endif %}
{% endfor %}
{% endif %}

{% if Settings.CommaMode %}
#if CommaMode
{{{ keymapToAhk(CommaMode) }}}
{% endif %}

{% if Settings.DotMode %}
#if DotMode
{{{ keymapToAhk(DotMode) }}}
{% endif %}


{% if Settings.CapslockMode %}
#if CapslockMode

{% for key,value in Capslock.items()|sort(attribute="1.value") %}
    {% if value.value %}
{{{ value.prefix }}}{{{ escapeAhkHotkey(key) }}}::{{{ value.value }}}
    {% endif %}
{% endfor %}


{% if Settings.enableCapsF %}
f::
    FMode := true
    CapslockMode := false
    SLOWMODE := false
    keywait f
    FMode := false
    return
{% endif %}

{% if Settings.enableCapsSpace %}
space::
    CapslockSpaceMode := true
    CapslockMode := false
    SLOWMODE := false
    keywait space
    CapslockSpaceMode := false
    return
{% endif %}

#if SLOWMODE
{% for key,value in MouseMoveMode.items()|sort(attribute="1.value") %}
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

{% endif %}

{% if Settings.CapslockMode %}
#If TASK_SWITCH_MODE
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




{{{ all_ahk_funcs|join('\n') }}}

{% for value in send_key_functions %}
{{{ value }}}
{% endfor %}