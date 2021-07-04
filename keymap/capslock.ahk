#NoEnv
#notrayicon
#SingleInstance Force
#UseHook
#MaxHotkeysPerInterval 200
#include keymap/functions.ahk

SetBatchLines -1
ListLines Off
process, Priority,, A
SetWorkingDir %A_ScriptDir%  
SendMode Input

SetMouseDelay, 0  ; 发送完一个鼠标后不会 sleep
SetDefaultMouseSpeed, 0
coordmode, mouse, screen
settitlematchmode, 2

time_enter_repeat = T0.2
delay_before_repeat = T0.01
fast_one := 110     ;90
fast_repeat := 70
slow_one :=  10     ; 10
slow_repeat := 13

init()

; 新建 ahk 线程
; thread0 := AhkThread()
; thread0.ahkdll("keymap\my_menu.ahk")
; menuWindowId := thread0.ahkgetvar.currentWindowId


CoordMode, Mouse, Screen
; 多显示器不同缩放比例导致的问题,  https://www.autohotkey.com/boards/viewtopic.php?f=14&t=13810
DllCall("SetThreadDpiAwarenessContext", "ptr", -3, "ptr")
return

~capslock::
    CapslockMode := true
    keywait capslock
    CapslockMode := false
    if (A_PriorKey == "CapsLock" && A_TimeSinceThisHotkey < 450) {
        showXianyukangWindow()
        return
    }
    return


#if CapslockMode
; ------ 窗口管理 ------
e::send ^!{tab}
w::send !{tab}
x::SmartCloseWindow()
r::SwitchWindows()
t::run, list_view.ahk
; y::MoveWindow()


d::
    ; ShowDimmer()
    send ^!{f11}
    return
space::
    ; ShowDimmer()
    ShowCommandBar()
    return
b::
    WingetPos x, y, width, height, A
    mousemove % x + width/2, y + height/2, 0
    return

f::
    FMode := true
    CapslockMode := false
    SLOWMODE := false
    keywait f
    FMode := false
    return

