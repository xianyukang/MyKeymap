#NoEnv
#SingleInstance Force
#MaxHotkeysPerInterval 70
#NoTrayIcon
#WinActivateForce               ; 解决「 winactivate 最小化的窗口时不会把窗口放到顶层(被其他窗口遮住) 」
#InstallKeybdHook               ; 可能是 ahk 自动卸载 hook 导致的丢失 hook,  如果用这行指令, ahk 是否就不会卸载 hook 了呢?
#include bin/functions.ahk
#include bin/actions.ahk

{{ define "keymapToAhk" }}
{{- range toList . -}}
{{ .Prefix }}{{ escapeAhkHotkey .Key }}::{{ .Value }}
{{ end }}
{{ end }}

StringCaseSense, On
SetWorkingDir %A_ScriptDir%\..
{{ if .Settings.runAsAdmin -}}
requireAdmin()
{{- end }}
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

scrollOnceLineCount := {{ .Settings.scrollOnceLineCount }}
scrollDelay1 = {{ concat "T" .Settings.scrollDelay1 }}
scrollDelay2 = {{ concat "T" .Settings.scrollDelay2 }}

{{ if .Settings.showMouseMovePrompt }}
global mouseMovePrompt := newMouseMovePromptWindow()
{{ end }}

exitMouseModeAfterClick := {{ .Settings.exitMouseModeAfterClick }}
fastMoveSingle := {{ .Settings.fastMoveSingle }}
fastMoveRepeat := {{ .Settings.fastMoveRepeat }}
slowMoveSingle := {{ .Settings.slowMoveSingle }}
slowMoveRepeat := {{ .Settings.slowMoveRepeat }}
moveDelay1 = {{ concat "T" .Settings.moveDelay1 }}
moveDelay2 = {{ concat "T" .Settings.moveDelay2 }}

SemicolonAbbrTip := true
keymapLockState := {}

allHotkeys := []
{{ if .Settings.Mode3 }}allHotkeys.Push("*3"){{ end }}
{{ if .Settings.Mode9 }}allHotkeys.Push("*9"){{ end }}
{{ if .Settings.CommaMode }}allHotkeys.Push("*,"){{ end }}
{{ if .Settings.DotMode }}allHotkeys.Push("*."){{ end }}
{{ if .Settings.JMode }}allHotkeys.Push("*j"){{ end }}
{{ if .Settings.CapslockMode }}allHotkeys.Push("*capslock"){{ end }}
{{ if .Settings.SemicolonMode }}allHotkeys.Push("*;"){{ end }}
{{ if .Settings.LButtonMode }}allHotkeys.Push("~LButton"){{ end }}
{{ if .Settings.RButtonMode }}allHotkeys.Push("RButton"){{ end }}
{{ if .Settings.SpaceMode }}allHotkeys.Push("*Space"){{ end }}
{{ if .Settings.TabMode }}allHotkeys.Push("$Tab"){{ end }}

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
Menu, Tray, Tip, MyKeymap 1.2.5 by 咸鱼阿康
; processPath := getProcessPath()
; SetWorkingDir, %processPath%


CoordMode, Mouse, Screen
; 多显示器不同缩放比例导致的问题,  https://www.autohotkey.com/boards/viewtopic.php?f=14&t=13810
DllCall("SetThreadDpiAwarenessContext", "ptr", -3, "ptr")


global typoTip := new TypoTipWindow()

semiHook := InputHook("", "{CapsLock}{BackSpace}{Esc}{;}{Space}", {{ .SemicolonAbbrKeys|join ","|ahkString }})
semiHook.KeyOpt("{CapsLock}", "S")
semiHook.OnChar := Func("onSemiHookChar")
semiHook.OnEnd := Func("onSemiHookEnd")
capsHook := InputHook("", "{CapsLock}{BackSpace}{Esc}", {{ .CapslockAbbrKeys|join ","|ahkString }})
capsHook.KeyOpt("{CapsLock}", "S")
capsHook.OnChar := Func("onCapsHookChar")
capsHook.OnEnd := Func("onCapsHookEnd")

#include data/custom_functions.ahk
return

^F21::
    Suspend, Permit
    MyRun2(run_target, run_args, run_workingdir)
    ; tip(A_TickCount - run_start)
    Return
