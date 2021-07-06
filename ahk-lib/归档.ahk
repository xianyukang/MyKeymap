#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.



; 曾今用于处理一批 corner case
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