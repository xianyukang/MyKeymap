#SingleInstance Force
; #NoTrayIcon
#WinActivateForce ; 解决「 winactivate 最小化的窗口时不会把窗口放到顶层(被其他窗口遮住) 」
InstallKeybdHook ; 强制安装键盘钩子
A_MaxHotkeysPerInterval := 70
SetWorkingDir("../")

#Include lib/Fcunctions.ahk
#Include lib/Actions.ahk

; 托盘菜单
A_TrayMenu.Delete
A_TrayMenu.Add("暂停", TrayMenuHandler)
A_TrayMenu.Add("退出", TrayMenuHandler)
A_TrayMenu.Add("重启程序", TrayMenuHandler)
A_TrayMenu.Add("打开设置", TrayMenuHandler)
A_TrayMenu.Add("帮助文档", TrayMenuHandler)
A_TrayMenu.Add("查看窗口标识符", TrayMenuHandler)
A_TrayMenu.Default := "暂停"
A_TrayMenu.ClickCount := 1

A_IconTip := "MyKeymap 2.0.0 by 咸鱼阿康"
TraySetIcon("./bin/icons/logo.ico")

#1::(Run("note"))