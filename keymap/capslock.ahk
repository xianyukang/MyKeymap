#NoEnv
#notrayicon
#SingleInstance Force
#UseHook
#MaxHotkeysPerInterval 200
#include keymap/functions.ahk

SetBatchLines -1
;ListLines Off
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

thread0 := AhkThread()
thread0.ahkdll("keymap\my_menu.ahk")
return




~capslock::
    CapslockMode := true
    keywait capslock
    CapslockMode := false
    if (A_PriorKey == "CapsLock" && A_TimeSinceThisHotkey < 450){
        thread0.addScript("show_menu()" , 2)
        return
    }
    return


#if CapslockMode
; ------ 窗口管理 ------
e::send ^!{tab}
w::send !{tab}
x::SmartCloseWindow()
r::SwitchWindows()
; y::MoveWindow()



d::
    ShowDimmer()
    send ^!{f11}
    return
space::
    ShowDimmer()
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



;鼠标
u::MouseClick, WheelUp, , , 1
o::MouseClick, WheelDown, , , 1
h::MouseClick, WheelLeft, , , 2
`;::MouseClick, WheelRight, , , 2


;h::send  {blind}{WheelLeft}
;`;::send {blind}{WheelRight}

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


j::
    ;SLOWMODE := true
    ;mousemove,  -%fast_one%, 0, 0,  R
    ;sleep 220
    ;while (getkeystate(A_thishotkey,"P"))
    ;{
    ;    mousemove,  -%fast_repeat%, 0, 0,  R
    ;    sleep 10
    ;}
    ;return



    SLOWMODE := true
    dllMouseMove(-fast_one, 0)
    keywait, j,  %time_enter_repeat%
    while (errorlevel != 0)
    {
        dllMouseMove(-fast_repeat, 0)
        keywait,  j,  %delay_before_repeat%
    }
    return

k::
    ;SLOWMODE := true
    ;mousemove,  0, %fast_one%, 0,  R
    ;sleep 220
    ;while (getkeystate(A_thishotkey,"P"))
    ;{
    ;    mousemove,  0, %fast_repeat%, 0,  R
    ;    sleep 10
    ;}
    ;return



    SLOWMODE := true
    dllMouseMove(0, fast_one)
    keywait, k,  %time_enter_repeat%
    while (errorlevel != 0)
    {
        dllMouseMove(0, fast_repeat)
        keywait,  k,  %delay_before_repeat%
    }
    return


l::
    ;SLOWMODE := true
    ;mousemove,  %fast_one%, 0, 0,  R
    ;sleep 220
    ;while (getkeystate(A_thishotkey,"P"))
    ;{
    ;    mousemove,  %fast_repeat%, 0, 0,  R
    ;    sleep 10
    ;}
    ;return



    SLOWMODE := true
    dllMouseMove(fast_one, 0)
    keywait, l,  %time_enter_repeat%
    while (errorlevel != 0)
    {
        dllMouseMove(fast_repeat, 0)
        keywait,  l,  %delay_before_repeat%
    }
    return


i::
    ;SLOWMODE := true
    ;mousemove,  0, -%fast_one%, 0,  R
    ;sleep 220
    ;while (getkeystate(A_thishotkey,"P"))
    ;{
    ;    mousemove,  0, -%fast_repeat%, 0,  R
    ;    sleep 10
    ;}
    ;return



    SLOWMODE := true
    dllMouseMove(0, -fast_one)
    keywait, i,  %time_enter_repeat%
    while (errorlevel != 0)
    {
        dllMouseMove(0, -fast_repeat)
        keywait,  i,  %delay_before_repeat%
    }
    return


#if FMode

