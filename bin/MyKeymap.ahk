#NoEnv
#SingleInstance Force
#MaxHotkeysPerInterval 70
#NoTrayIcon
#WinActivateForce               ; 解决「 winactivate 最小化的窗口时不会把窗口放到顶层(被其他窗口遮住) 」
#InstallKeybdHook               ; 可能是 ahk 自动卸载 hook 导致的丢失 hook,  如果用这行指令, ahk 是否就不会卸载 hook 了呢?
#include bin/functions.ahk
#include bin/actions.ahk



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

; win10、win11 任务切换、任务视图
GroupAdd, TASK_SWITCH_GROUP, ahk_class MultitaskingViewFrame
GroupAdd, TASK_SWITCH_GROUP, ahk_class XamlExplorerHostIslandWindow
GroupAdd, window_group_3, ahk_exe explorer.exe
GroupAdd, window_group_4, ahk_exe chrome.exe
GroupAdd, window_group_4, ahk_exe msedge.exe
GroupAdd, window_group_4, ahk_exe firefox.exe


scrollOnceLineCount := 1
scrollDelay1 = T0.2
scrollDelay2 = T0.03



exitMouseModeAfterClick := true
fastMoveSingle := 110
fastMoveRepeat := 70
slowMoveSingle := 10
slowMoveRepeat := 13
moveDelay1 = T0.13
moveDelay2 = T0.01

SemicolonAbbrTip := true
keymapLockState := {}

allHotkeys := []
allHotkeys.Push("*3")


allHotkeys.Push("*.")
allHotkeys.Push("*j")
allHotkeys.Push("*capslock")
allHotkeys.Push("*;")

allHotkeys.Push("RButton")





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
Menu, Tray, Tip, MyKeymap 1.2.7 by 咸鱼阿康
; processPath := getProcessPath()
; SetWorkingDir, %processPath%


CoordMode, Mouse, Screen
; 多显示器不同缩放比例导致的问题,  https://www.autohotkey.com/boards/viewtopic.php?f=14&t=13810
DllCall("SetThreadDpiAwarenessContext", "ptr", -3, "ptr")


global typoTip := new TypoTipWindow()

semiHook := InputHook("", "{CapsLock}{BackSpace}{Esc}{;}{Space}", ",,,.,/,blu,dh,dk,dq,fs,gg,gre,gt,jt,kg,pin,pur,red,sj,sk,ss,ver,xk,year,zh,zk")
semiHook.KeyOpt("{CapsLock}", "S")
semiHook.OnChar := Func("onSemiHookChar")
semiHook.OnEnd := Func("onSemiHookEnd")
capsHook := InputHook("", "{CapsLock}{BackSpace}{Esc}", "acmd,bb,bd ,dd,dm,ex,gg,gj,help,ld,lj,ly,mm,ms,no,rb,rex,se,sl,sp,st,tm,we")
capsHook.KeyOpt("{CapsLock}", "S")
capsHook.OnChar := Func("onCapsHookChar")
capsHook.OnEnd := Func("onCapsHookEnd")

#include data/custom_functions.ahk
return

^F21::
    Suspend, Permit
    MyRun2(run_target, run_args, run_workingdir)
    Return
^F22::
    Suspend, Permit
    ActivateOrRun2(run_to_activate, run_target, run_args, run_workingdir, run_run_as_admin)
    Return

RAlt::LCtrl


+!'::
Suspend, Permit
toggleSuspend()
return
!'::
Suspend, Toggle
ReloadProgram()
return





*capslock::
    start_tick := A_TickCount
    thisHotkey := A_ThisHotkey
    disableOtherHotkey(thisHotkey)
    CapslockMode := true
    ResetCurrentModeLockState("CapslockMode")
    keywait capslock
    CapslockMode := false
    if (A_ThisHotkey = "*capslock" && A_PriorKey = "CapsLock" && (A_TickCount - start_tick < 350)) {
        enterCapslockAbbr()
    }
    enableOtherHotkey(thisHotkey)
    return




