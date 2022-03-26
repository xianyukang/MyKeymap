/*
  ShellRun by Lexikos
    requires: AutoHotkey_L
    license: http://creativecommons.org/publicdomain/zero/1.0/

  Credit for explaining this method goes to BrandonLive:
  http://brandonlive.com/2008/04/27/getting-the-shell-to-run-an-application-for-you-part-2-how/
 
  Shell.ShellExecute(File [, Arguments, Directory, Operation, Show])
  http://msdn.microsoft.com/en-us/library/windows/desktop/gg537745

  param: "Verb" (For example, pass "RunAs" to run as administrator)
  param: Suggestion to the application about how to show its window

  see the msdn link above for detail values

  useful links:
https://autohotkey.com/board/topic/72812-run-as-standard-limited-user/page-2#entry522235
https://msdn.microsoft.com/en-us/library/windows/desktop/gg537745
https://stackoverflow.com/questions/11169431/how-to-start-a-new-process-without-administrator-privileges-from-a-process-with
https://autohotkey.com/board/topic/149689-lexikos-running-unelevated-process-from-a-uac-elevated-process/#entry733408
https://autohotkey.com/boards/viewtopic.php?t=4334



*/



ShellRun(prms*)
{
    global shell

    try {

        try {
            if (shell) {
                ; tip("使用缓存了的 shell 对象")
                shell.ShellExecute(prms*)
                return
            }
        } catch {
            tip("refresh object")
        }

        shellWindows := ComObjCreate("Shell.Application").Windows
        VarSetCapacity(_hwnd, 4, 0)
        desktop := shellWindows.FindWindowSW(0, "", 8, ComObj(0x4003, &_hwnd), 1)
    
        ; Retrieve top-level browser object.
        if ptlb := ComObjQuery(desktop
            , "{4C96BE40-915C-11CF-99D3-00AA004AE837}"  ; SID_STopLevelBrowser
            , "{000214E2-0000-0000-C000-000000000046}") ; IID_IShellBrowser
        {
            ; IShellBrowser.QueryActiveShellView -> IShellView
            if DllCall(NumGet(NumGet(ptlb+0)+15*A_PtrSize), "ptr", ptlb, "ptr*", psv:=0) = 0
            {
                ; Define IID_IDispatch.
                VarSetCapacity(IID_IDispatch, 16)
                NumPut(0x46000000000000C0, NumPut(0x20400, IID_IDispatch, "int64"), "int64")
            
                ; IShellView.GetItemObject -> IDispatch (object which implements IShellFolderViewDual)
                DllCall(NumGet(NumGet(psv+0)+15*A_PtrSize), "ptr", psv
                    , "uint", 0, "ptr", &IID_IDispatch, "ptr*", pdisp:=0)
            
                ; Get Shell object.
                shell := ComObj(9,pdisp,1).Application
            
                ; IShellDispatch2.ShellExecute
                shell.ShellExecute(prms*)
            
                ; ObjRelease(psv)
            }
            ; ObjRelease(ptlb)
        }
    }
    catch {
        tip("run failed")
    }
}

closeToolTip() {
    ToolTip,
}

tip(message, time:=-1500) {
    tooltip, %message%
    settimer, closeToolTip, %time%
}


;无视输入法中英文状态发送中英文字符串
;原理是, 发送英文时, 把它当做字符串来发送, 就像发送中文一样
;不通过模拟按键来发送,  而是发送它的Unicode编码
text(str)
{
    charList:=StrSplit(str)
	SetFormat, integer, hex
    for key,val in charList
    out.="{U+ " . ord(val) . "}"
	return out
}



GetProcessName(id:="") {
    if (id == "")
        id := "A"
    else
        id := "ahk_id " . id
    
    WinGet name, ProcessName, %id%
    if (name == "ApplicationFrameHost.exe") {
        ;ControlGet hwnd, Hwnd,, Windows.UI.Core.CoreWindow, %id%
        ControlGet hwnd, Hwnd,, Windows.UI.Core.CoreWindow1, %id%
        if hwnd {
            WinGet name, ProcessName, ahk_id %hwnd%
        }
    }
    return name
}