f::return
;x::SmartCloseWindow()
;space::send  {enter}
; 最酷的笔记软件, OneNote
o::ActivateOrRun("OneNote for Windows 10", "shortcuts\OneNote for Windows 10.lnk")
; 显示 Evenote
e::ShowEvernote()
; 文件管理器
;*a::ActivateOrRun("ahk_class CabinetWClass ahk_exe Explorer.EXE", "explorer.exe")
; Windows 下颜值最高的命令行工具,  设置好了能让 linux 子系统更易用
; a::ActivateOrRun("ahk_class VirtualConsoleClass", "tools\cmder\cmder.exe")
a::ActivateOrRun("ahk_exe WindowsTerminal.exe", "shortcuts\Windows Terminal Preview.lnk")
; 世界上最受欢迎的 Chrome 浏览器
w::ActivateOrRun("ahk_exe chrome.exe", A_ProgramsCommon . "\Google Chrome.lnk")
d::ActivateOrRun("ahk_exe msedge.exe", A_ProgramsCommon . "\Microsoft Edge.lnk")
;*f::ActivateOrRun("ahk_exe firefox.exe", "C:\Program Files\Mozilla Firefox\firefox.exe")
r::ActivateOrRun("ahk_exe FoxitReader.exe", "D:\Download\zip\FoxiReader\Foxit Reader\FoxitReader.exe")
; Kindle 桌面客户端
;*k::ActivateOrRun("ahk_exe Kindle.exe", A_Programs . "\Amazon\Amazon Kindle\Kindle.lnk")
; Webstorm 写 前端 
;*w::ActivateOrRun("ahk_exe webstorm64.exe", A_Programs . "\JetBrains Toolbox\WebStorm.lnk") 
; Pycharm 写 Python 
;*p::ActivateOrRun("ahk_exe pycharm64.exe", A_Programs . "\JetBrains Toolbox\PyCharm Professional.lnk") 
p::ActivateOrRun("ahk_exe PaintDotNet.exe", "C:\ProgramMicrosoft\Windows\Start Menu\Programs\paint.net.lnk") 

; IDE、编辑器相关
j::ActivateOrRun("ahk_exe idea64.exe", A_Programs . "\JetBrains Toolbox\IntelliJ IDEA Ultimate.lnk") 
s::ActivateOrRun("ahk_exe Code.exe", A_Programs . "\Visual Studio Code\Visual Studio Code.lnk")
; i::ActivateOrRun("ahk_class Vim", "gvim.exe")
i::ActivateOrRun("ahk_exe Typora.exe", "C:\Program Files\Typora\Typora.exe") 

; 好看的 MindManager 思维导图工具, m 按键容易误触
m::ActivateOrRun("ahk_exe MindManager.exe", "C:\Program Files\Mindjet\MindManager 19\MindManager.exe")
; Everything
q::ActivateOrRun("ahk_class EVERYTHING", A_ProgramFiles . "\Everything\Everything.exe")
; Excel or PotPlayer
l::ActivateOrRun("ahk_class PotPlayer64", A_ProgramFiles . "\DAUM\PotPlayer\PotPlayerMini64.exe")
; 多按一个 shift 键,  于是按键数就多了一倍
+w::ActivateOrRun("ahk_exe WINWORD.EXE", A_ProgramsCommon . "\Word.lnk")
+p::ActivateOrRun("ahk_exe POWERPNT.EXE", A_ProgramsCommon . "\PowerPoint.lnk")




; ; 显示 Evenote
; *e::ShowEvernote()

; ; Gvim 
; *i::ActivateOrRun("ahk_class Vim", "gvim.exe")

; ; VScode 
; *v::ActivateOrRun("ahk_exe Code.exe", "shortcuts\Visual Studio Code.lnk")


; ; 文件管理器
; *a::ActivateOrRun("ahk_class CabinetWClass ahk_exe Explorer.EXE", "explorer.exe")

; ; Windows 下颜值最高的命令行工具,  设置好了能让 linux 子系统更易用
; *o::ActivateOrRun("ahk_class VirtualConsoleClass", "tools\cmder\cmder.exe")

; ; 世界上最受欢迎的 Chrome 浏览器
; *c::ActivateOrRun("ahk_exe chrome.exe", "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe")
; *f::ActivateOrRun("ahk_exe firefox.exe", "C:\Program Files\Mozilla Firefox\firefox.exe")
; *r::ActivateOrRun("ahk_exe FoxitReader.exe", "D:\Download\zip\FoxiReader\Foxit Reader\FoxitReader.exe")

