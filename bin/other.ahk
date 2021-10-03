#NoEnv
#SingleInstance Force
#NoTrayIcon
ListLines Off
SetWorkingDir %A_ScriptDir%\..
MyKeymapLnk = %A_Startup%\MyKeymap.lnk

if (A_Args[1] == "enableRunOnStartup") {
    FileCreateShortcut, %A_WorkingDir%\MyKeymap.exe, %MyKeymapLnk%, %A_WorkingDir%
}
if (A_Args[1] == "disableRunOnStartup") {
    FileDelete, %MyKeymapLnk%
}