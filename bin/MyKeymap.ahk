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
; requireAdmin()
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

semiHook := InputHook("C", "{Space}", "xk,ss,sk,sl,zk,dk,dh,jt,gt,lx,sm,zh,gg,ver,xm")
semiHook.OnChar := Func("onTypoChar")
semiHook.OnEnd := Func("onTypoEnd")
capsHook := InputHook("C", "{LControl}{RControl}{LAlt}{RAlt}{Space}{Esc}{LWin}{RWin}", "ss,sl,ex,rb,fp,fb,fg,dd,dp,dv,da,dr,se,no,sd,ld,we,st,dw,bb,gg,fr,fi,ee")
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

*Space::
send {blind}{enter}
return
*W::send {blind}+{tab}
*Z::send {blind}{appskey}
*C::send {blind}{backspace}
*V::send {blind}{delete}
*D::send {blind}{down}
*G::send {blind}{end}
*X::send {blind}{esc}
*A::send {blind}{home}
*I::send {blind}{insert}
*S::send {blind}{left}
*T::send {blind}{pgdn}
*Q::send {blind}{pgup}
*F::send {blind}{right}
*R::send {blind}{tab}
*E::send {blind}{up}

    


#if PunctuationMode
*A::
send {blind}*
return
*I::
send {blind}:
return
*Space::
send, {blind}{enter}
return
*U::send {blind}$
*R::send {blind}&
*Q::send {blind}(
*M::send {blind}-
*C::send {blind}.
*N::send {blind}/
*S::send {blind}<
*D::send {blind}=
*F::send {blind}>
*Y::send {blind}@
*Z::send {blind}\
*X::send {blind}_
*B::send {blind}`%
*H::send {blind}`;
*K::send {blind}``
*G::send {blind}{!}
*W::send {blind}{#}
*J::send {blind}{+}
*E::send {blind}{^}
*O::send {blind}{space 4}
*V::send {blind}|
*T::send {blind}~


#if DigitMode

*Space::
send, {blind}{f1}
return
*H::send {blind}0
*J::send {blind}1
*K::send {blind}2
*L::send {blind}3
*U::send {blind}4
*I::send {blind}5
*O::send {blind}6
*P::send {blind}7
*N::send {blind}8
*M::send {blind}9

*r::
    DigitMode := false
    FnMode := true
    keywait r
    FnMode := false
    return

*2::send {blind}{backspace}

#if Mode9
X::
    path = C:\Program Files\Microsoft Office\root\Office16\EXCEL.EXE
    ActivateOrRun("ahk_exe EXCEL.EXE", path, "", "")
    return
W::
    path = shortcuts\网易云音乐.lnk
    ActivateOrRun("网易云音乐", path, "", "")
    return

#if FnMode
*r::return

*H::send {blind}{f10}
*,::send {blind}{f11}
*/::send {blind}{f12}
*J::send {blind}{f1}
*K::send {blind}{f2}
*L::send {blind}{f3}
*U::send {blind}{f4}
*I::send {blind}{f5}
*O::send {blind}{f6}
*P::send {blind}{f7}
*N::send {blind}{f8}
*M::send {blind}{f9}


#if CapslockMode

*C::
send {blind}#{left}
return
*T::
send {blind}#{right}
return
S::center_window_to_current_monitor(1200, 800)
A::center_window_to_current_monitor(1370, 930)
/::centerMouse()
I::fastMoveMouse("I", 0, -1)
J::fastMoveMouse("J", -1, 0)
K::fastMoveMouse("K", 0, 1)
L::fastMoveMouse("L", 1, 0)
`;::horizontalScroll(";", 1)
H::horizontalScroll("H", -1)
,::lbuttonDown()
*N::leftClick()
*O::MouseClick, WheelDown, , , 1
*U::MouseClick, WheelUp, , , 1
M::rightClick()
W::send !{tab}
D::send #+{right}
E::send ^!{tab}
Y::send {LControl down}{LWin down}{Left}{LWin up}{LControl up}
P::send {LControl down}{LWin down}{Right}{LWin up}{LControl up}
X::SmartCloseWindow()
R::SwitchWindows()
Q::winmaximize, A
B::winMinimizeIgnoreDesktop()


f::
    FMode := true
    CapslockMode := false
    SLOWMODE := false
    keywait f
    FMode := false
    return




#if SLOWMODE

/::centerMouse()
I::slowMoveMouse("I", 0, -1)
J::slowMoveMouse("J", -1, 0)
K::slowMoveMouse("K", 0, 1)
L::slowMoveMouse("L", 1, 0)
`;::horizontalScroll(";", 1)
H::horizontalScroll("H", -1)
,::lbuttonDown()
*N::leftClick()
*O::MouseClick, WheelDown, , , 1
*U::MouseClick, WheelUp, , , 1
M::rightClick(true)


esc::exitMouseMode()
space::exitMouseMode()


#if FMode
f::return

L::
    path = %A_ProgramFiles%\DAUM\PotPlayer\PotPlayerMini64.exe
    ActivateOrRun("ahk_class PotPlayer64", path)
    return
Q::
    path = %A_ProgramFiles%\Everything\Everything.exe
    ActivateOrRun("ahk_class EVERYTHING", path)
    return
U::
    path = %A_Programs%\JetBrains Toolbox\DataGrip.lnk
    ActivateOrRun("ahk_exe datagrip64.exe", path)
    return
J::
    path = %A_Programs%\JetBrains Toolbox\IntelliJ IDEA Ultimate.lnk
    ActivateOrRun("ahk_exe idea64.exe", path)
    return
S::
    path = %A_Programs%\Visual Studio Code\Visual Studio Code.lnk
    ActivateOrRun("ahk_exe Code.exe", path)
    return
W::
    path = %A_ProgramsCommon%\Google Chrome.lnk
    ActivateOrRun("ahk_exe chrome.exe", path)
    return
D::
    path = %A_ProgramsCommon%\Microsoft Edge.lnk
    ActivateOrRun("ahk_exe msedge.exe", path)
    return
H::
    path = %A_ProgramsCommon%\Visual Studio 2019.lnk
    ActivateOrRun("- Microsoft Visual Studio", path)
    return
P::
    path = %A_StartMenuCommon%\Programs\paint.net.lnk
    ActivateOrRun("ahk_exe PaintDotNet.exe", path, "", "")
    return
E::
    path = C:\Program Files (x86)\Yinxiang Biji\印象笔记\Evernote.exe
    ActivateOrRun("ahk_class YXMainFrame", path)
    return
I::
    path = C:\Program Files\Typora\Typora.exe
    ActivateOrRun("ahk_exe Typora.exe", path)
    return
Z::
    path = D:\
    ActivateOrRun("ahk_class CabinetWClass ahk_exe Explorer.EXE", path)
    return
R::
    path = D:\install\Foxit Reader\FoxitReader.exe
    ActivateOrRun("ahk_exe FoxitReader.exe", path)
    return
N::
    path = D:\MyFiles\MyKeymap\shortcuts\网易云音乐.lnk
    ActivateOrRun("", path, "", "")
    return
O::
    path = shortcuts\OneNote for Windows 10.lnk
    ActivateOrRun("OneNote for Windows 10", path)
    return
A::
    path = shortcuts\Windows Terminal Preview.lnk
    ActivateOrRun("ahk_exe WindowsTerminal.exe", path)
    return

#IfWinActive, ahk_exe explorer.exe ahk_class MultitaskingViewFrame
d::send, {blind}{down}
e::send, {blind}{up}
s::send, {blind}{left}
f::send, {blind}{right}
*x::send,  {blind}{del}
space::send, {blind}{enter}

#if LButtonMode
*S::
send {blind}^#{Left}
return
*F::
send {blind}^#{Right}
return

#if RButtonMode
*Z::
send {blind}#v
return
*W::
send {blind}^c
return
*R::
send {blind}^v
return
*X::
send {blind}^x
return
*Space::
send {blind}{enter}
return
*C::send {blind}{backspace}
*V::send {blind}{delete}
*D::send {blind}{down}
*G::send {blind}{end}
*A::send {blind}{home}
*S::send {blind}{left}
*T::send {blind}{pgdn}
*Q::send {blind}{pgup}
*F::send {blind}{right}
*E::send {blind}{up}

LButton::send ^!{tab}
WheelUp::send ^+{tab}
WheelDown::send ^{tab}

#If




execSemicolonAbbr(typo) {
    switch typo 
    {
        case "ver":
            
send, {blind}#r
             sleep 700
send, {blind}winver{enter}
return
        case "xk":
            
send, {blind}(){left 1}
return
        case "gg":
            
send, {blind}{text}git add -A`; git commit -a -m ""`; git push origin (git branch --show-current)`;
send, {blind}{left 47}
return
        case "dk":
            
send, {blind}{text}{}
send, {blind}{left}
return
        case "xm":
            
send, {blind}{text}❖` ` 
return
        case "zh":
            send % text(" site:zhihu.com")
send {blind}{enter}
        case "ss":
            send {blind}""{left}
        case "zk":
            send {blind}[]{left}
        case "jt":
            send {blind}➤{space 1}
        case "dh":
            send {blind}、
        case "sm":
            send {blind}《》{left}
        case "sk":
            send {blind}「  」{left 2}
        case "sl":
            send {blind}【】{left 1}
        case "gt":
            send {blind}🐶
        case "lx":
            send {blind}💚
        default: 
            return false
    }
    return true
}

execCapslockAbbr(typo) {
    switch typo 
    {
        case "bb":
           
    path = C:\Program Files\Google\Chrome\Application\chrome.exe
    ActivateOrRun("Bing 词典", path, "--app=https://cn.bing.com/dict/search?q=nice", "")
    return
        case "gg":
           
    path = C:\Program Files\Google\Chrome\Application\chrome.exe
    ActivateOrRun("Google 翻译", path, "--app=https://translate.google.cn/?op=translate&sl=auto&tl=zh-CN&text=nice", "")
    return
        case "no":
           
    path = notepad.exe
    ActivateOrRun("记事本", path, "", "")
    return
        case "st":
           
    path = shortcuts\Store.lnk
    ActivateOrRun("Microsoft Store", path, "", "")
    return
        case "we":
           
    path = shortcuts\网易云音乐.lnk
    ActivateOrRun("网易云音乐", path)
    return
        case "sl":
           DllCall("PowrProf\SetSuspendState", "Int", 0, "Int", 0, "Int", 0)
        case "se":
           openSettings()
        case "ex":
           quit(false)
        case "da":
           run, %A_WorkingDir%
        case "ld":
           run, bin\ahk.exe bin\changeBrightness.ahk
        case "sd":
           run, bin\ahk.exe bin\soundControl.ahk
        case "dd":
           run, shell:downloads
        case "dp":
           run, shell:my pictures
        case "dv":
           run, shell:My Video
        case "dw":
           run, shell:Personal
        case "dr":
           run, shell:RecycleBinFolder
        case "fg":
           setColor("#080")
        case "fb":
           setColor("#2E66FF")
        case "fp":
           setColor("#b309bb")
        case "fr":
           setColor("#D05")
        case "fi":
           setColor("#FF00FF")
        case "rb":
           slideToReboot()
        case "ss":
           slideToShutdown()
        case "ee":
           ToggleTopMost()
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
