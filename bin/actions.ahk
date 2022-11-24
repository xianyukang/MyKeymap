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
    global TASK_SWITCH_MODE, keymapLockState, CapslockMode, TabMode, DigitMode, SpaceMode, Mode9, FMode, CapslockSpaceMode, SemicolonMode, CommaMode, DotMode
    CapslockMode := false
    TabMode := false
    DigitMode := false
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

action_lock_current_mode()
{
    global keymapLockState, SLOWMODE

    currentMode := keymapLockState.currentMode
    keymapLockState.clear := false

    if keymapLockState.locked {
        SLOWMODE := false
        %currentMode% := false
        keymapLockState.locked := false
        tip("取消锁定", -400)
    } else {
        keymapLockState.locked := true
        tip("锁定当前模式", -400)
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