#SingleInstance Force
#NoTrayIcon
#WinActivateForce ; 解决「 winactivate 最小化的窗口时不会把窗口放到顶层(被其他窗口遮住) 」
InstallKeybdHook ; 强制安装键盘钩子
A_MaxHotkeysPerInterval := 70

#Include lib/Fcunctions.ahk
#Include lib/Actions.ahk

MsgBox(A_WorkingDir)