*j::
    start_tick := A_TickCount
    thisHotkey := A_ThisHotkey
    disableOtherHotkey(thisHotkey)
    JMode := true
    ResetCurrentModeLockState("JMode")
    DisableCapslockKey := true
    keywait j
    JMode := false
    DisableCapslockKey := false
    if (A_PriorKey = "j" && (A_TickCount - start_tick < 300))
            send,  {blind}j
    enableOtherHotkey(thisHotkey)
    return




*`;::
    start_tick := A_TickCount
    thisHotkey := A_ThisHotkey
    disableOtherHotkey(thisHotkey)
    SemicolonMode := true
    ResetCurrentModeLockState("SemicolonMode")
    DisableCapslockKey := true
    keywait `; 
    SemicolonMode := false
    DisableCapslockKey := false
    if (A_PriorKey = ";" && (A_TickCount - start_tick < 300)) {
         enterSemicolonAbbr()
    }
    enableOtherHotkey(thisHotkey)
    return



*3::
    start_tick := A_TickCount
    thisHotkey := A_ThisHotkey
    disableOtherHotkey(thisHotkey)
    Mode3 := true
    ResetCurrentModeLockState("Mode3")
    keywait 3 
    Mode3 := false
    if (A_PriorKey = "3" && (A_TickCount - start_tick < 300))
        send, {blind}3 
    enableOtherHotkey(thisHotkey)
    return






*.::
    start_tick := A_TickCount
    thisHotkey := A_ThisHotkey
    disableOtherHotkey(thisHotkey)
    DotMode := true
    ResetCurrentModeLockState("DotMode")
    keywait `. 
    DotMode := false
    if (A_PriorKey = "." && (A_TickCount - start_tick < 300))
        send, {blind}`. 
    enableOtherHotkey(thisHotkey)
    return











RButton::
enterRButtonMode()
{
	global RButtonMode
    start_tick := A_TickCount
    thisHotkey := A_ThisHotkey
    RButtonMode := true
	keywait, RButton
    RButtonMode := false
    if (A_PriorKey = "RButton" && (A_TickCount - start_tick < 350)) {
        ; 如果在系统设置中交换了左右键,  那么需要发送左键才能打开右键菜单
        SysGet, swapMouseButton, 23
        if swapMouseButton {
            send, {blind}{LButton}
        } else {
            send, {blind}{RButton}
        }
    }
}









#if JModeK
*k::return
*D::send, {blind}+{down}
*G::send, {blind}+{end}
*X::send, {blind}+{esc}
*A::send, {blind}+{home}
*S::send, {blind}+{left}
*F::send, {blind}+{right}
*E::send, {blind}+{up}
*Z::send, {blind}^+{left}
*V::send, {blind}^+{right}
*C::send, {blind}{bs}


