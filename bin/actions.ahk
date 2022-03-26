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

action_enter_task_switch_mode()
{
    global TASK_SWITCH_MODE, CapslockMode
    CapslockMode := false
    TASK_SWITCH_MODE := true
    send, ^!{tab}
    WinWaitActive, ahk_group TASK_SWITCH_GROUP,, 0.5
    if (!ErrorLevel) {
        WinWaitNotActive, ahk_group TASK_SWITCH_GROUP
    }
    TASK_SWITCH_MODE := false
}