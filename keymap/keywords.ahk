#NoEnv
#Persistent
#NoTrayIcon
#SingleInstance Force

SendMode Input
SetBatchLines -1
settitlematchmode, 2
ListLines Off

currentWindowId := A_ScriptHwnd
;ToolTip, ininted
return

$9::
oldValue := A_DetectHiddenWindows
DetectHiddenWindows, 1                      ; 先激活窗口, 否则标题栏会有闪烁: 失去焦点->获得焦点
WinActivate, ahk_id %parentWindowHwnd%
WinShow, ahk_id %parentWindowHwnd%

DetectHiddenWindows, %oldValue%
return


setParentWindowHwnd(id) {
    global parentWindowHwnd
    parentWindowHwnd := id
}


exec(keyword) {
    if (keyword == "sq") {
        send ^+{esc}
    }
    else if (keyword == "sz") {
        run, %A_workingdir%
    }
    else if (keyword == "sv") {
        run, sndvol.exe -f
    }
    else if (keyword == "se") {
        winmaximize, A
    }
    else if (keyword == "sd") {
        winminimize, A
    }
    else if (keyword == "sr") {
        winrestore, A
    }
    else if (keyword == "ss") {
        send, {LWin down}{left}{Lwin up}
    }
    else if (keyword == "sf") {
        send, {LWin down}{right}{Lwin up}
    }
    else if (keyword == "sc") {
        center_window_to_current_monitor()
    }
    else if (keyword == "sa") {
        send #+{left}
    }
    else if (keyword == "sg") {
        send #+{right}
    }
    else if (keyword == "sx") {
        close_same_class_window()
    }
    else if (keyword == "st") {
        ; 这里直接调用函数会有问题,  所以用 timer 去调用,  fuck bug
        ; settimer, ToggleTopMost, -100
    }
    else if (SubStr(keyword, 1, 1) == "f") {
        text := copySelectedText()
        if (keyword == "fp") {
            style := "color:#b309bb; font-family: Iosevka;"
            mdTemplate := "<font color='#b309bb'>{{text}}</font>"
            html := set_color(text, style)
        }
        else if (keyword == "fo") {
            style := "color:#FF00FF; font-family: Iosevka;"
            mdTemplate := "<font color='#FF00FF'>{{text}}</font>"
            html := set_color(text, style)
        }
        else if (keyword == "fk") {
            style := "color:#7B68EE; font-family: Iosevka;"
            mdTemplate := "<font color='#7B68EE'>{{text}}</font>"
            html := set_color(text, style)
        }
        else if (keyword == "fr") {
            style := "color:#b309bb; font-family: Iosevka;"
            mdTemplate := "<font color='#b309bb'>{{text}}</font>"
            html := set_color(text, style)
        }
        else if (keyword == "fg") {
            style :="color:#080; font-family: Iosevka;"
            mdTemplate := "<font color='#080'>{{text}}</font>"
            html := set_color(text, style)
        }
        else if (keyword == "fb") {
            style := "color:#2E66FF; font-family: Iosevka;"
            mdTemplate := "<font color='#2E66FF'>{{text}}</font>"
            html := set_color(text, style)
        }
        else if (keyword == "fi") {
            style := "color:#D05; font-family: Iosevka;"
            mdTemplate := "<font color='#D05'>{{text}}</font>"
            html := set_color(text, style)
        }
        else if (keyword == "ff") {
            style := "font-family: Iosevka;"
            html := set_color(text, style)
        }
        else if (keyword == "fh") {
            text := htmlEscape(text)

            htmlTemplate := "<span style='color: rgb(221, 17, 68);  background:rgb(245, 245, 245); font-family: Iosevka medium;" 
                            . "border: 1px solid rgb(221, 221, 221); border-radius: 4px; '>{{text}}</span>"
            html := strReplace(htmlTemplate, "{{text}}", text)
        }

        if (WinActive(" - Typora")) {
            clipboard := strReplace(mdTemplate, "{{text}}", text)
        } else {
            ; sleep 100
            setHtml( html )
            ; sleep 100
        }

        send {LShift down}{Insert down}{Insert up}{LShift up}
    }
    else {
        return "no match"
    }
    return keyword
}