; ; Kindle 桌面客户端
; *k::ActivateOrRun("ahk_exe Kindle.exe", A_Programs . "\Amazon\Amazon Kindle\Kindle.lnk")


; ; Webstorm 写 前端 
; *w::ActivateOrRun("ahk_exe webstorm64.exe", A_Programs . "\JetBrains Toolbox\WebStorm.lnk") 

; ; Pycharm 写 Python 
; *p::ActivateOrRun("ahk_exe pycharm64.exe", A_Programs . "\JetBrains Toolbox\PyCharm Professional.lnk") 
 
; ; IDEA 写 Java 
; *j::ActivateOrRun("ahk_exe idea64.exe", A_Programs . "\JetBrains Toolbox\IntelliJ IDEA Ultimate.lnk") 


; ; 好看的 MindManager 思维导图工具
; *m::ActivateOrRun("ahk_exe MindManager.exe", "C:\Program Files\Mindjet\MindManager 19\MindManager.exe")

; ; Everything
; *s::ActivateOrRun("ahk_class EVERYTHING", "tools\Everything\Everything.exe")

; ; Excel
; *l::ActivateOrRun("ahk_exe PotPlayerMini.exe", "D:\MyFiles\dz\PotPlayer\PotPlayerMini.exe")


; ; 多按一个 shift 键,  于是按键数就多了一倍
; *+w::ActivateOrRun("ahk_exe WINWORD.EXE", A_ProgramsCommon . "\Word.lnk")
; *+p::ActivateOrRun("ahk_exe POWERPNT.EXE", A_ProgramsCommon . "\PowerPoint.lnk")






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

    

j::
    dllMouseMove(-slow_one, 0)
    keywait, j,  %time_enter_repeat%
    while (errorlevel != 0)
    {
        dllMouseMove(-slow_repeat, 0)
        keywait,  j,  %delay_before_repeat%
    }
    return

k::
    dllMouseMove(0, slow_one)
    keywait, k,  %time_enter_repeat%
    while (errorlevel != 0)
    {
        dllMouseMove(0, slow_repeat)
        keywait,  k,  %delay_before_repeat%
    }
    return

l::
    dllMouseMove(slow_one, 0)
    keywait, l,  %time_enter_repeat%
    while (errorlevel != 0)
    {
        dllMouseMove(slow_repeat, 0)
        keywait,  l,  %delay_before_repeat%
    }
    return

i::
    dllMouseMove(0, -slow_one)
    keywait, i,  %time_enter_repeat%
    while (errorlevel != 0)
    {
        dllMouseMove(0, -slow_repeat)
        keywait,  i,  %delay_before_repeat%
    }
    return


#IfWinActive, ahk_group  taskswitch
r::tab
d::down
e::up
s::Left
f::Right
q::
    send {tab down}
    sleep 30
    send {tab up}
    send {tab}
    return
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













WaitThenCloseDimmer:
    settimer ,, 150
    winget, pname, ProcessName, A
    if pname not in  KeyboardGeek.exe,Listary.exe
    {
        Gui, G_Dimmer:Default
        gui, +LastFound
            While ( Trans > 0) ;这样做是增加淡出效果;
            { 		
                    Trans -= 6
                    WinSet, Transparent, %Trans% ;,  ahk_id %H_DImmer%
                    Sleep, 4
            }
        Gui, hide
        settimer ,,off
    }
    return


    
