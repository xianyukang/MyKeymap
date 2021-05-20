#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#SingleInstance, force
; #WinActivateForce

; 如果需要获取窗口的 icon,  可以参考 https://docs.microsoft.com/en-us/windows/win32/winmsg/wm-geticon

DetectHiddenWindows, 1
OnMessage(0x0100, "wm_keydown_handler")

; Create the ListView with two columns, Name and Size:
Gui, Font, s12,
; Gui, Add, Edit, r1 vMyEdit w700 gMyInputBox, 
Gui, Add, ListView, r20 w700 vMyList gMyListView, Window Title|Process Name

; Gather a list of file names from a folder and put them into the ListView:

windowList := getOpenWindows()
renderList(windowList)


; Display the window and return. The script will be notified whenever the user double clicks a row.
Gui, Show
return

MyListView:
if (A_GuiEvent = "DoubleClick")
{
    LV_GetText(RowText, A_EventInfo)  ; Get the text from the row's first field.
    ToolTip You double-clicked row number %A_EventInfo%. Text: "%RowText%"
}
tooltip, % A_GuiEvent
return

MyInputBox:
; if (A_GuiEvent = "Normal")
; {
;     GuiControlGet, currentText,, MyEdit
;     windowList := getWindowList()
;     filtered := filterWindowList(windowList, currentText)
;     renderList(filtered)
; }
return


GuiClose:  ; Indicate that the script should exit automatically when the window is closed.
ExitApp

renderList(windowList) {
    LV_Delete()
    for index,value in windowList {
        WinGetTitle, title, ahk_id %value%
        LV_Add("", title, "xxx.exe")
    }

    LV_ModifyCol(1, "AutoHdr")  ; Auto-size each column to fit its contents.
    LV_ModifyCol(2, "AutoHdr")  ; Auto-size each column to fit its contents.
}

filterWindowList(windowList, input) {
    array := []
    for index,value in windowList {
        if (InStr(value, input)) {
            array.push(value)
        }
    }
    return array
}

getWindowList() {
    array := []
    array[0] := "Chrome"
    array[1] := "Visual Studio Code"
    array[2] := "onenote"
    array[3] := "evernote"
    array[4] := "idea"
    array[5] := "windows"
    return array
}

$9::
SetTitleMatchMode, 2
title := "Visual Studio Code"
WinActivate, %title%
return

wm_keydown_handler(wParam, lParam)
{
    global windowList
    key := GetKeyName("VK" SubStr(Format("0x{:#x}", wParam), 3)) 
    if (key == "Escape") {
        ExitApp
    }
    if (key == "Enter") {
        focused_row_numer := LV_GetNext()
        focused_row_text := windowList[focused_row_numer]
        winactivate, % "ahk_id " windowList[focused_row_numer]
        ExitApp
        ; tooltip,% focused_row_text
    }
    ; if (key == "NumpadDown") {
    ;     tooltip, down
    ;     GuiControl, Focus, MyList
    ; }
}



getOpenWindows(detectAllVirtualDesktop:=true) {
    windwBlackList := "计算器,MainWindow,Groove 音乐,Microsoft Text Input Application,Program Manager,dummyLayeredWnd,设置"
    processBlcakList := "Rainmeter.exe"
    if (detectAllVirtualDesktop) {
        DetectHiddenWindows, 1
    }
    WinGet windows, List
    r := []
    Loop %windows%
    {
        id := windows%A_Index%
        WinGet, style, style, ahk_id %id%
        if !(style & 0x10000000) {  ; visible
            continue
        }
        ; if !(style & 0x80000) {  ; sys menu
        ;     continue
        ; }
        ; if !(style & 0x40000) {  ; has taskbar icon
        ;     continue
        ; }
        WinGetTitle title, ahk_id %id%
        if (trim(title) == "" || InStr(windwBlackList, title)) { 
            continue
        }
        WinGet, pname, ProcessName, ahk_id %id%
        if (InStr(processBlcakList, pname)) { 
            continue
        }

        r.push(id)
    }
    return r
}