; 先把主窗口隐藏了,  ahk 脚本执行时, 才有正确的焦点
; func := Func("exec_keyword").Bind(keyword)
; SetTimer, % func, -50
exec_keyword(keyword) {
    WinWaitNotActive, ahk_id %parentWindowHwnd%,, 0.5
    WinGetTitle, title, A
    ToolTip, %title%
}

; 需要等一定延迟后才能最大化、最小化、隐藏主窗口
hide_parent_window:
WinHide, ahk_id %parentWindowHwnd%
return


setHtml(html)
{
    s := "<HTML> <head><meta http-equiv='Content-type' content='text/html;charset=UTF-8'></head> <body> <!--StartFragment-->"
    s .= html
    s .= "<!--EndFragment--></body></HTML> "
    dllcall("clip_dll.dll\setHtml", "Str", s)
}




translate(url)
{
    to_translate := get_text()
    if (!to_translate)
        return
    exePath = C:\Program Files (x86)\Google\Chrome\Application\chrome.exe
    pattern = --app="data:text/html,<html><body><script>window.moveTo(150,40);window.resizeTo(1370,850);window.location=``{1}```;</script></body></html>"
    arg := format(pattern, url)
    to_translate := strReplace(to_translate, "`r`n"," ")
    to_translate := strReplace(to_translate, "%","%25")
    to_translate := strReplace(to_translate, "/","%2F")
    to_translate := strReplace(to_translate, "’","'")

    arg := format(arg, UriEncode(to_translate))
    run, %exePath% %arg%
}






get_text()
{
    global currentWindowId
    ; WinActivate, ahk_id %currentWindowId%
    WinWaitActive, ahk_id %currentWindowId%,,0.3
    clipboard =
    send ^c
    send ^{insert}
    clipwait, 0.5, 1
    ; if (errorlevel)
    ;     msgbox miss
    r := rtrim(clipboard, "`n")
    return r
}

;get_text()
;{
;    ;sleep 10
;    old_clipboard := clipboardall
;    clipboard =
;    send ^c
;    send ^{insert}
;    clipwait, 0.5, 1
;    if (errorlevel)
;        msgbox miss
;    r := rtrim(clipboard, "`n")
;    clipboard := old_clipboard
;    tooltip % r
;    settimer, close_tooltip, -2000
;    return r
;}

