#SingleInstance Force
; 解决「 winactivate 最小化的窗口时不会把窗口放到顶层(被其他窗口遮住)
#WinActivateForce
InstallKeybdHook ; 强制安装键盘钩子
A_MaxHotkeysPerInterval := 70
SetWorkingDir("../")

#Include lib/Fcunctions.ahk
#Include lib/Actions.ahk

; 托盘菜单
A_TrayMenu.Delete()
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

ListLines(false) ; 不记录日志
ProcessSetPriority("High") ; 高线程响应
; 使用 sendinput 时,  通过 alt+3+j 输入 alt+1 时,  会发送 ctrl+alt
SendMode("Input")

SetMouseDelay(0) ; 发送完一个鼠标后不会sleep
SetDefaultMouseSpeed(0) ; 设置鼠标移动的速度
CoordMode("Mouse", "Screen") ; 鼠标坐标相对于活动窗口
SetTitleMatchMode(2) ; WinTitle匹配时窗口标题只要包含就可以
; 多显示器不同缩放比例导致的问题,  https://www.autohotkey.com/boards/viewtopic.php?f=14&t=13810
DllCall("SetThreadDpiAwarenessContext", "ptr", -3, "ptr")
SetWinDelay(0)

; 记录Caps缩写的Pid
capsAbbrWindowPid := ""
; 自定义热键
customHotKey := true
; 已启动的热键
activatedModes := []
; 热键状态
modeState := { currentName: "", currentRef: "", locked: false }
; 当模拟ALT+TAB或Alt+shift+table时松手退出选择任务页面用
altTabIsOpen := false
; 含有绑定key 和ahk_id 的对应关系
bindWindowMap := Map()

; Windows10、Windows11的任务切换视图类名
GroupAdd("taskSwitchGroup", "ahk_class MultitaskingViewFrame")
GroupAdd("taskSwitchGroup", "ahk_class XamlExplorerHostIslandWindow")

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

; ===============      模式定义      ========================
OnExit(MyExit)
; 当有异常时退出所有模式
OnError(CloseAllMode)

; ===============    以下为配置信息    =======================
configVer := ""

; ===============      命令窗口      ========================
; todo: 添加一个判断，如果选择了命令窗口则生成以下内容，否则不生成
capsHook := InputHook(, "{Capslock}{BackSpace}{Esc}", "dd,df,se")
capsHook.KeyOpt("{CapsLock}", "S")
capsHook.OnChar := PostCharToCaspAbbr
Run("bin\MyKeymap-CommandInput.exe", , , &capsAbbrWindowPid)

semiHook := InputHook("", "{CapsLock}{BackSpace}{Esc}{;}{Space}", "dd")
semiHook.OnChar := (ih, char) => semiHookAbbrWindow.Show(char)
semiHookAbbrWindow := TypoTipWindow()

; ===============       内置组       ========================
GroupAdd("makrdownGroup", "ahk_exe Obsidian.exe")


; ===============        热键        ========================
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
  EnableMode(&capslockMode, "capslockMode", 350, EnterCapslockAbbr)
}

Tab:: {
  global tabMode
  EnableMode(&tabMode, "tabMode", 350, () => MsgBox("TAB模式"))
}

#;:: Reload()

#HotIf capslockMode
a:: toggleCapslock()
s:: BindOrActivate("Capslock S")
d:: UnBindWindow()
q:: CloseSameClassWindows()
w:: ActivateOrRun(, "ms-settings:autoplay", , , false)
e:: EnableTaskSwitchMode()
r:: ActivateOrRun(, "D:\")
t:: ActivateOrRun(, "fsdjk.exe")

f:: {
  global capslockMode, capsFMode
  capslockMode := false
  EnableMode(&capsFMode, "capsFMode", , , false)
  capslockMode := true
}
z:: LockCurrentMode()

#HotIf tabMode
a:: MsgBox("J模式")
s:: LockCurrentMode()

#HotIf capsFMode
a:: MsgBox("CapsF 模式")

#HotIf TaskSwitchMode
e:: send("{blind}{up}")
d:: send("{blind}{down}")
s:: send("{blind}{left}")
f:: send("{blind}{right}")
x:: send("{blind}{del}")
Space:: send("{blind}{enter}")


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

#HotIf

ExecCapslockAbbr(command) {
  switch command {
    case "dd":
      Run("shell:downloads")
  }
}

ExecSemicolonAbbr(command) {
  switch command {
    case "dd":
      Run("shell:downloads")
  }
}