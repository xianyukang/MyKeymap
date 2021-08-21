#NoEnv
#SingleInstance Force
#MaxHotkeysPerInterval 200
#WinActivateForce               ; 解决「 winactivate 最小化的窗口时不会把窗口放到顶层(被其他窗口遮住) 」
#include keymap/functions.ahk

SetBatchLines -1
; ListLines Off
process, Priority,, H
SetWorkingDir %A_ScriptDir%\..
; 使用 sendinput 时,  通过 alt+3+j 输入 alt+1 时,  会发送 ctrl+alt
SendMode Input
; SetKeyDelay, 0
; SetMouseDelay, 0

SetMouseDelay, 0  ; 发送完一个鼠标后不会 sleep
SetDefaultMouseSpeed, 0
coordmode, mouse, screen
settitlematchmode, 2


rqeruireAdmin()
closeOldInstance()

SemicolonAbbrTip := true
time_enter_repeat = T0.2
delay_before_repeat = T0.01
fast_one := 110     
fast_repeat := 70
slow_one :=  10     
slow_repeat := 13

Menu, Tray, Icon, bin\logo.ico
Menu, Tray, Tip, MyKeymap 1.0 by 咸鱼康2333
processPath := getProcessPath()
SetWorkingDir, %processPath%


CoordMode, Mouse, Screen
; 多显示器不同缩放比例导致的问题,  https://www.autohotkey.com/boards/viewtopic.php?f=14&t=13810
DllCall("SetThreadDpiAwarenessContext", "ptr", -3, "ptr")


global typoTip := new TypoTipWindow()

semiHook := InputHook("C", "{Space}", {{{ SemicolonAbbrKeys|join(',')|ahkString }}})
semiHook.OnChar := Func("onTypoChar")
semiHook.OnEnd := Func("onTypoEnd")

return

RAlt::LCtrl
!'::ReloadProgram()
+capslock::toggleCapslock()

*capslock::
    CapslockMode := true
    keywait capslock
    CapslockMode := false
    if (A_PriorKey == "CapsLock" && A_TimeSinceThisHotkey < 450) {
        enterCapslockAbbr()
    }
    return


*j::
    ; hotkey, *capslock, off
    JMode := true
    keywait `j
    JMode := false
    if (A_PriorKey == "j" && A_TimeSinceThisHotkey < 350)
            send  {blind}`j
    ; hotkey, *capslock, on
    return


*`;::
    PunctuationMode := true
    keywait `; 
    PunctuationMode := false
    if (A_PriorKey == ";" && A_TimeSinceThisHotkey < 350)
        enterSemicolonAbbr(semiHook)
    return


*3::
    DigitMode := true
    keywait 3 
    DigitMode := false
    if (A_PriorKey == "3" && A_TimeSinceThisHotkey < 350)
        send {blind}3 
    return

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

*space::send  {blind}{enter}
    


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

*space::f1
*2::backspace


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


space::
    ; ShowDimmer()
    ShowCommandBar()
    return

f::
    hotkey, *`;, off
    FMode := true
    CapslockMode := false
    SLOWMODE := false
    keywait f
    FMode := false
    hotkey, *`;, on
    return




#if SLOWMODE

{% for key,value in Capslock.items()|sort(attribute="1.value") %}
    {% if value.value and value.type == "鼠标操作" %}
{{{ value.prefix }}}{{{ escapeAhkHotkey(key) }}}::{{{ value.value | replace("fast", "slow") }}}
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
r::tab
d::down
e::up
s::Left
f::Right
*x::
    if GetKeyState("`j", "P")  
        send {Esc}
    else
        send,  {blind}{del}
    return
space::enter


#IfWinActive



matchCapslockAbbr(typo) {
    
    arr := [ {{{ CapslockAbbrKeys|map('ahkString')|join(',') }}} ]

    return arrayContains(arr, typo)
}


matchSemicolonAbbr(typo) {
    
    arr := [ {{{ SemicolonAbbrKeys|map('ahkString')|join(',') }}} ]

    return arrayContains(arr, typo)
}

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
    typoTip.show("    ") 
    hotkey, *`j, off
    ih.Start()
    ih.Wait()
    ih.Stop()
    hotkey, *`j, on
    typoTip.hide()
    if (ih.Match)
        execSemicolonAbbr(ih.Match)
}

onTypoChar(ih, char) {
    typoTip.show(ih.Input)
}

onTypoEnd(ih) {
    ; typoTip.show(ih.Input)
}

enterCapslockAbbr() 
{
    WM_USER := 0x0400
    SHOW_TYPO_WINDOW := WM_USER + 0x0001
    HIDE_TYPO_WINDOW := WM_USER + 0x0002

    postMessageToTipWidnow(SHOW_TYPO_WINDOW)
    SoundPlay, D:\Downloads\QQ炫舞 音效\sound\bingo.wav
    result := ""

    hotkey, *`j, off
    Loop 
    {
        Input, key, L1, {LControl}{RControl}{LAlt}{RAlt}{Space}{Esc}{LWin}{RWin}{CapsLock}

        if InStr(ErrorLevel, "EndKey:") {
            SoundPlay, D:\Downloads\QQ炫舞 音效\sound\beatmiss.wav
            break
        }
        if (ErrorLevel == "NewInput") {
            break
        }
            
        typo := typo . key
        postCharToTipWidnow(key)
        SoundPlay, D:\Downloads\QQ炫舞 音效\sound\bingo.wav

        if matchCapslockAbbr(typo) {
            result := typo
            break
        }
    }
    hotkey, *`j, on

    typo := ""
    postMessageToTipWidnow(HIDE_TYPO_WINDOW)
    if (result) {
        if (StrLen(result) < 4) {
        } else {
            SoundPlay, D:\Downloads\QQ炫舞 音效\sound\cool.wav
            ; SoundPlay, D:\Downloads\QQ炫舞 音效\sound\perfect.wav
        }
        execCapslockAbbr(result)
    }
}