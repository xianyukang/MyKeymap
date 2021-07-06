#NoEnv
#notrayicon
#SingleInstance Force
#UseHook
#MaxHotkeysPerInterval 200

#include keymap/functions.ahk



SetBatchLines -1
ListLines Off
process, Priority, , A
SetWorkingDir %A_ScriptDir%  
SendMode Input

coordmode,  mouse,  screen
settitlematchmode, 2
SetDefaultMouseSpeed, 0


init()

#if

RAlt::LCtrl


*3::
    DigitMode := true
    keywait 3 
    DigitMode := false
    if (A_PriorKey == "3" && A_TimeSinceThisHotkey < 350)
        send {blind}3 
    return


capslock::
    hotkey, if
    hotkey, *j, off
    return
capslock up::
    hotkey, if
    hotkey, *j, on
    return

*j::
    JMode := true
    ; hotkey, space, off
    keywait `j
    JMode := false
    ; hotkey, space, on
    if (A_PriorKey == "j" && A_TimeSinceThisHotkey < 350)
            send  {blind}`j
    return


+`;::send {blind}{:}
*`;::
    hotstring("Reset")
    PunctuationMode := true
    keywait `; 
    PunctuationMode := false
    if (A_PriorKey == ";" && A_TimeSinceThisHotkey < 350)
        EnterHotstringMode()
    return
    



#if DigitMode
*h::send  {blind}0
*j::send  {blind}1
*k::send  {blind}2
*l::send  {blind}3
*p::send {blind}7
*u::send  {blind}4
*i::send  {blind}5
*o::send  {blind}6
*n::send  {blind}8
*m::send  {blind}9



*r::
    DigitMode := false
    FnMode := true
    keywait r
    FnMode := false
    return



*space::f1
*2::backspace


#if PunctuationMode
*s::send {blind}<
*e::send {blind}{^}
*f::send {blind}>
*j::send {blind}{+}
*c::send {blind}.
*n::send {blind}/
*r::send {blind}&
*v::send {blind}|
*g::send {blind}{!}
*z::send {blind}\
*b::send {blind}`%
*a::send {blind}`;
*h::send {blind}:
*q::send {blind}{(}
*w::send {blind}{#}
*t::send {blind}~
*u::send {blind}$
*x::send {blind}_
;*q::send {blind}?
o::send {space 4}
*y::send {blind}@
*k::send {blind}``
*i::send {blind}*

; 为了让 ahk 模拟的按键能触发 ahk 里的热键,  让 sendlevel 值大于默认值 0
*d::
    sendlevel, 5
    send {blind}=
    return
*m::
    sendlevel, 5
    send {blind}-
    return


#if FnMode
*r::return
*j::send   {blind}{f1}
*k::send   {blind}{f2}
*l::send   {blind}{f3}
*u::send   {blind}{f4}
*i::send   {blind}{f5}
*o::send   {blind}{f6}
*n::send   {blind}{f8}
*m::send   {blind}{f9}
*h::send   {blind}{f10}
*,::send   {blind}{f11}
*/::send   {blind}{f12}
*p::send  {blind}{f7}
w::lalt



#if JMode
#inputlevel 5
; 关闭 capslock 模式,  避免以外开启大写
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

    *'::send  {blind}j



    *e::
    If (  WinExist( "ahk_class  SoPY_Comp" )   )
        send {pgup}
    else if (winactive("ahk_exe onenote.exe") &&   !WinExist( "ahk_class  QQPinyinCompWndTSF" ) )
    {
        ; 倒霉的 Onenote 留下了一个诡异的 bug, 且从 1812 版本开始 bug 变形了, 所以注释掉了一些行
        ;vk_code = 0xA0
        ;dllcall("keybd_event","UChar", vk_code, "UChar", 0, "UInt", 0, "Ptr", 0 )
        vk_code = 0x26
        dllcall("keybd_event","UChar", vk_code, "UChar", 0, "UInt", 0, "Ptr", 0 )
        dllcall("keybd_event","UChar", vk_code, "UChar", 0, "UInt", 0x0002, "Ptr", 0 )
        ;vk_code = 0xA0
        ;dllcall("keybd_event","UChar", vk_code, "UChar", 0, "UInt", 0x0002, "Ptr", 0 )
    }
    else
        send  {blind}{up}
    return

    *d::
    If (  WinExist( "ahk_class  SoPY_Comp" )   )
        send {pgdn}
    else if (winactive("ahk_exe onenote.exe") &&   !WinExist( "ahk_class  QQPinyinCompWndTSF" ) )
    {
        ;vk_code = 0xA0
        ;dllcall("keybd_event","UChar", vk_code, "UChar", 0, "UInt", 0, "Ptr", 0 )
        vk_code = 0x28
        dllcall("keybd_event","UChar", vk_code, "UChar", 0, "UInt", 0, "Ptr", 0 )
        dllcall("keybd_event","UChar", vk_code, "UChar", 0, "UInt", 0x0002, "Ptr", 0 )
        ;vk_code = 0xA0
        ;dllcall("keybd_event","UChar", vk_code, "UChar", 0, "UInt", 0x0002, "Ptr", 0 )
    }
    else
        send  {blind}{down}
    return
    *s::send  {blind}{left}
    *f::send  {blind}{right}
    *c::send  {blind}{bs}
    *v::send  {blind}{delete}
    *a::send  {blind}{home}
    *g::send  {blind}{end}
    *x::send  {blind}{esc}
    *z::send  {blind}{appskey}
    *t::send  {blind}{pgdn}
    *q::send  {blind}{pgup}
    *r::send  {blind}{tab}
    *i::send  {blind}{insert}
    *space::send  {blind}{enter}

    *w::send  {blind}+{tab}

#inputlevel 0




#if HotsringMode
#Hotstring *  B0 X

::xk::send (){left 1}
::ss::send ""{left}
::sk::send 「  」{left 2}
::sl::send 【】{left 1}
::zk::send []{left}
::dk::send {{}{}}{left}
::dh::send 、
::jt::send   ➤{space 1}
::gt::send 🐶
::sm::send 《》{left}
::zh::send % text("site:zhihu.com")
::dy::send % text("pan.baidu.com") . "{enter}"
::yx::send % text("850111596@qq.com")
::yx::send % text("850111596@qq.com")
::mz::send % text("ftp://192.168.1.99:2121/tv.danmaku.bili/download/")
::cpl::send {home}{sleep 100}^s+{end}^c{esc}{end}
::hr::send % text("# 一一一一一一一一一一一一一一一一一一一一一一一一一一一一一一一") "{enter 2}" text("# 一一一一一一一一一一一一一一一一一一一一一一一一一一一一一一一") "{up}" text("# ")

::hs::send % text("// 一一一一一一一一一一一一一一一一一一一一一一一一一一一一一一一") "{enter 2}" text("// 一一一一一一一一一一一一一一一一一一一一一一一一一一一一一一一") "{up}" text("// ")

::hw::send % text("#   ") "{enter}" text("# =========================") "{up}"
::hn::send % text("//  ") "{enter}" text("// =========================") "{up}"

::nl::send {end}`;