ProcessExist(name)
{
    process, exist, %name%
    if (errorlevel > 0)
        return errorlevel
    else
        return false
}


HasVal(haystack, needle)
{
	if !(IsObject(haystack)) || (haystack.Length() = 0)
		return 0
	for index, value in haystack
		if (value = needle)
			return index
	return 0
}


WinVisible(id)
{
    ;WingetPos x, y, width, height, ahk_id %id%
    WinGetTitle, title, ahk_id %id%
    ;WinGet, state, MinMax, ahk_id %id%
    ;tooltip %x% %y% %width% %height%

    ;sizeTooSmall := width < 300 && height < 300 && state != -1 ; -1 is minimized
    empty :=  !trim(title)
    ;if (!sizeTooSmall && !empty)
    ;    tooltip %x% %y% %width% %height% "%title%" 

    return  empty  ? 0 : 1
    ;return  sizeTooSmall || empty  ? 0 : 1
}


GetVisibleWindows(winFilter)
{
    ids := []

    WinGet, id, list, %winFilter%,,Program Manager
    Loop, %id%
    {
        if (WinVisible(id%A_Index%))
            ids.push(id%A_Index%)
    }

    if (ids.length() == 0)
    {

        pos := Instr(winFilter, "ahk_exe") - StrLen(winFilter) + StrLen("ahk_exe")
        pname := Trim(Substr(winFilter, pos))
        WinGet, id, list, ahk_class ApplicationFrameWindow
        loop, %id%
        {
            get_name := GetProcessName(id%A_index%)
            if (get_name== pname)
                ids.push(id%A_index%)
        }

    }
    return ids
}