^F22::
    Suspend, Permit
    ActivateOrRun2(run_to_activate, run_target, run_args, run_workingdir, run_run_as_admin)
    ; tip(A_TickCount - run_start)
    Return

{{ .Settings.KeyMapping }}

{{ range toList .CustomHotkeys -}}
{{ if and .Key (or (contains .Value "toggleSuspend()") (contains .Value "ReloadProgram()")) -}}
{{ escapeAhkHotkey .Key }}::{{ .Value }}
{{- end }}
{{ end }}

{{ if .Settings.CapslockMode -}}
*capslock::
    thisHotkey := A_ThisHotkey
    disableOtherHotkey(thisHotkey)
    CapslockMode := true
    keymapLockState.currentMode := "CapslockMode"
    keywait capslock
    CapslockMode := false
    if (A_ThisHotkey == "*capslock" && A_PriorKey == "CapsLock" && A_TimeSinceThisHotkey < 450) {
        {{ (index .SpecialKeys "Caps Up").value }}
    }
    enableOtherHotkey(thisHotkey)
    return
{{ end }}


{{ if .Settings.JMode }}
*j::
    thisHotkey := A_ThisHotkey
    disableOtherHotkey(thisHotkey)
    JMode := true
    keymapLockState.currentMode := "JMode"
    DisableCapslockKey := true
    keywait j
    JMode := false
    DisableCapslockKey := false
    if (A_PriorKey == "j" && A_TimeSinceThisHotkey < 350)
            send,  {blind}j
    enableOtherHotkey(thisHotkey)
    return
{{ end }}


{{ if .Settings.SemicolonMode }}
*`;::
    thisHotkey := A_ThisHotkey
    disableOtherHotkey(thisHotkey)
    SemicolonMode := true
    keymapLockState.currentMode := "SemicolonMode"
    DisableCapslockKey := true
    keywait `; 
    SemicolonMode := false
    DisableCapslockKey := false
    if (A_PriorKey == ";" && A_TimeSinceThisHotkey < 250) {
         {{ (index .SpecialKeys "; Up").value }}
    }
    enableOtherHotkey(thisHotkey)
    return
{{ end }}

{{ if .Settings.Mode3 }}
*3::
    start_tick := A_TickCount
    thisHotkey := A_ThisHotkey
    disableOtherHotkey(thisHotkey)
    DigitMode := true
    keymapLockState.currentMode := "DigitMode"
    keywait 3 
    DigitMode := false
    if (A_PriorKey == "3" && (A_TickCount - start_tick < 250))
        send, {blind}3 
    enableOtherHotkey(thisHotkey)
    return
{{ end }}
{{ if .Settings.Mode9 }}
*9::
    thisHotkey := A_ThisHotkey
    disableOtherHotkey(thisHotkey)
    Mode9 := true
    keymapLockState.currentMode := "Mode9"
    keywait 9 
    Mode9 := false
    if (A_PriorKey == "9" && A_TimeSinceThisHotkey < 350)
        send, {blind}9 
    enableOtherHotkey(thisHotkey)
    return
{{ end }}

{{ if .Settings.CommaMode }}
*,::
    thisHotkey := A_ThisHotkey
    disableOtherHotkey(thisHotkey)
    CommaMode := true
    keymapLockState.currentMode := "CommaMode"
    keywait `, 
    CommaMode := false
    if (A_PriorKey == "," && A_TimeSinceThisHotkey < 350)
        send, {blind}`, 
    enableOtherHotkey(thisHotkey)
    return
{{ end }}

{{ if .Settings.DotMode }}
*.::
    thisHotkey := A_ThisHotkey
    disableOtherHotkey(thisHotkey)
    DotMode := true
    keymapLockState.currentMode := "DotMode"
    keywait `. 
    DotMode := false
    if (A_PriorKey == "." && A_TimeSinceThisHotkey < 350)
        sendevent, {blind}`. 
    enableOtherHotkey(thisHotkey)
    return
{{ end }}

{{ if .Settings.SpaceMode }}
*Space::
    thisHotkey := A_ThisHotkey
    disableOtherHotkey(thisHotkey)
    SpaceMode := true
    keymapLockState.currentMode := "SpaceMode"
    keywait Space 
    SpaceMode := false
    if (A_PriorKey == "Space" && A_TimeSinceThisHotkey < 350)
        send, {blind}{Space} 
    enableOtherHotkey(thisHotkey)
    return
{{ end }}