#if JMode
*k::enterJModeK()
`;::RealShellRun(A_WorkingDir "\bin\ahk.exe", """" A_WorkingDir "\bin\CustomShellMenu.ahk" """")
*2::send, ^+{tab}
*3::send, ^{tab}
*Q::send, {appskey}
*W::send, {blind}+{tab}
*Z::send, {blind}^{left}
*V::send, {blind}^{right}
*C::send, {blind}{bs}
*,::send, {blind}{del}
*D::send, {blind}{down}
*G::send, {blind}{end}
*Space::send, {blind}{enter}
*A::send, {blind}{home}
*.::send, {blind}{insert}
*S::send, {blind}{left}
*F::send, {blind}{right}
*R::send, {blind}{tab}
*E::send, {blind}{up}
*X::send, {esc}
*T::sendevent, +{end}{bs}
*B::sendevent, ^{bs}
*L::sendevent, {home}+{end}
I::防止J模式误触("ji")





#if SemicolonMode
*U::send, {blind}$
*R::send, {blind}&
*Q::send, {blind}(){left}
*A::send, {blind}*
*M::send, {blind}-
*C::send, {blind}.
*N::send, {blind}/
*I::send, {blind}:
*S::send, {blind}<
*D::send, {blind}=
*F::send, {blind}>
*Y::send, {blind}@
*Z::send, {blind}\
*X::send, {blind}_
*B::send, {blind}`%
*J::send, {blind}`;
*K::send, {blind}``
*G::send, {blind}{!}
*W::send, {blind}{#}
*H::send, {blind}{+}
*E::send, {blind}{^}
*O::send, {blind}{end};
*V::send, {blind}|
*T::send, {blind}~









#if Mode3
/::action_lock_current_mode()
*H::send, {blind}0
*J::send, {blind}1
*K::send, {blind}2
*L::send, {blind}3
*U::send, {blind}4
*I::send, {blind}5
*O::send, {blind}6
*B::send, {blind}7
*N::send, {blind}8
*M::send, {blind}9
*0::send, {blind}{f10}
*E::send, {blind}{f11}
*R::send, {blind}{f12}
*1::send, {blind}{f1}
*Space::send, {blind}{f1}
*2::send, {blind}{f2}
*4::send, {blind}{f4}
*5::send, {blind}{f5}
*7::send, {blind}{f7}
*8::send, {blind}{f8}
*9::send, {blind}{f9}









#if DotMode
*,::action_hold_down_shift_key()
*T::send, {blind}+{home}{bs}
*W::send, {blind}+{tab}
*2::send, {blind}^+{tab}
*Y::send, {blind}^y
*B::send, {blind}^{bs}
*Z::send, {blind}^{left}
*V::send, {blind}^{right}
*3::send, {blind}^{tab}
*Q::send, {blind}{appskey}
*C::send, {blind}{bs}
*D::send, {blind}{down}
*G::send, {blind}{end}
*Space::send, {blind}{enter}
*X::send, {blind}{esc}
*A::send, {blind}{home}
*L::send, {blind}{home}+{end}
*S::send, {blind}{left}
*F::send, {blind}{right}
*R::send, {blind}{tab}
*E::send, {blind}{up}









#if CapslockMode
*X::Capslock__aa98672807c9102d3827b979e18f0299()
C::MyRun("SoundControl.exe")
R::SwitchWindows()
D::SystemAltTab()
G::ToggleTopMost()
E::action_enter_task_switch_mode()
S::center_window_to_current_monitor(1200, 800)
A::center_window_to_current_monitor(1370, 930)
*I::fastMoveMouse("I", 0, -1)
*J::fastMoveMouse("J", -1, 0)
*K::fastMoveMouse("K", 0, 1)
*L::fastMoveMouse("L", 1, 0)
*,::lbuttonDown()
*N::leftClick()
*.::moveCurrentWindow()
*M::rightClick()
*`;::scrollWheel(";", 4)
*H::scrollWheel("H", 3)
*O::scrollWheel("O", 2)
*U::scrollWheel("U", 1)
W::send, !{tab}
V::send, #+{right}
Y::send, {LControl down}{LWin down}{Left}{LWin up}{LControl up}
P::send, {LControl down}{LWin down}{Right}{LWin up}{LControl up}
*T::send, {blind}#{left}
*0::send, {blind}{Volume_Down}
*9::send, {blind}{Volume_Up}
7::set_window_position_and_size(0, 0, 960, 1080)
8::set_window_position_and_size(960, 0, 960, 1080)
Q::winMaximizeIgnoreDesktop()
B::winMinimizeIgnoreDesktop()




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