; 鼠标
u::MouseClick, WheelUp, , , 1
o::MouseClick, WheelDown, , , 1
h::MouseClick, WheelLeft, , , 1
`;::MouseClick, WheelRight, , , 1

j::fastMoveMouse("j", -1, 0)
k::fastMoveMouse("k", 0, 1)
l::fastMoveMouse("l", 1, 0)
i::fastMoveMouse("i", 0, -1)

y::send  {LControl down}{LWin down}{Left}{LWin up}{LControl up}
p::send {LControl down}{LWin down}{Right}{LWin up}{LControl up}

n::
    send,  {blind}{Lbutton down}
    sleep 50
    send {Lbutton up}
    SLOWMODE := false
    return
m::
    send,  {blind}{Rbutton down}
    sleep 50
    send {Rbutton up}
    SLOWMODE := false
    return

,::send {Lbutton down}


#if FMode

; 配合 shit 键,  有可以多一倍的按键
; 剩余按键 p、k、y、u、n、b、,、.、/、x
; 由于指法无法利用的按键 t、g、c

f::return

; 常用软件
z::ActivateOrRun("ahk_class CabinetWClass ahk_exe Explorer.EXE", "D:\")
a::ActivateOrRun("ahk_exe WindowsTerminal.exe", "shortcuts\Windows Terminal Preview.lnk")
w::ActivateOrRun("ahk_exe chrome.exe", A_ProgramsCommon . "\Google Chrome.lnk")
d::ActivateOrRun("ahk_exe msedge.exe", A_ProgramsCommon . "\Microsoft Edge.lnk")
r::ActivateOrRun("ahk_exe FoxitReader.exe", "D:\install\Foxit Reader\FoxitReader.exe")
p::ActivateOrRun("ahk_exe PaintDotNet.exe", "C:\ProgramMicrosoft\Windows\Start Menu\Programs\paint.net.lnk") 

; IDE、编辑器、笔记软件相关
e::ActivateOrRun("ahk_class YXMainFrame", A_Programs . "\印象笔记\印象笔记.lnk")
o::ActivateOrRun("OneNote for Windows 10", "shortcuts\OneNote for Windows 10.lnk")
j::ActivateOrRun("ahk_exe idea64.exe", A_Programs . "\JetBrains Toolbox\IntelliJ IDEA Ultimate.lnk") 
h::ActivateOrRun("- Microsoft Visual Studio", A_ProgramsCommon . "\Visual Studio 2019.lnk") 
u::ActivateOrRun("ahk_exe datagrip64.exe", A_Programs . "\JetBrains Toolbox\DataGrip.lnk") 
s::ActivateOrRun("ahk_exe Code.exe", A_Programs . "\Visual Studio Code\Visual Studio Code.lnk")
i::ActivateOrRun("ahk_exe Typora.exe", "C:\Program Files\Typora\Typora.exe") 

m::ActivateOrRun("ahk_exe MindManager.exe", "C:\Program Files\Mindjet\MindManager 19\MindManager.exe")
q::ActivateOrRun("ahk_class EVERYTHING", A_ProgramFiles . "\Everything\Everything.exe")
l::ActivateOrRun("ahk_class PotPlayer64", A_ProgramFiles . "\DAUM\PotPlayer\PotPlayerMini64.exe")

; 多按一个 shift 键,  于是按键数就多了一倍
+w::ActivateOrRun("ahk_exe WINWORD.EXE", A_ProgramsCommon . "\Word.lnk")
+p::ActivateOrRun("ahk_exe POWERPNT.EXE", A_ProgramsCommon . "\PowerPoint.lnk")


;鼠标的慢速model
#if SLOWMODE
u::send {blind}{wheelup}
o::send {blind}{wheeldown}
n::
    send, {blind}{Lbutton}
    SLOWMODE := false
    return
m::
    send, {blind}{Rbutton}
    SLOWMODE := false
    return

esc::
space::
    SLOWMODE := false
    send {Lbutton up}
    return

,::send {Lbutton down}

    

j::slowMoveMouse("j", -1, 0)
k::slowMoveMouse("k", 0, 1)
l::slowMoveMouse("l", 1, 0)
i::slowMoveMouse("i", 0, -1)


#IfWinActive, ahk_group  taskswitch
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

QUIT:
    quit(true)
    return

ShowCommandBar()
{
    old := A_DetectHiddenWindows
    DetectHiddenWindows, 1
    PostMessage, 0x8003, 0, 0, , __KeyboardGeekInvisibleWindow
    DetectHiddenWindows, %old%
    ; winshow, __KeyboardGeekCommandBar
    ; winactivate, __KeyboardGeekCommandBar
}

SwitchWindows()
{
    wingetclass, class, A
    if (class == "ApplicationFrameWindow")
        to_check := "ahk_class "  class  "ahk_exe "  GetProcessName()
    else
        to_check := "ahk_exe "  GetProcessName()

    MyGroupActivate(to_check)
    return
}

MoveWindow()
{
    wingetclass, class, A
    if (class == "ApplicationFrameWindow")
        {
            sendevent {lalt down}{space down}
            sleep 10
            sendevent {space up}{lalt up}
            sleep 10
            sendevent m{left}
        }
    else 
    {
        postmessage 0x0112, 0xF010, 0,, A
        send {left}
    }
}


init()
{
    global
    Menu, Tray, Icon, exe.ico
    parentPath := getProcessPath()
    SetWorkingDir, %parentPath%

    ;Menu, Tray, NoStandard
    ;Menu, Tray, DeleteAll
    ;Menu, Tray, Add, E&xit, QUIT

    groupadd, taskswitch, ahk_exe  explorer.exe ahk_class TaskSwitcherWnd
    groupadd, taskswitch, ahk_exe  explorer.exe ahk_class MultitaskingViewFrame

}