{{ if .Settings.TabMode }}
$Tab::
    thisHotkey := A_ThisHotkey
    disableOtherHotkey(thisHotkey)
    TabMode := true
    keymapLockState.currentMode := "TabMode"
    keywait Tab 
    TabMode := false
    if (A_PriorKey == "Tab" && A_TimeSinceThisHotkey < 350)
        send, {blind}{Tab} 
    enableOtherHotkey(thisHotkey)
    return
{{ end }}

{{ if .Settings.RButtonMode }}
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
{{ end }}


{{ if .Settings.LButtonMode }}
~LButton::
enterLButtonMode()
{
	global LButtonMode
    LButtonMode := true
    keywait LButton
    LButtonMode := false
    return
}
{{ end }}




{{ if .Settings.JMode }}
#if JModeK
k::return
{{ template "keymapToAhk" .JModeK }}
#if JMode
k::enterJModeK()
{{ template "keymapToAhk" .JMode }}
{{ end }}

{{ if .Settings.SemicolonMode }}
#if SemicolonMode
{{ template "keymapToAhk" .Semicolon }}
{{ end }}

{{ if .Settings.SpaceMode }}
#if SpaceMode
{{ template "keymapToAhk" .SpaceMode }}
{{ end }}

{{ if .Settings.TabMode }}
#if TabMode
{{ template "keymapToAhk" .TabMode }}
{{ end }}

{{ if .Settings.Mode3 }}
#if DigitMode
{{ template "keymapToAhk" .Mode3 }}
{{ end }}

{{ if .Settings.Mode9 }}
#if Mode9
{{ template "keymapToAhk" .Mode9 }}
{{ end }}

{{ if .Settings.CommaMode }}
#if CommaMode
{{ template "keymapToAhk" .CommaMode }}
{{ end }}

{{ if .Settings.DotMode }}
#if DotMode
{{ template "keymapToAhk" .DotMode }}
{{ end }}

{{ if .Settings.CapslockMode }}
#if CapslockMode
{{ template "keymapToAhk" .Capslock }}

{{ if .Settings.enableCapsF }}
f::
    FMode := true
    CapslockMode := false
    SLOWMODE := false
    keywait f
    FMode := false
    if keymapLockState.locked {
        CapslockMode := true
    }
    return
{{ end }}

{{ if .Settings.enableCapsSpace }}
space::
    CapslockSpaceMode := true
    CapslockMode := false
    SLOWMODE := false
    keywait space
    CapslockSpaceMode := false
    if keymapLockState.locked {
        CapslockMode := true
    }
    return
{{ end }}
{{- end }}

#if SLOWMODE
{{ template "keymapToAhk" .MouseMoveMode }}
Esc::exitMouseMode()
*Space::exitMouseMode()

{{ if .Settings.CapslockMode -}}
#if FMode
f::return
{{ template "keymapToAhk" .CapslockF }}

#if CapslockSpaceMode
space::return
{{ template "keymapToAhk" .CapslockSpace }}

#if DisableCapslockKey
*capslock::return
*capslock up::return
{{ end }}

{{ if .Settings.LButtonMode }}
#if LButtonMode
{{ template "keymapToAhk" .LButtonMode }}
{{ end }}

{{ if .Settings.RButtonMode }}
#if RButtonMode
{{ template "keymapToAhk" .RButtonMode }}
{{ end }}

#If TASK_SWITCH_MODE
{{ .Settings.windowSwitcherKeymap }}

#if !keymapIsActive
{{ range toList .CustomHotkeys -}}
{{ if and .Key (not (or (contains .Value "toggleSuspend()") (contains .Value "ReloadProgram()"))) -}}
{{ escapeAhkHotkey .Key }}::{{ .Value }}
{{- end }}
{{ end }}
#If




execSemicolonAbbr(typo) {
    switch typo 
    {
    {{ range toList .SemicolonAbbr -}}
        case {{ .Key|ahkString }}:
            {{ .Value }}
    {{ end -}}
        default:
            return false
    }
    return true
}

execCapslockAbbr(typo) {
    switch typo 
    {
    {{ range toList .CapslockAbbr -}}
        case {{ .Key|ahkString }}:
            {{ .Value }}
    {{ end -}}
        default:
            return false
    }
    return true
}




{{ .all_ahk_funcs|join "\n" }}

{{ range .send_key_functions -}}
{{ . }}
{{ end }}