#if SLOWMODE
*,::lbuttonDown()
*N::leftClick()
*.::moveCurrentWindow()
*M::rightClick()
*`;::scrollWheel(";", 4)
*H::scrollWheel("H", 3)
*O::scrollWheel("O", 2)
*U::scrollWheel("U", 1)
*I::slowMoveMouse("I", 0, -1)
*J::slowMoveMouse("J", -1, 0)
*K::slowMoveMouse("K", 0, 1)
*L::slowMoveMouse("L", 1, 0)


Esc::exitMouseMode()
*Space::exitMouseMode()

#if FMode
f::return
H::ActivateOrRun("- Microsoft Visual Studio", "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Visual Studio 2019.lnk", "", "")
E::ActivateOrRun("ahk_class CabinetWClass ahk_exe Explorer.EXE", "D:\", "", "")
Q::ActivateOrRun("ahk_class EVERYTHING", "C:\Program Files\Everything\Everything.exe", "", "")
K::ActivateOrRun("ahk_class PotPlayer64", "" A_ProgramsCommon "\Daum\PotPlayer 64 bit\PotPlayer 64 bit.lnk", "", "")
S::ActivateOrRun("ahk_exe Code.exe", "" A_Programs "\Visual Studio Code\Visual Studio Code.lnk", "", "")
L::ActivateOrRun("ahk_exe EXCEL.EXE", "" A_ProgramsCommon "\Excel.lnk", "", "")
R::ActivateOrRun("ahk_exe FoxitReader.exe", "D:\install\Foxit Reader\FoxitReader.exe", "", "")
O::ActivateOrRun("ahk_exe ONENOTE.EXE", "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\OneNote.lnk", "", "")
P::ActivateOrRun("ahk_exe POWERPNT.EXE", "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\PowerPoint.lnk", "", "")
I::ActivateOrRun("ahk_exe Typora.exe", "C:\Program Files\Typora\Typora.exe", "", "")
A::ActivateOrRun("ahk_exe WindowsTerminal.exe", "wt.exe", "", "")
W::ActivateOrRun("ahk_exe chrome.exe", "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Google Chrome.lnk", "", "")
D::ActivateOrRun("ahk_exe msedge.exe", "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk", "", "")
J::ActivateOrRun("detect_hidden_window: ahk_exe idea64.exe", "" A_Programs "\JetBrains Toolbox\IntelliJ IDEA Ultimate.lnk", "", "")
M::ActivateOrRun("if_exist_then_send: TIM.exe, ^!z", "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\腾讯软件\TIM\TIM.lnk", "", "")



#if CapslockSpaceMode
space::return
D::ActivateOrRun("detect_hidden_window: ahk_exe datagrip64.exe", "" A_Programs "\JetBrains Toolbox\DataGrip.lnk", "", "")
G::ActivateOrRun("detect_hidden_window: ahk_exe goland64.exe", "" A_Programs "\JetBrains Toolbox\GoLand.lnk", "", "")
T::ActivateOrRun("if_exist_then_send: TIM.exe, ^!z", "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\腾讯软件\TIM\TIM.lnk", "", "")
W::ActivateOrRun("if_exist_then_send: WeChat.exe, ^!w", "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\微信\微信.lnk", "", "")



#if DisableCapslockKey
*capslock::return
*capslock up::return





#if RButtonMode
*LButton::send, {blind}^!{tab}
*WheelUp::send, {blind}^+{tab}
*WheelDown::send, {blind}^{tab}
*C::send, {blind}{bs}
*Space::send, {blind}{enter}
*X::send, {esc}




#If TASK_SWITCH_MODE
*E::send, {blind}{up}
*D::send, {blind}{down}
*S::send, {blind}{left}
*F::send, {blind}{right}
*X::send,  {blind}{del}
*Space::send, {blind}{enter}

#if !keymapIsActive


~+;::return
!capslock::toggleCapslock()
+capslock::toggleCapslock()

#If




execSemicolonAbbr(typo) {
    switch typo 
    {
    case "zk":
                send, {blind}[]{left}
    case "zh":
                send, {blind}{text} site:zhihu.com
    case "fs":
                send, {blind}{text}、
    case "gt":
                send, {blind}{text}🐶
    case "dh":
            SemicolonAbbr2__dh()
    case "dk":
            SemicolonAbbr2__dk()
    case "gg":
            SemicolonAbbr2__gg()
    case "sk":
            SemicolonAbbr2__sk()
    case "ss":
            SemicolonAbbr2__ss()
    case "ver":
            SemicolonAbbr2__ver()
    case "xk":
            SemicolonAbbr2__xk()
    case "kg":
            actionAddSpaceBetweenEnglishChinese()
    case "dq":
            action_align_text()
    case "year":
            send, % "明年是" . (A_YYYY + 1) . "年"
    case "sj":
            send, {blind}%A_YYYY%-%A_MM%-%A_DD% %A_Hour%:%A_Min%
    case "jt":
            send, {blind}{text}➤` ` 
    case "/":
            send, {blind}、
    case ".":
            send, {blind}。
    case ",":
            send, {blind}，
    case "gre":
            setColor("#080")
    case "blu":
            setColor("#2E66FF")
    case "red":
            setColor("#D05")
    case "pin":
            setColor("#FF00FF")
    case "pur":
            setColor("#b309bb")
    default:
            return false
    }
    return true
}

execCapslockAbbr(typo) {
    switch typo 
    {
    case "dm":
            ActivateOrRun("", ".\", "", "")
    case "gg":
            ActivateOrRun("", "https://google.com/search?q={selected_text}", "", "")
    case "bd ":
            ActivateOrRun("", "https://www.baidu.com", "", "")
    case "ly":
            ActivateOrRun("", "ms-settings:bluetooth", "", "")
    case "bb":
            ActivateOrRun("Bing 词典", "C:\Program Files\Google\Chrome\Application\chrome.exe", "--app=https://cn.bing.com/dict/search?q={selected_text}", "")
    case "st":
            ActivateOrRun("Microsoft Store", "shortcuts\Store.lnk", "", "")
    case "mm":
            ActivateOrRun("MyKeymap - Visual Studio Code", "" A_Programs "\Visual Studio Code\Visual Studio Code.lnk", "D:\MyFiles\MyKeymap", "")
    case "sp":
            ActivateOrRun("Spotify", "https://open.spotify.com/", "", "")
    case "tm":
            ActivateOrRun("ahk_exe taskmgr.exe", "taskmgr.exe", "", "")
    case "ms":
            ActivateOrRun("my_site - Visual Studio Code", "" A_Programs "\Visual Studio Code\Visual Studio Code.lnk", "D:\project\my_site", "")
    case "acmd":
            ActivateOrRun("管理员 ahk_exe cmd.exe", "cmd.exe", "", "", true)
    case "we":
            ActivateOrRun("网易云音乐", "shortcuts\网易云音乐.lnk", "", "")
    case "no":
            ActivateOrRun("记事本", "notepad.exe", "", "")
    case "sl":
            DllCall("PowrProf\SetSuspendState", "Int", 0, "Int", 0, "Int", 0)
    case "help":
            openHelpHtml()
    case "se":
            openSettings()
    case "ex":
            quit(false)
    case "rex":
            restartExplorer()
    case "ld":
            run, bin\ahk.exe bin\changeBrightness.ahk
    case "lj":
            run, shell:RecycleBinFolder
    case "dd":
            run, shell:downloads
    case "rb":
            slideToReboot()
    case "gj":
            slideToShutdown()
    default:
            return false
    }
    return true
}




Capslock__aa98672807c9102d3827b979e18f0299()
{
    if winactive("ahk_group window_group_4") {
        send, {blind}^w
        return
    }
    if (true) {
        SmartCloseWindow()
        return
    }
}

SemicolonAbbr2__dh() {
    send, {blind}{home}
    sleep 50
    send, {blind}电话号码: 123456{enter}
}
SemicolonAbbr2__dk() {
    send, {blind}{text}{}
    send, {blind}{left}
}
SemicolonAbbr2__gg() {
    send, {blind}{text}git add -A`; git commit -a -m ""`; git push origin (git branch --show-current)`;
    send, {blind}{left 47}
}
SemicolonAbbr2__sk() {
    send, {blind}{text}「  」
    send, {blind}{left 2}
}
SemicolonAbbr2__ss() {
    send, {blind}{text}""
    send, {blind}{left}
}
SemicolonAbbr2__ver() {
    send, {blind}#r
    sleep 700
    send, {blind}winver{enter}
}
SemicolonAbbr2__xk() {
    send, {blind}{text}()
    send, {blind}{left 1}
}