; 设置值到剪切板
::stp::set_cb("D:\Download\temp")
::slp::
clipboard = 
(
path = "E:\projects\web\lib_py"
if not path in sys.path:
    sys.path.insert(1, path)
del path
)
return




::rr::ReloadProgram()
::ex::quit(true)        ; 退出程序

; ------ 常用文件夹及文件 ------
::fa::ActivateOrRun(, ".\")                                          ; 本程序的 data 文件夹
::fp::ActivateOrRun(, "explorer.exe", "shell:my pictures")             ; shell:xxx 代表了某个特殊路径,
::fd::ActivateOrRun(, "explorer.exe", "shell:downloads")               ; 完整列表在这 https://ss64.com/nt/shell.html
::fu::ActivateOrRun(, "explorer.exe", "shell:Profile")
::lj::ActivateOrRun(, "explorer.exe", "shell:RecycleBinFolder")       ; 这里把 jj 看成单独一个 j 就好
::jl::ActivateOrRun(, "D:\我的文档\记录记录.xlsx")                    ; 因为不可抗力的原因, 把 jj 看成 j 就好
::te::ActivateOrRun(, "D:\Download\temp")                    ; 因为不可抗力的原因, 把 jj 看成 j 就好

; ------ 日常工具 ------
::anp::ActivateOrRun(, "powershell.exe",,, true)                    ; 管理员执行 powershell, true 参数表示以管理员执行
::ano::ActivateOrRun(, "tools\cmder\cmder.exe",,, true)    ; 管理员执行 cmder, true 参数表示以管理员执行
::rex::ActivateOrRun(, "tools\Rexplorer_x64.exe")          ; 重启资源管理器
::pd::ActivateOrRun("ahk_exe FoxitReader.exe")                      ; 福昕阅读器



::ti::
    if (ProcessExist("TIM.exe"))
        send ^!z
    else
        ActivateOrRun(, A_ProgramsCommon "\腾讯软件\TIM\TIM.lnk")
    return

; ------ 多开一个窗口 ------
::nw::ActivateOrRun(, A_ProgramFiles . "\Google\Chrome\Application\chrome.exe")
::nf::ActivateOrRun(, "C:\Program Files\Mozilla Firefox\firefox.exe")
::no::ActivateOrRun(, "tools\cmder\cmder.exe")



; ------ 开发工具 -----

::vs::ActivateOrRun("- Microsoft Visual Studio",  A_ProgramsCommon . "\Visual Studio 2017.lnk")



; ------ uwp 应用 ------
::ne::ActivateOrRun("网易云音乐 ahk_class  ApplicationFrameWindow ", "shortcuts\网易云音乐.lnk")
::eg::ActivateOrRun("Microsoft Edge ahk_class  ApplicationFrameWindow ", "shortcuts\Microsoft Edge.lnk")
::as::ActivateOrRun("Microsoft Store ahk_class  ApplicationFrameWindow ", "shortcuts\Microsoft Store.lnk")



; ------- 系统控制 ------
;::sd::shutdown, 1
::rb::shutdown, 2





;空格 退出模式
:?*B0: ::
    ExitHotstringMode()
    ShowTip("Canceled !", 900)
    return


ReloadProgram()
{
    global exeFullPath
    global pid
    Menu, Tray, NoIcon 
    tooltip, Reload !
    run, "keygeek.ahk"
    ;run, "%exeFullPath%" Reload
    ;process, close, %pid%
    ;process, close, ahk.exe
}




timer_HotstringMode:
    if (A_thishotkey != "*;")
        ExitHotstringMode()
    return
EnterHotstringMode()
{
    global HotsringMode
    HotsringMode := true
    hotkey, IfWinActive
    hotkey, *j, off
    blockinput on
    ;click up ; 重置热字串状态
    settimer, timer_HotstringMode, 50
}
ExitHotstringMode()
{
    global HotsringMode
    HotsringMode := false
    hotkey, IfWinActive
    hotkey, *j, on
    blockinput off
    settimer, timer_HotstringMode, off
}


init()
{
    global
    DetectHiddenWindows, on
    winget, exeFullPath, ProcessPath, ahk_id %A_ScriptHwnd%
    winget, pid, PID, ahk_id %A_ScriptHwnd%
    pos := InStr(exeFullPath, "\",, 0)
    parentPath := substr(exeFullPath, 1, pos)
    SetWorkingDir, %parentPath%
    DetectHiddenWindows, off
}

set_cb(text)
{
    clipboard := text
    if (strlen(text) > 30) {
        text := substr(text,1,30)
        text .= " . . ."
    }
    ShowTip(text, 1000, 66)
}

