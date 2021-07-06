#NoEnv
#SingleInstance Force
#UseHook
#MaxHotkeysPerInterval 200
#WinActivateForce               ; 解决「 winactivate 最小化的窗口时不会把窗口放到顶层(被其他窗口遮住) 」
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
fast_one := 110     
fast_repeat := 70
slow_one :=  10     
slow_repeat := 13

Menu, Tray, Icon, exe.ico
processPath := getProcessPath()
SetWorkingDir, %processPath%


CoordMode, Mouse, Screen
; 多显示器不同缩放比例导致的问题,  https://www.autohotkey.com/boards/viewtopic.php?f=14&t=13810
DllCall("SetThreadDpiAwarenessContext", "ptr", -3, "ptr")
return

~capslock::
    CapslockMode := true
    keywait capslock
    CapslockMode := false
    if (A_PriorKey == "CapsLock" && A_TimeSinceThisHotkey < 450) {
        enterHotString()
    }
    return


#if CapslockMode
; ------ 窗口管理 ------
e::send ^!{tab}
w::send !{tab}
x::SmartCloseWindow()
r::SwitchWindows()
t::run, list_view.ahk
; g::moveActiveWindow()


d::
    ; ShowDimmer()
    send ^!{f11}
    return
space::
    ; ShowDimmer()
    ShowCommandBar()
    return

f::
    FMode := true
    CapslockMode := false
    SLOWMODE := false
    keywait f
    FMode := false
    return

; 鼠标
/::centerMouse()
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

n::leftClick()
m::rightClick()
,::middleDown()

#if SLOWMODE
u::send {blind}{wheelup}
o::send {blind}{wheeldown}
n::leftClick()
m::rightClick()
,::middleDown()

esc::exitMouseMode()
space::exitMouseMode()

j::slowMoveMouse("j", -1, 0)
k::slowMoveMouse("k", 0, 1)
l::slowMoveMouse("l", 1, 0)
i::slowMoveMouse("i", 0, -1)

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

m::ActivateOrRun("ahk_exe MindManager.exe", "C:\Program Files\Mindjet\MindManager 19\MindManager.exe")
q::ActivateOrRun("ahk_class EVERYTHING", A_ProgramFiles . "\Everything\Everything.exe")
l::ActivateOrRun("ahk_class PotPlayer64", A_ProgramFiles . "\DAUM\PotPlayer\PotPlayerMini64.exe")

; IDE、编辑器、笔记软件相关
e::ActivateOrRun("ahk_class YXMainFrame", A_Programs . "\印象笔记\印象笔记.lnk")
o::ActivateOrRun("OneNote for Windows 10", "shortcuts\OneNote for Windows 10.lnk")
j::ActivateOrRun("ahk_exe idea64.exe", A_Programs . "\JetBrains Toolbox\IntelliJ IDEA Ultimate.lnk") 
h::ActivateOrRun("- Microsoft Visual Studio", A_ProgramsCommon . "\Visual Studio 2019.lnk") 
u::ActivateOrRun("ahk_exe datagrip64.exe", A_Programs . "\JetBrains Toolbox\DataGrip.lnk") 
s::ActivateOrRun("ahk_exe Code.exe", A_Programs . "\Visual Studio Code\Visual Studio Code.lnk")
i::ActivateOrRun("ahk_exe Typora.exe", "C:\Program Files\Typora\Typora.exe") 

; 多按一个 shift 键,  于是按键数就多了一倍
+w::ActivateOrRun("ahk_exe WINWORD.EXE", A_ProgramsCommon . "\Word.lnk")
+p::ActivateOrRun("ahk_exe POWERPNT.EXE", A_ProgramsCommon . "\PowerPoint.lnk")



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