ActivateOrRun(to_activate:="", target:="", args:="", workingdir:="", RunAsAdmin:=false) 
{
    to_activate := Trim(to_activate)
    ; WinShow, %to_activate%
    ; if (to_activate && winexist(to_activate))
    if (to_activate && firstVisibleWindow(to_activate))
        MyGroupActivate(to_activate)
    else if (target != "")
    {
        ;showtip("not exist, try to start !")
        if (RunAsAdmin)
            {
                if (substr(target, 1, 1) == "\")
                    target := substr(target, 2, strlen(target) - 1)
                Run, "%target%" %args%, %WorkingDir%
            }

        else
        {
            oldTarget := target
            target := WhereIs(target)
            if (target)
            {
                if (SubStr(target, -3) != ".lnk")
                    ShellRun(target, args, workingdir)
                else {
                    ; 检查 lnk 是否损坏
                    FileGetShortcut, %target%, OutTarget
                    ; if FileExist(OutTarget)
                    ShellRun(target, args, workingdir)
                }

            } else {
                try 
                {
                    if (workingdir && args) {
                        run, %oldTarget% %args%, %workingdir%
                    } 
                    else if (workingdir) {
                        run, %oldTarget%, %workingdir%
                    } 
                    else if (args) {
                        run, %oldTarget% %args%
                    }
                    else {
                        run, %oldTarget%
                    }
                }
                catch e 
                {
                    tip(e.message)
                } 
            }
        }

    }
}

WhereIs(FileName)
{
    ; https://autohotkey.com/board/topic/20807-fileexist-in-path-environment/


	; Working Folder
	PathName := A_WorkingDir "\"
	IfExist, % PathName FileName, Return PathName FileName

    ; absolute path
	IfExist, % FileName, Return FileName

	; Parsing DOS Path variable
	EnvGet, DosPath, Path
	Loop, Parse, DosPath, `;
	{
		IfEqual, A_LoopField,, Continue
		IfExist, % A_LoopField "\" FileName, Return A_LoopField "\" FileName
	}

	; Looking up Registry
	RegRead, PathName, HKLM, SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\%FileName%
	IfExist, % PathName, Return PathName

}


GroupAdd(ByRef GroupName, p1:="", p2:="", p3:="", p4:="", p5:="")
{
     static g:= 1
     If (GroupName == "")
        GroupName:= "AutoName" g++
     GroupAdd %GroupName%, %p1%, %p2%, %p3%, %p4%, %p5%
}

MyGroupActivate(winFilter) 
{

    winFilter := Trim(winFilter)
    if (!winactive(winFilter))
    {
        activateFirstVisible(winFilter)
        return
    }

    ; group 是窗口组对象, 这个对象无法获取内部状态, 所以用 win_group_array_form 来储存他的状态
    global win_group
    global win_group_array_form
    global last_winFilter


    ; 判断是否进入了新的窗口组
    if (winFilter != last_winFilter)
    {
        last_winFilter := winFilter
        win_group_array_form       := []
        win_group := ""    ; 建立新的分组
    }


    ; 对比上一次的状态, 获取新的窗口, 然后把新窗口添加到 win_group_array_form 状态和 win_group
    curr_group := GetVisibleWindows(winFilter)
    loop % curr_group.Length()
    {
        val := curr_group[A_Index]
        if (!HasVal(win_group_array_form, val))
        {
            win_group_array_form.push(val)
            GroupAdd(win_group, "ahk_id " . val)
        }
    }


    ; showtip( "total:"  win_group_array_form.length())
    GroupActivate, %win_group%, R
}

SwitchWindows()
{
    wingetclass, class, A
    if (class == "ApplicationFrameWindow") {
        WinGetTitle, title, A
        to_check := title . " ahk_class ApplicationFrameWindow"
    }
    else
        to_check := "ahk_exe " . GetProcessName()

    MyGroupActivate(to_check)
    return
}


activateFirstVisible(windowSelector)
{
    id := firstVisibleWindow(windowSelector)
    ; WinGet, State, MinMax, ahk_id %id%
    ; if (State = -1)
    ;     WinRestore, ahk_id %id%
    WinActivate, ahk_id %id%
}

firstVisibleWindow(windowSelector)
{
    WinGet, winList, List, %windowSelector%
    loop %winList%
    {
        item := winList%A_Index%
        WinGetTitle, title, ahk_id %item%
        ; if (Trim(title) != "") {
        WingetPos x, y, width, height, ahk_id %item%
        ; tip(width "-" height)
        if (Trim(title) != "" && (height > 20 || width > 20)) {
            return item
        }
    }
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





quit(ShowExitTip:=false)
{
    if (ShowExitTip)
    {
        ShowTip("Exit !")
        sleep 400
    }
    Menu, Tray, NoIcon 
    ; process, exist, KeyboardGeek.exe
    ; if (errorlevel > 0)
    ;     process, close, %errorlevel%
    ; process, close, ahk.exe
    myExit()
    exitapp
}


IsBrowser(pname)
{
    if pname in chrome.exe,MicrosoftEdge.exe,firefox.exe,360se.exe,opera.exe,iexplore.exe,qqbrowser.exe,sogouexplorer.exe
        return true
}

SmartCloseWindow()
{
    if (winactive("ahk_class WorkerW ahk_exe explorer.exe"))
        return

    WinGetclass, class, A
    name := GetProcessName()
    if IsBrowser(name)
        send ^w
    else if WinActive("- Microsoft Visual Studio ahk_exe devenv.exe")
        send ^{f4}
    else
    {
        if (class == "ApplicationFrameWindow"  || name == "explorer.exe")
            send !{f4}
        else
            PostMessage, 0x112, 0xF060,,, A
    }
}

dllMouseMove(offsetX, offsetY) {
    ; 需要在文件开头 CoordMode, Mouse, Screen
    ; MouseGetPos, xpos, ypos
    ; DllCall("SetCursorPos", "int", xpos + offsetX, "int", ypos + offsetY)    

    mousemove, %offsetX%, %offsetY%, 0, R
}

showMenu(window_id) {
    Prev_DetectHiddenWindows := A_DetectHiddenWindows
    DetectHiddenWindows On
    PostMessage, 0x5555,,,, ahk_id %window_id%
    DetectHiddenWindows %Prev_DetectHiddenWindows%
}


showXianyukangWindow() {
    Prev_DetectHiddenWindows := A_DetectHiddenWindows
    DetectHiddenWindows 1
    id := WinExist("ahk_class xianyukang_window")
    WinActivate, ahk_id %id%
    WinShow, ahk_id %id%
    DetectHiddenWindows %Prev_DetectHiddenWindows%
}



slowMoveMouse(key, direction_x, direction_y) {
    global slowMoveSingle, slowMoveRepeat, moveDelay1, moveDelay2 
    one_x := direction_x * slowMoveSingle
    one_y := direction_y * slowMoveSingle
    repeat_x := direction_x * slowMoveRepeat
    repeat_y := direction_y * slowMoveRepeat
    mousemove, %one_x% , %one_y%, 0, R
    keywait, %key%, %moveDelay1%
    while (errorlevel != 0)
    {
        mousemove, %repeat_x%, %repeat_y%, 0, R
        keywait,  %key%,  %moveDelay2%
    }
}

fastMoveMouse(key, direction_x, direction_y) {
    global fastMoveSingle, fastMoveRepeat, moveDelay1, moveDelay2, SLOWMODE
    SLOWMODE := true
    one_x := direction_x *fastMoveSingle 
    one_y := direction_y *fastMoveSingle 
    repeat_x := direction_x *fastMoveRepeat 
    repeat_y := direction_y *fastMoveRepeat 
    mousemove, %one_x% , %one_y%, 0, R
    keywait, %key%, %moveDelay1%
    while (errorlevel != 0)
    {
        mousemove, %repeat_x%, %repeat_y%, 0, R
        keywait,  %key%,  %moveDelay2%
    }
}


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


WaitThenCloseDimmer() {
    settimer , WaitThenCloseDimmer, 150
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
        settimer ,WaitThenCloseDimmer,off
    }
}




getProcessPath() 
{
    old := A_DetectHiddenWindows
    DetectHiddenWindows, 1
    winget, exeFullPath, ProcessPath, ahk_id %A_ScriptHwnd%
    winget, pid, PID, ahk_id %A_ScriptHwnd%
    DetectHiddenWindows, %old%

    pos := InStr(exeFullPath, "\",, 0)
    parentPath := substr(exeFullPath, 1, pos)
    return parentPath
}

moveActiveWindow()
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

exitMouseMode() 
{
    global SLOWMODE
    SLOWMODE := false
    send {blind}{Lbutton up}
}

centerMouse() 
{
    WingetPos x, y, width, height, A
    mousemove % x + width/2, y + height/2, 0
}

lbuttonDown() 
{
    send {Lbutton down}
}

leftClick() 
{
    global SLOWMODE
    send,  {blind}{LButton}
    SLOWMODE := false
}

rightClick(tempDisableRButton := false) 
{
    global SLOWMODE
    if (!tempDisableRButton)
        send,  {blind}{RButton}
    else {
        setHotkeyStatus("RButton", false)
        send,  {blind}{RButton}
        sleep, 70
        setHotkeyStatus("RButton", true)
    }
    SLOWMODE := false
}

ShowCommandBar()
{
    old := A_DetectHiddenWindows
    DetectHiddenWindows, 1
    PostMessage, 0x8003, 0, 0, , __KeyboardGeekInvisibleWindow
    DetectHiddenWindows, %old%
    ; winshow, __KeyboardGeekCommandBar
    ; winactivate, __KeyboardGeekCommandBar
}



arrayContains(arr, target) 
{
    for index,value in arr 
        if (value == target)
            return true
    return false
}

ReloadProgram()
{
    Menu, Tray, NoIcon 
    tooltip, ` ` Reload !` ` 
    run, MyKeymap.exe
    ExitApp
    ;run, "%exeFullPath%" Reload
    ;process, close, %pid%
    ;process, close, ahk.exe
}

slideToShutdown()
{
    run, SlideToShutDown
    sleep, 1300
    MouseClick, Left, 100, 100
}

slideToReboot()
{
    ; run, SlideToShutDown
    ; sleep, 1300
    ; MouseClick, Left, 100, 100
    ; sleep, 250
    shutdown, 2
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

center_window_to_current_monitor(width, height)
{
    ; 在 mousemove 时需要 PER_MONITOR_AWARE (-3), 否则当两个显示器有不同的缩放比例时,  mousemove 会有诡异的漂移
    ; 在 winmove   时需要 UNAWARE (-1),           这样即使写死了窗口大小为 1200x800,  系统会帮你缩放到合适的大小
    DllCall("SetThreadDpiAwarenessContext", "ptr", -1, "ptr")

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
    msw := msRight - msLeft
    msh := msBottom - msTop
    ; win_w := msw * 0.67
    ; win_h := (msw * 10 / 16) * 0.7
    ; win_w := Min(win_w, win_h * 1.54)
    win_w := width
    win_h := height
    win_x := msLeft + (msw - win_w) / 2
    win_y := msTop + (msh - win_h) / 2
    winmove,,, %win_x%, %win_y%, %win_w%, %win_h%
    DllCall("SetThreadDpiAwarenessContext", "ptr", -3, "ptr")
}

winMinimizeIgnoreDesktop() 
{
    ; 如果是这个窗口是桌面就返回
    if (winactive("ahk_class WorkerW ahk_exe explorer.exe"))
        return
    ; if (winactive("ahk_class CabinetWClass ahk_exe explorer.exe"))
    ;     return
    if (winactive("ahk_exe Rainmeter.exe"))
        return

    WinMinimize, A
}


scrollOnce(direction, scrollCount :=1)
{
    if (direction == 1) {
        MouseClick, WheelUp, , , %scrollCount%
    }
    if (direction == 2) {
        MouseClick, WheelDown, , , %scrollCount%
    }
    if (direction == 3) {
        MouseClick, WheelLeft, , , %scrollCount%
    }
    if (direction == 4) {
        MouseClick, WheelRight, , , %scrollCount%
    }
}
scrollWheel(key, direction) {
    global scrollOnceLineCount, scrollDelay1, scrollDelay2 
    scrollOnce(direction, scrollOnceLineCount)
    keywait, %key%, %scrollDelay1%
    while (errorlevel != 0)
    {
        scrollOnce(direction)
        keywait,  %key%,  %scrollDelay2%
    }
}

toggleCapslock() {
    ; 方案 2,  未测试
    send, {Blind}{Lctrl}{LAlt UP}{CapsLock}
    
    ; 方案 1,  输入法大小写指示可能不对
    ; newState := !GetKeyState("CapsLock", "T")
    ; SetCapsLockState %newState%
    ; if (newState)
    ;     tip("CapsLock 开启", -400)
    ; else
    ;     tip("CapsLock 关闭", -400)
}


surroundWithSpace(message) {
    return "   " . message . "   "
}


copySelectedText()
{
    ; old_clipboard := clipboardall
    clipboard =
    send ^c
    ; send ^{insert}
    clipwait, 0.5, 1

    if (errorlevel) {
        tip("copy text failed", -700)
        return ""
    }

    r := rtrim(clipboard, "`n")
    return r
}

addHtmlStyle(text, style )
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

ToggleTopMost()
{
    winexist("A")
    WinGet, style, ExStyle
    if (style & 0x8) {
         style := "  取消置顶  "
         winset, alwaysontop, off
    }
    else {
         style := "  窗口置顶  "
         winset, alwaysontop, on
    }
    ; tip(style, -500)
}

htmlEscape(text) 
{
    text := strReplace(text, "&", "&amp;")
    text := strReplace(text, "<", "&lt;")
    text := strReplace(text, ">", "&gt;")
    text := strReplace(text, """", "&quot;")
    text := strReplace(text, " ", "&nbsp;")
    return text
}

setHtml(html)
{
    s := "<HTML> <head><meta http-equiv='Content-type' content='text/html;charset=UTF-8'></head> <body> <!--StartFragment-->"
    s .= html
    s .= "<!--EndFragment--></body></HTML> "
    dllcall("clip_dll.dll\setHtml", "Str", s)
}

setColor(color := "#000000", fontFamily:= "Iosevka") 
{
    text := copySelectedText()
    if (!text) {
        return
    }

    style := "color: " color "; font-family: " fontFamily ";"
    html := addHtmlStyle(text, style)
    md := "<font color='{{color}}'>{{text}}</font>"

    if (WinActive(" - Typora")) {
        md := strReplace(md, "{{text}}", text)
        md := strReplace(md, "{{color}}", color)
        clipboard := md
    } else {
        ; sleep 200
        setHtml( html )
        ; sleep 300
        Sleep, 100
    }

    send {LShift down}{Insert down}{Insert up}{LShift up}
}


class TypoTipWindow
{
    __New()
    {

        text := "               "                       ; 初始化 text control 的宽度
        fontSize := 12
        Font_Colour := 0x0 ;0x2879ff
        Back_Colour := 0xffffe1 ; 0x34495e

        Gui, TYPO_TIP_WINDOW:New, +hwndhGui, ` 
        this.hwnd := hGui                           ; 保存 hwnd 目前没什么用

        Gui, +Owner +ToolWindow +Disabled -SysMenu -Caption +E0x20 +AlwaysOnTop +Border
        GUI, Margin, %fontsize%, % fontsize / 5
        GUI, Color, % Back_Colour
        GUI, Font, c%Font_Colour% s%fontsize%, Microsoft Sans Serif

        static ControlID                            ; 存储控件 ID,  不同于 Hwnd
        GUI, Add, Text, vControlID center, %text%
        GuiControlGet, OutputVar, Hwnd , ControlID  ; 获取 Hwnd
        this.textHwnd := OutputVar                  ; 保存到对象属性

        Gui, TYPO_TIP_WINDOW:Show, Hide
    }

    show(text) {
        GuiControl, Text, % this.textHwnd, %text%
        MouseGetPos, xpos, ypos 
        xpos += 10
        ypos += 7
        Gui, TYPO_TIP_WINDOW:Show, AutoSize Center NoActivate x%xpos% y%ypos%
    }
    
    hide() {
        Gui, TYPO_TIP_WINDOW:Show, Hide
    }
}

myExit()
{
    Menu, Tray, NoIcon 
    thisPid := DllCall("GetCurrentProcessId")
    Process, Close, %thisPid%
}

requireAdmin()
{
   if not A_IsAdmin
   {
      try {
         Run *RunAs "MyKeymap.exe" ; 需要 v1.0.92.01+
         myExit()
      }
      catch {
        tip("MyKeymap 当前以普通权限运行 `n在一些高权限窗口中会完全失效 (比如任务管理器)", -3700)
      }
   }
}

getProcessList(pname)
{
   result := []
   for proc in ComObjGet("winmgmts:").ExecQuery("SELECT Name,Handle FROM Win32_Process WHERE Name='MyKeymap.exe'")
      result.push(proc.Handle)
   return result
}

closeOldInstance()
{

   thisPid := DllCall("GetCurrentProcessId")
   for index,pid in getProcessList("MyKeymap.exe")
   {
      if (pid != thisPid) {
         Process, Close, %pid%
        ;  tip("  Reload  ", -400)
      }
   }
}


openSettings()
{
    run, bin\ahk.exe bin\openSettings.ahk
}

setHotkeyStatus(theHotkey, enableHotkey)
{
    global allHotkeys
    for index,value in allHotkeys
    {
        if (value == theHotkey) {
            if (enableHotkey)
                hotkey, %theHotkey%, on
            else
                hotkey, %theHotkey%, off
        }
    }
}

disableOtherHotkey(thisHotkey)
{
    global allHotkeys
    ; ToolTip, % thisHotkey
    for index,value in allHotkeys
    {
        if (value != thisHotkey) {
            hotkey, %value%, off
        }
    }
    
}

enableOtherHotkey(thisHotkey)
{
    global allHotkeys
    ; ToolTip, % thisHotkey
    for index,value in allHotkeys
    {
        if (value != thisHotkey) {
            hotkey, %value%, on
        }
    }
    
}

toggleSuspend()
{
        Suspend, Toggle
        if (A_IsSuspended) {
            Menu, Tray, Check, 暂停
            tip("  暂停 MyKeymap  ", -500)
        }
        else {
            Menu, Tray, UnCheck, 暂停
            tip("  恢复 MyKeymap  ", -500)
        }
}

trayMenuHandler(ItemName, ItemPos, MenuName)
{
    if (InStr(ItemName, "退出" )) {
        myExit()
    }
    if (InStr(ItemName, "暂停" )) {
        toggleSuspend()
    }
    if (InStr(ItemName, "打开设置" )) {
        openSettings()
    }
    if (InStr(ItemName, "检查更新" )) {
        run, https://xianyukang.com/MyKeymap-Change-Log.html
    }
    if (InStr(ItemName, "视频教程" )) {
        run, https://space.bilibili.com/34674679
    }
    if (InStr(ItemName, "帮助文档" )) {
        run, https://xianyukang.com/MyKeymap.html
    }
    if (InStr(ItemName, "查看窗口标识符" )) {
        run, bin\ahk.exe bin\WindowSpy.ahk
    }

}

moveCurrentWindow()
{
    PostMessage, 0x0112, 0xF010, 0,, A
    sleep 50
    SendInput, {right}
}

bindOrActivate(ByRef id)
{
    old := A_DetectHiddenWindows
    DetectHiddenWindows, 1
    if WinActive("ahk_id " id) {
        ; id := ""
        ; tip("取消绑定", -400)
    }
    else if WinExist("ahk_id " id) {
        WinActivate
    }
    else {
        tip("绑定当前窗口到 " A_ThisHotkey " 键", -400)
        id := WinExist("A")
    }
    DetectHiddenWindows, %old%
}

toggleAutoHideTaskBar()
{
    VarSetCapacity(APPBARDATA, A_PtrSize=4 ? 36:48)
    NumPut(DllCall("Shell32\SHAppBarMessage", "UInt", 4 ; ABM_GETSTATE
                                           , "Ptr", &APPBARDATA
                                           , "Int")
 ? 2:1, APPBARDATA, A_PtrSize=4 ? 32:40) ; 2 - ABS_ALWAYSONTOP, 1 - ABS_AUTOHIDE
 , DllCall("Shell32\SHAppBarMessage", "UInt", 10 ; ABM_SETSTATE
                                    , "Ptr", &APPBARDATA)
}

restartExplorer()
{
    run, tools\Rexplorer_x64.exe
}

toggleRemoveTaskBar()
{
    ; 下面的软件能完全移除 TaskBar 但个人偏好「 自动隐藏任务栏 」
    global HIDE_TASK_BAR
    HIDE_TASK_BAR := !HIDE_TASK_BAR
    if (HIDE_TASK_BAR) {
        runwait, tools\TaskBarHider.exe -hide -exit
        run, tools\TaskBarHider.exe -hide -exit
    }
    else {
        run, tools\TaskBarHider.exe -show -exit
    }
}


enterJModeL()
{
    global
    JModeL := true
    keywait l
    JModeL := false
}

actionAddSpaceBetweenEnglishChinese()
{
    text := copySelectedText()
    if (!text) {
        return
    }

    clipboard := addSpaceBetweenEnglishChinese(text)
    send {LShift down}{Insert down}{Insert up}{LShift up}
}

addSpaceBetweenEnglishChinese(str) {
    ; 参考 https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Guide/Regular_Expressions/Assertions

    ; 前面加空格,  使用 look behind,  当英文在非英文之后时匹配
    regexp := "(?<=[^ -~])([!-~]+)"
    replacement := " $1"
    str := RegExReplace(str, regexp, replacement)
    ; 后面加空格, 使用 look ahead,  当英文在非英文之前时匹配
    regexp := "([!-~]+)(?=[^ -~])"
    replacement := "$1 "
    str := RegExReplace(str, regexp, replacement)
    ; 去除两端空格
    ; return Trim(str)
    return str
}



; 参考 => https://www.autohotkey.com/boards/viewtopic.php?p=255256#p255256
; 返回文件管理器中选中的文件列表
; 如果没有选中任何东西,  返回当前所在文件夹的路径 (甚至是 shell clsid,  amazing !)
Explorer_GetSelection() 
{
    WinGetClass, winClass, % "ahk_id" . hWnd := WinExist("A")
    if !(winClass ~="Progman|WorkerW|(Cabinet|Explore)WClass")
        Return

    shellWindows := ComObjCreate("Shell.Application").Windows
    if (winClass ~= "Progman|WorkerW")
        shellFolderView := shellWindows.FindWindowSW(0, 0, SWC_DESKTOP := 8, 0, SWFO_NEEDDISPATCH := 1).Document
    else {
        for window in shellWindows
            if (hWnd = window.HWND) && (shellFolderView := window.Document)
            break
    }
    ; FolerItem 对象参考 => https://docs.microsoft.com/en-us/windows/win32/shell/folderitem
    ; for item in shellFolderView.SelectedItems
    ;     result .= (result = "" ? "" : "`n") . item.Path
    ; if !result
    ;     result := shellFolderView.Folder.Self.Path
    ; Return """" StrReplace(result, "`n", """ """)  """"

    res := {}
    res.current := shellFolderView.Folder.Self.Path

    paths := ""
    for item in shellFolderView.SelectedItems
    {
        paths .= (paths == "" ? "" : " ") . ("""" item.Path """")
        res.filename := item.Name
    }
    res.selected := paths ? paths : res.current

    res.purename := res.filename
    if (res.filename && ( pos := InStr(res.filename, ".", false, 0))) {
        res.purename := SubStr(res.filename, 1 , pos - 1)
    }

    ; MsgBox, % "current: " res.current "`npaths: " res.selected "`nfilename: " res.filename "`npurename: " res.purename
    Return res
}


setCommandInputHwnd(hwnd)
{
    global commandInputHwnd
    commandInputHwnd := hwnd
}

postCharToTipWidnow(char) {
    global commandInputHwnd
    oldValue := A_DetectHiddenWindows
    DetectHiddenWindows, 1
    ; if WinExist("ahk_class MyKeymap_Command_Input")
    ;     PostMessage, 0x0102, Ord(char), 0
    PostMessage, 0x0102, Ord(char), 0,, ahk_id %commandInputHwnd%
    DetectHiddenWindows, %oldValue%
}

postMessageToTipWidnow(messageType) {
    global commandInputHwnd
    oldValue := A_DetectHiddenWindows
    DetectHiddenWindows, 1
    ; if WinExist("ahk_class MyKeymap_Command_Input")
    ;     PostMessage, %messageType%, 0, 0
    PostMessage, %messageType%, 0, 0,, ahk_id %commandInputHwnd%
    DetectHiddenWindows, %oldValue%
}