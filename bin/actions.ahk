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
    WinExist("A")
    WinGet, state, MinMax
    if state
        WinRestore
    WinMove, , , %x%, %y% , %width%, %height%
}

action_enter_task_switch_mode()
{
    global TASK_SWITCH_MODE, CapslockMode, TabMode, DigitMode, SpaceMode, Mode9, FMode, CapslockSpaceMode, PunctuationMode, CommaMode, DotMode
    CapslockMode := false
    TabMode := false
    DigitMode := false
    SpaceMode := false
    Mode9 := false
    FMode := false
    CapslockSpaceMode := false
    PunctuationMode := false
    CommaMode := false
    DotMode := false

    TASK_SWITCH_MODE := true
    send, ^!{tab}
    WinWaitActive, ahk_group TASK_SWITCH_GROUP,, 0.5
    if (!ErrorLevel) {
        WinWaitNotActive, ahk_group TASK_SWITCH_GROUP
    }
    TASK_SWITCH_MODE := false
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
        ShellRun(url)
    }
}

run_as_admin(path, args:="", working_dir:="")
{
    Run *RunAs %path% %args%, %working_dir%
}

action_lock_current_mode()
{
    global lockCurrentMode, currentMode, SLOWMODE

    if lockCurrentMode {
        SLOWMODE := false
        %currentMode% := false
        tip("取消锁定", -400)
    } else {
        lockCurrentMode := true
        tip("锁定当前模式", -400)
    }

}

action_toggle_slow_mode()
{
    global SWITCH_TO_SLOWMODE
    SWITCH_TO_SLOWMODE := !SWITCH_TO_SLOWMODE
}