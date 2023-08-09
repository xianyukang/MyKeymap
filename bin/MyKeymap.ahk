#SingleInstance Force
; 解决「 winactivate 最小化的窗口时不会把窗口放到顶层(被其他窗口遮住)
#WinActivateForce
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

ListLines false ; 不记录日志
ProcessSetPriority "High" ; 高线程响应
; 使用 sendinput 时,  通过 alt+3+j 输入 alt+1 时,  会发送 ctrl+alt
SendMode "Input"

SetMouseDelay 0 ; 发送完一个鼠标后不会sleep
SetDefaultMouseSpeed 0 ; 设置鼠标移动的速度
CoordMode("Mouse", "Screen") ; 鼠标坐标相对于活动窗口
SetTitleMatchMode(2) ; WinTitle匹配时窗口标题只要包含就可以
; 多显示器不同缩放比例导致的问题,  https://www.autohotkey.com/boards/viewtopic.php?f=14&t=13810
DllCall("SetThreadDpiAwarenessContext", "ptr", -3, "ptr")

; 自定义热键
customHotKey := true
; 已启动的热键
activatedModes := []
; 热键状态
modeState := { currentName: "", currentRef: "", locked: false }
; 当模拟ALT+TAB或Alt+shift+table时松手退出选择任务页面用
altTabIsOpen := false

; ===============      模式定义      ========================
capslockMode := false
jMode := false
semicolonMode := false
threeMode := false
nincMode := false
commaMode := false
dotModel := false
additionalMode1 := false
additionalMode2 := false
spaceMode := false
tabMode := false
rButtonMode := false
lButtonMode := false

capsFMode := false
capsSpaceMode := false
jKModel := false

mouseMode := false
TaskSwitchMode := false

; =============== 以下为读取的配置信息 =======================
configVer := ""


; 鼠标点击后退出鼠标模式
needExitMouseMode := true

scrollOnceLineCount := 3
scrollDelay1 := "T0.2"
scrollDelay2 := "T0.01"
fastMoveSingle := 110
fastMoveRepeat := 70
slowMoveSingle := 10
slowMoveRepeat := 13
moveDelay1 := "T0.2"
moveDelay2 := "T0.01"

activatedModes.Push("CapsLock")
activatedModes.Push("Tab")

CapsLock:: {
  global capslockMode
  EnableMode(&capslockMode, "capslockMode", 350, () => MsgBox("大小写"))
}

Tab:: {
  global tabMode
  EnableMode(&tabMode, "tabMode", 350, () => MsgBox("TAB模式"))
}

#HotIf capslockMode
a:: MsgBox("Cpas模式")
s:: MsgBox("Cpas模式")
f:: {
  global capslockMode, capsFMode
  capslockMode := false
  EnableMode(&capsFMode, "capsFMode", , , false)
  capslockMode := true
}
z:: LockCurrentMode()

#HotIf tabMode
a:: MsgBox("J模式")

#HotIf capsFMode
a:: MsgBox("CapsF 模式")


#HotIf mouseMode
*/:: MouseToActiveWindowCenter()
*,:: LbuttonDown()
*N:: LbuttonClick()
*.:: MouseMoveActiveWindowPos()
*M:: RbuttonClick()
*':: scrollWheel("'", 4)
*I:: scrollWheel("I", 3)
*O:: scrollWheel("O", 2)
*U:: scrollWheel("U", 1)
*H:: slowMoveMouse("H", -1, 0)
*J:: slowMoveMouse("J", 0, 1)
*K:: slowMoveMouse("K", 0, -1)
*L:: slowMoveMouse("L", 1, 0)


Esc:: exitMouseMode()
*Space:: exitMouseMode()