ShowDimmer()
{
    global H_DImmer
    global DimmerInitiialized
    global Trans
    Trans := 55
    if (DimmerInitiialized == "")
    {
        SysGet,monitorcount,MonitorCount
        l:=0, t:=0, r:=0, b:=0
        Loop,%monitorcount%
        {
            SysGet,monitor,Monitor,%A_Index%
            If (monitorLeft<l)
            l:=monitorLeft
            If (monitorTop<t)
            t:=monitorTop
            If (monitorRight>r)
            r:=monitorRight
            If (monitorBottom>b)
            b:=monitorBottom
        }
        resolutionRight:=r+Abs(l)
        resolutionBottom:=b+Abs(t)

        Gui,G_Dimmer:New, +HwndH_DImmer +ToolWindow +Disabled -SysMenu -Caption +E0x20 +AlwaysOnTop 
        Gui,Margin,0,0
        Gui,Color,000000
        Gui,G_Dimmer:Show, X0 Y9999 W1 H1, _____
        Gui,G_Dimmer:Show, X%l% Y%t% W%resolutionRight% H%resolutionBottom%, _____

        gui, G_Dimmer:show, NoActivate
        WinSet,Transparent,%Trans%, ahk_id %H_DImmer%
        DimmerInitiialized := true
        settimer, WaitThenCloseDimmer, -400
        }
    else
    {

        IfWinActive, __KeyboardGeekCommandBar
            return
        Gui, G_Dimmer:Default,  
        Gui, +AlwaysOnTop 
        Gui,  show, NoActivate
        ;Gui,G_Dimmer:New, +HwndH_DImmer +ToolWindow +Disabled -SysMenu -Caption +E0x20 
        WinSet,Transparent,%Trans%, ahk_id %H_DImmer%
        settimer, WaitThenCloseDimmer, -400
    }
}


send_pipe_message(pipe_message, pipe_name:="\\.\pipe\KeyboardGeekGUI_IPC_API" )
{
    ptr := A_PtrSize ? "Ptr" : "UInt"
    char_size := A_IsUnicode ? 2 : 1
    pipe := __get_pipe_handle(pipe_name)

    If pipe = -1
        return false

    DllCall("ConnectNamedPipe", ptr, pipe, ptr, 0)

    pipe_message := (A_IsUnicode ? chr(0xfeff) : chr(239) chr(187) chr(191)) . pipe_message
    If !DllCall("WriteFile", ptr, pipe, "str", pipe_message, "uint", (StrLen(pipe_message)+1)*char_size, "uint*", 0, ptr, 0)
        ExitAPP
        ;MsgBox WriteFile failed: %ErrorLevel%/%A_LastError%

    DllCall("CloseHandle", ptr, pipe)
    return true

}

__get_pipe_handle(name) {
    GENERIC_WRITE := 0x40000000  
    GENERIC_READ  := 0x80000000  
    access := GENERIC_READ | GENERIC_WRITE

    return DllCall("CreateFile"
        ,"Str" , name
        ,"UInt", access
        ,"UInt", 3 ; share read / write
        ,"UInt", 0
        ,"UInt", 3 ; open existing file
        ,"UInt", 0
        ,"UInt", 0)			
}



ShowCommandBar()
{
    ;global desktopid
    ;winactivate, ahk_class WorkerW ahk_exe Explorer.EXE
    ;desktopid := winexist("Program Manager ahk_exe explorer.exe")

    PipeMsg := "ShowCommandBar"
    r :=  send_pipe_message(PipeMsg)
    if (r)
    {
        winshow, __KeyboardGeekCommandBar
        winactivate, __KeyboardGeekCommandBar
    }
    else
        ShowTip("KeyboardGeek.exe is not running !")
    return
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

    DetectHiddenWindows, on
    winget, exeFullPath, ProcessPath, ahk_id %A_ScriptHwnd%
    winget, pid, PID, ahk_id %A_ScriptHwnd%
    pos := InStr(exeFullPath, "\",, 0)
    parentPath := substr(exeFullPath, 1, pos)
    SetWorkingDir, %parentPath%
    DetectHiddenWindows, off

    ;Menu, Tray, NoStandard
    ;Menu, Tray, DeleteAll
    ;Menu, Tray, Add, E&xit, QUIT


    Menu, Tray, Icon 
    if (fileexist(A_Temp . "\processkeymap.ico"))
        Menu, Tray, Icon, % A_Temp  "\processkeymap.ico", 1, 1


    groupadd, taskswitch, ahk_exe  explorer.exe ahk_class TaskSwitcherWnd
    groupadd, taskswitch, ahk_exe  explorer.exe ahk_class MultitaskingViewFrame

}


