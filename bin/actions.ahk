action_copy_selected_file_path()
{
    clipboard := Explorer_GetSelection().selected
    tip("复制了: " clipboard, -1000)
}

action_open_selected_with(toRun, cmdArgs)
{
    ; msgbox, % cmdArgs
    ActivateOrRun("", toRun, cmdArgs) 
}

action_align_text()
{
    if (copySelectedText()) {
        runwait, cmd.exe /c ahk.exe ClipboardPipe.ahk | settings.exe AlignText, bin\, Hide
        RealShellRun("msedge.exe", "--app=" A_WorkingDir "\bin\html-tools\AlignText.html")
    }
}

wrap_selected_text(format)
{
    if (txt := copySelectedText()) {
        Clipboard := StrReplace(format, "{text}", txt)
        send, +{insert}
        return
    }
}

set_window_position_and_size(x, y, width, height)
{
    if IsDesktopWindowActive()
        return
    hwnd := WinExist("A")
    WinGet, state, MinMax
    if state
        WinRestore
    offset := GetWindowPositionOffset(hwnd)
    WinMove, , , % x+offset.x, % y+offset.y , % width+offset.width, % height+offset.height
}

action_enter_task_switch_mode()
{
    global TASK_SWITCH_MODE, keymapLockState, CapslockMode, TabMode, Mode3, SpaceMode, Mode9, FMode, CapslockSpaceMode, SemicolonMode, CommaMode, DotMode
    CapslockMode := false
    TabMode := false
    Mode3 := false
    SpaceMode := false
    Mode9 := false
    FMode := false
    CapslockSpaceMode := false
    SemicolonMode := false
    CommaMode := false
    DotMode := false

    TASK_SWITCH_MODE := true
    send, ^!{tab}
    WinWaitActive, ahk_group TASK_SWITCH_GROUP,, 0.5
    if (!ErrorLevel) {
        WinWaitNotActive, ahk_group TASK_SWITCH_GROUP
    }
    TASK_SWITCH_MODE := false

    ; 全都关了,  得恢复一下
    if (keymapLockState.locked) {
        currentMode := keymapLockState.currentMode
        %currentMode% := true
    }
}

action_hold_down_shift_key()
{
    send, {LShift down}
    key := LTrim(A_ThisHotkey, "*")
    keywait, %key%
    send, {LShift up}
}

activate_it_by_hotkey_or_run(process_name, activation_hotkey, target, args:="", workingdir:="")
{
    if ProcessExist(process_name) {
        send, %activation_hotkey%
    } else {
        ActivateOrRun2("", target, args, workingdir)
    }
}

launch_multiple(urls*)
{
    for index,url in urls {
        RealShellRun(url)
    }
}

run_as_admin(path, args:="", working_dir:="")
{
    Run *RunAs %path% %args%, %working_dir%
}


ResetCurrentModeLockState(currentMode)
{
    global keymapLockState
    if keymapLockState.locked {
        return
    }
    keymapLockState.currentMode := currentMode
}

action_lock_current_mode()
{
    global keymapLockState, SLOWMODE

    currentMode := keymapLockState.currentMode

    if keymapLockState.locked {
        SLOWMODE := false
        %currentMode% := false
        keymapLockState.locked := false
        tip(" 取消锁定 ", -400)
    } else {
        keymapLockState.locked := true
        tip(" 锁定 → " Trim(currentMode, "Mode") " ", -400)
    }

}

toggle_dark_mode()
{
    RegRead,L_LightMode,HKCU,SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize,SystemUsesLightTheme
    If L_LightMode {
        ; write both system end App lightmode to the registry
        RegWrite,Reg_Dword,HKCU,SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize,SystemUsesLightTheme,0
        RegWrite,Reg_Dword,HKCU,SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize,AppsUseLightTheme ,0
    }
    else {
        ; write both system end App lightmode to the registry
        RegWrite,Reg_Dword,HKCU,SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize,SystemUsesLightTheme,1
        RegWrite,Reg_Dword,HKCU,SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize,AppsUseLightTheme ,1
    }
    ; tell the system it needs to refresh the user settings
    ; run,RUNDLL32.EXE USER32.DLL`, UpdatePerUserSystemParameters `,2 `,True
}

防止J模式误触(text) {
    global JMode
    JMode := false
    send, %text%
}

close_same_class_window()
{
    ; 避免把桌面关了
    if (WinActive("Program Manager ahk_class Progman") || WinActive("ahk_class WorkerW")) {
        return
    }

    WinGetClass, className, A
    WinGet, winList, List, ahk_class %className%

    loop %winList%
    {
        id := winList%A_Index%
        WinClose, ahk_id %id%
        ; WinWaitClose, ahk_id %id%, , 0.1
        if ErrorLevel {
            ; break
        }
    }
}

onenote_up() 
{
    if WinActive("ahk_exe onenote.exe") {
        if GetKeyState("Shift") {
            send, ^+{up}
        } else {
            vk_up := 0x26
            dllcall("keybd_event","UChar", vk_up, "UChar", 0, "UInt", 0, "Ptr", 0 )
            dllcall("keybd_event","UChar", vk_up, "UChar", 0, "UInt", 0x0002, "Ptr", 0 )
        }
    } else {
        send, {blind}{up}
    }
}
onenote_shift_up() 
{
    if WinActive("ahk_exe onenote.exe") {
        send, ^+{up}
    } else {
        send, {blind}+{up}
    }
}
onenote_down() 
{
    if WinActive("ahk_exe onenote.exe") {
        if GetKeyState("Shift") {
            send, ^+{down}
        } else {
            vk_down := 0x28
            dllcall("keybd_event","UChar", vk_down, "UChar", 0, "UInt", 0, "Ptr", 0 )
            dllcall("keybd_event","UChar", vk_down, "UChar", 0, "UInt", 0x0002, "Ptr", 0 )
        }
    } else {
        send, {blind}{down}
    }
}
onenote_shift_down() 
{
    if WinActive("ahk_exe onenote.exe") {
        send, ^+{down}
    } else {
        send, {blind}+{down}
    }
}

close_window_processes()
{
    if (WinActive("Program Manager ahk_class Progman") || WinActive("ahk_class WorkerW")) {
        return
    }
    WinGet, pname, ProcessName, A
    if (pname = "explorer.exe") {
        return
    }
    run, taskkill /f /im "%pname%", , Hide
}