htmlEscape(text)
{
    text := strReplace(text, "&", "&amp;")
    text := strReplace(text, "<", "&lt;")
    text := strReplace(text, ">", "&gt;")
    text := strReplace(text, """", "&quot;")
    text := strReplace(text, " ", "&nbsp;")
    return text
    
}


set_color(text, style )
{
    text := htmlEscape(text)

    if (instr(text, "`n")) 
        html = <span style="%style%"><pre>%text%</pre></span>
    else 
        html = <span style="%style%">%text%</span>

    return html
}



; modified from jackieku's code (http://www.autohotkey.com/forum/post-310959.html#310959)
UriEncode(Uri, Enc = "UTF-8")
{
	StrPutVar(Uri, Var, Enc)
	f := A_FormatInteger
	SetFormat, IntegerFast, H
	Loop
	{
		Code := NumGet(Var, A_Index - 1, "UChar")
		If (!Code)
			Break
		If (Code >= 0x30 && Code <= 0x39 ; 0-9
			|| Code >= 0x41 && Code <= 0x5A ; A-Z
			|| Code >= 0x61 && Code <= 0x7A) ; a-z
			Res .= Chr(Code)
		Else
			Res .= "%" . SubStr(Code + 0x100, -1)
	}
	SetFormat, IntegerFast, %f%
	Return, Res
}


StrPutVar(Str, ByRef Var, Enc = "")
{
	Len := StrPut(Str, Enc) * (Enc = "UTF-16" || Enc = "CP1200" ? 2 : 1)
	VarSetCapacity(Var, Len, 0)
	Return, StrPut(Str, &Var, Enc)
}


current_monitor_index()
{
  SysGet, numberOfMonitors, MonitorCount
  WinGetPos, winX, winY, winWidth, winHeight, A
  winMidX := winX + winWidth / 2
  winMidY := winY + winHeight / 2
  Loop %numberOfMonitors%
  {
    SysGet, monArea, Monitor, %A_Index%
    ;MsgBox, %A_Index% %monAreaLeft% %winX%
    if (winMidX >= monAreaLeft && winMidX <= monAreaRight && winMidY <= monAreaBottom && winMidY >= monAreaTop)
        return A_Index
  }
}
_ShowTip(text, size)
{
    SysGet, currMon, Monitor, % current_monitor_index()
    fontsize := (currMonRight - currMonLeft) / size

    Gui,G_Tip:destroy 
    Gui,G_Tip:New
    GUI, +Owner +LastFound
    
    Font_Colour := 0xFFFFFF ;0x2879ff
    Back_Colour := 0x000000  ; 0x34495e
    GUI, Margin, %fontsize%, % fontsize / 2
    GUI, Color, % Back_Colour
    GUI, Font, c%Font_Colour% s%fontsize%, Microsoft YaHei UI
    GUI, Add, Text, center, %text%

    GUI, show, hide
    wingetpos, X, Y, Width, Height ; , ahk_id %H_Tip%
    Gui_X := (currMonRight + currMonLeft)/2.0 - Width/2.0
    Gui_Y := (currMonTop + currMonBottom) * 0.8
    GUI, show,  NoActivate  x%Gui_X% y%Gui_Y%, Tip

    GUI, +ToolWindow +Disabled -SysMenu -Caption +E0x20 +AlwaysOnTop 
    GUI, show, Autosize NoActivate

}
ShowTip(text,  time:=2000, size:=60) 
{
    _ShowTip(text, size)
    settimer, CancelTip, -%time%
}
CancelTip()
{
    gui,G_Tip:destroy
}




ToggleTopMost()
{
    winexist("A")
    WinGet, ExStyle, ExStyle
    If (ExStyle & 0x8) {
         ExStyle = AlwaysOnTop Off
         winset, alwaysontop, off
    }
    Else {
         ExStyle = AlwaysOnTop On
         winset, alwaysontop, on
    }
    ShowTip(ExStyle, 800)
}



wp_GetMonitorAt(x, y, default=1)
{
    SysGet, m, MonitorCount
    ; Iterate through all monitors.
    Loop, %m%
    {   ; Check if the window is on this monitor.
        SysGet, Mon, Monitor, %A_Index%
        if (x >= MonLeft && x <= MonRight && y >= MonTop && y <= MonBottom)
            return A_Index
    }

    return default
}


center_window_to_current_monitor()
{
    ; WinExist win will set "A" to default window
    WinExist("A")
    SetWinDelay, 0
    WinGet, state, MinMax
    if state
        WinRestore
    WinGetPos, x, y, w, h
    ; Determine which monitor contains the center of the window.
    ms := wp_GetMonitorAt(x+w/2, y+h/2)
    ; Get source and destination work areas (excludes taskbar-reserved space.)
    SysGet, ms, MonitorWorkArea, %ms%
    msw := msRight - msLeft, msh := msBottom - msTop
    win_w := msw * 0.67,      win_h := msh * 0.7
    win_x := msLeft + (msw - win_w) / 2
    win_y := msTop + (msh - win_h) / 2
    winmove,,, %win_x%, %win_y%, %win_w%, %win_h%
}


GroupAdd(ByRef GroupName, p1:="", p2:="", p3:="", p4:="", p5:="")
{
     static g:= 1
     If (GroupName == "")
        GroupName:= "AutoName" g++
     GroupAdd %GroupName%, %p1%, %p2%, %p3%, %p4%, %p5%
}

close_same_class_window()
{
    wingetclass, class, A
    GroupAdd(temp_group, "ahk_class " . class)
    groupclose, %temp_group%, A
}


init_menu()
{
    settitlematchmode, 2

    Menu, menuSearch, Add, (&F)  Google, handler_for_menu_search
    Menu, menuSearch, Add, (&B)  Bing, handler_for_menu_search

    Menu, menuStyle, Add, (&R)  Red, handler_for_menu_style
    Menu, menuStyle, Add, (&B)  Blue, handler_for_menu_style
    Menu, menuStyle, Add, (&G)  Green, handler_for_menu_style
    Menu, menuStyle, Add, (&I)  Pink, handler_for_menu_style
    Menu, menuStyle, Add, (&P)  Purple, handler_for_menu_style
    Menu, menuStyle, Add, (&O)  Magenta, handler_for_menu_style
    Menu, menuStyle, Add, (&K)  SlateBlue, handler_for_menu_style
    Menu, menuStyle, Add, (&D)  Plain text, handler_for_menu_style
    Menu, menuStyle, Add, (&E)  Bold, handler_for_menu_style
    Menu, menuStyle, Add, (&H)  Hightlight, handler_for_menu_style
    Menu, menuStyle, Add, (&F)  Font, handler_for_menu_style


    Menu, menuWindow, Add, (&E)  最大化, handler_for_menu_window
    Menu, menuWindow, Add, (&D)  最小化, handler_for_menu_window
    Menu, menuWindow, Add, (&R)  还原, handler_for_menu_window
    Menu, menuWindow, Add, (&S)  移到左边, handler_for_menu_window
    Menu, menuWindow, Add, (&F)  移到右边, handler_for_menu_window
    Menu, menuWindow, Add, (&A)  移到左边显示器, handler_for_menu_window
    Menu, menuWindow, Add, (&G)  移到右边显示器, handler_for_menu_window


    Menu, menuWindow, Add
    Menu, menuWindow, Add, (&C)  让窗口居中, handler_for_menu_window
    Menu, menuWindow, Add, (&T)  让窗口置顶, handler_for_menu_window
    Menu, menuWindow, Add, (&X)  关闭同类窗口, handler_for_menu_window
    Menu, menuWindow, Add, (&Q)  打开任务管理器, handler_for_menu_window
    Menu, menuWindow, Add, (&Z)  打开本 App 目录, handler_for_menu_window
    Menu, menuWindow, Add, (&V)  打开音量控制器, handler_for_menu_window


    Menu, menuX, Add, (&C)  让窗口居中, handler_for_menu_X
    Menu, menuX, Add, (&T)  让窗口置顶, handler_for_menu_X
    Menu, menuX, Add, (&X)  关闭同类窗口, handler_for_menu_X
    Menu, menuX, Add, (&Q)  打开任务管理器, handler_for_menu_X
    Menu, menuX, Add, (&Z)  打开本 App 目录, handler_for_menu_X
    Menu, menuX, Add, (&V)  打开音量控制器, handler_for_menu_X



    ; 把子菜单添加到主菜单
    Menu, menuMain, Add, (&S)  Window, :menuWindow
    Menu, menuMain, Add, (&F)  Style,  :menuStyle
    Menu, menuMain, Add, (&D)  Search,  :menuSearch
    Menu, menuMain, Add, (&O)  OCR,  handler_for_menu_OCR
    Menu, menuMain, Add, (&X)  XXX,  :menuX



    ; Menu, menuMain, Icon, (&S)  Window, exe.ico,,21
    ;Menu, menuMain, Icon, (&2)  Item2, D:\MyFiles\shuaihua\图标\mychangeicon\some_icons\shell.ico,,21

}


close_tooltip:
    tooltip
    return

handler_for_menu_OCR:
    run, E:\projects\apps\web-api\target\ocr.lnk
return

handler_for_menu_X:
    selected_item := RegExReplace(A_ThisMenuItem,"\(&(.*)\)\s*(.*)","$1")
    if (selected_item == "C") {
        center_window_to_current_monitor()
    }
return



handler_for_menu_window:
    selected_item := RegExReplace(A_ThisMenuItem,"\(&(.*)\)\s*(.*)","$1")
    

    if (selected_item == "Q") {
        send ^+{esc}
    }
    else if (selected_item == "Z") {
        run, %A_workingdir%
    }
    else if (selected_item == "V") {
        run, sndvol.exe -f
    }

    ; 如果是这个窗口是桌面就返回
    if (winactive("ahk_class WorkerW ahk_exe explorer.exe"))
        return


    if (selected_item == "E") {
        winmaximize, A
    }
    else if (selected_item == "D") {
        winminimize, A
    }
    else if (selected_item == "R") {
        winrestore, A
    }
    else if (selected_item == "S") {
        send, {LWin down}{left}{Lwin up}
    }
    else if (selected_item == "F") {
        send, {LWin down}{right}{Lwin up}
    }
    else if (selected_item == "C") {
        center_window_to_current_monitor()
    }
    else if (selected_item == "A") {
        send #+{left}
    }
    else if (selected_item == "G") {
        send #+{right}
    }
    else if (selected_item == "X") {
        close_same_class_window()
    }
    else if (selected_item == "T") {
        ; 这里直接调用函数会有问题,  所以用 timer 去调用,  fuck bug
        settimer, ToggleTopMost, -100
    }
return


handler_for_menu_search:
    selected_item := RegExReplace(A_ThisMenuItem,"\(&(.*)\)\s*(.*)","$1")
    if (selected_item == "F") {
        url := "https://translate.google.cn/?op=translate&sl=auto&tl=zh-CN&text={1}"
        translate(url)
    }
    else if (selected_item == "B") {
        url := "https://cn.bing.com/dict/search?q={1}"
        translate(url)
    }

return


handler_for_menu_style:
    selected_item := RegExReplace(A_ThisMenuItem,"\(&(.*)\)\s*(.*)","$1")

    text := get_text()

    if (!text)
        return

    if (selected_item == "E") {
        send ^b
        send ^+{>}^+{>}
        return
    }
    else if (selected_item == "D") {
        if (winactive("ahk_exe evernote.exe"))
            send ^+{space}
        else if (winactive("ahk_exe onenote.exe"))
            send ^+n
        else {
            clipboard := text
            send {LShift down}{Insert down}{Insert up}{LShift up}
        }
        return
    }


    if (selected_item == "P") {
        style := "color:#b309bb; font-family: Iosevka;"
        mdTemplate := "<font color='#b309bb'>{{text}}</font>"
        html := set_color(text, style)
    }
    if (selected_item == "O") {
        style := "color:#FF00FF; font-family: Iosevka;"
        mdTemplate := "<font color='#FF00FF'>{{text}}</font>"
        html := set_color(text, style)
    }
    if (selected_item == "K") {
        style := "color:#7B68EE; font-family: Iosevka;"
        mdTemplate := "<font color='#7B68EE'>{{text}}</font>"
        html := set_color(text, style)
    }
    else if (selected_item == "R") {
        style := "color:#b309bb; font-family: Iosevka;"
        mdTemplate := "<font color='#b309bb'>{{text}}</font>"
        html := set_color(text, style)
    }
    else if (selected_item == "G") {
        style :="color:#080; font-family: Iosevka;"
        mdTemplate := "<font color='#080'>{{text}}</font>"
        html := set_color(text, style)
    }
    else if (selected_item == "B") {
        style := "color:#2E66FF; font-family: Iosevka;"
        mdTemplate := "<font color='#2E66FF'>{{text}}</font>"
        html := set_color(text, style)
    }
    else if (selected_item == "I") {
        style := "color:#D05; font-family: Iosevka;"
        mdTemplate := "<font color='#D05'>{{text}}</font>"
        html := set_color(text, style)
    }
    else if (selected_item == "F") {
        style := "font-family: Iosevka;"
        html := set_color(text, style)
    }
    else if (selected_item == "H") {
        text := htmlEscape(text)

        htmlTemplate := "<span style='color: rgb(221, 17, 68);  background:rgb(245, 245, 245); font-family: Iosevka medium;" 
                         . "border: 1px solid rgb(221, 221, 221); border-radius: 4px; '>{{text}}</span>"
        html := strReplace(htmlTemplate, "{{text}}", text)
    }

    if (WinActive(" - Typora")) {
        clipboard := strReplace(mdTemplate, "{{text}}", text)
    } else {
        sleep 200
        setHtml( html )
        sleep 300
    }


    send {LShift down}{Insert down}{Insert up}{LShift up}
return




MsgMonitor(wParam, lParam, msg)
{
    if (msg == 0x5555) {
        ; show_menu()
    }
    ; ToolTip Message %msg% arrived:`nWPARAM: %wParam%`nLPARAM: %lParam%
}

copySelectedText()
{
    ; old_clipboard := clipboardall
    clipboard =
    WinWaitNotActive, ahk_id %parentWindowHwnd%,, 0.5
    send ^c
    clipwait, 0.5, 1
    if (errorlevel) {
        ToolTip, copy text failed
        SetTimer, close_tooltip, -700
    }
    r := rtrim(clipboard, "`n")

;    clipboardall := old_clipboard
    return r
}