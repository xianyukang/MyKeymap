#SingleInstance Force
; 解决「 winactivate 最小化的窗口时不会把窗口放到顶层(被其他窗口遮住)
#WinActivateForce
InstallKeybdHook ; 强制安装键盘钩子
A_MaxHotkeysPerInterval := 70
SetWorkingDir("../")

#Include lib/Fcunctions.ahk
#Include lib/Actions.ahk
#Include lib/KeymapManager.ahk
#Include lib/TypoTipWindow.ahk
#Include lib/TempFocusGui.ahk
#Include lib/Utils.ahk

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

OnExit(MyExit)
; 记录Caps缩写的Pid
capsAbbrWindowPid := ""

; ===============       内置组       ========================
GroupAdd("makrdownGroup", "ahk_exe Obsidian.exe")

; ===============    以下为配置信息    =======================
configVer := ""
; todo: 添加一个判断，如果选择了命令窗口则生成以下内容，否则不生成
capsHook := InputHook("", "{Capslock}{BackSpace}{Esc}", "dd,df,se")
capsHook.KeyOpt("{CapsLock}", "S")
capsHook.OnChar := PostCharToCaspAbbr
Run("bin\MyKeymap-CommandInput.exe", , , &capsAbbrWindowPid)

semiHook := InputHook("", "{CapsLock}{BackSpace}{Esc}{;}{Space}", "dd")
semiHook.OnChar := (ih, char) => semiHookAbbrWindow.Show(char)
semiHookAbbrWindow := TypoTipWindow()

; EnableMode(&capslockMode, "capslockMode", 350, EnterCapslockAbbr)
; ===============        热键        ========================
Caps := KeymapManager.NewKeymap("*capslock")
caps.Map("*a", Caps.ToggleLock)
Caps.Map("*c", arg => Run("bin/SoundControl.exe"))
Caps.Map("*x", arg => CloseSameClassWindows())
Caps.Map("*d", arg => Run("MyKeymap.exe bin/CustomShellMenu.ahk"))
Caps.SendKeys("*w", "!{tab}")

CapsF := KeymapManager.AddSubKeymap(Caps, "*f")
CapsF.Map("*f", NoOperation)
CapsF.Map("*n", arg => Run("notepad.exe"))
CapsF.Map("*m", bindWindow())

CapsSpace := KeymapManager.AddSubKeymap(Caps, "*space")
CapsSpace.Map("*space", NoOperation)

; Win10 和 Win11 的 Alt-Tab 任务切换视图
TaskSwitch := TaskSwitchKeymap("e", "d", "s", "f", "x", "space")
Caps.Map("*e", arg => Send("^!{tab}"), TaskSwitch)

; 可以自定义模式
m := KeymapManager.NewKeymap("!f")
m.Map("*n", arg => Run("notepad.exe"))
m := KeymapManager.NewKeymap("f1 & f2")
m.Map("*n", arg => Run("notepad.exe"))

; 鼠标模式相关
Fast := MouseKeymap(110, 70, "T0.13", "T0.01", 1, "T0.2", "T0.03", KeymapManager.ClearLock)
Slow := MouseKeymap(10, 13, "T0.13", "T0.01", 1, "T0.2", "T0.03", KeymapManager.UnLock)

Caps.Map("*i", Fast.MoveMouseUp, Slow)
Caps.Map("*k", Fast.MoveMouseDown, Slow)
Caps.Map("*j", Fast.MoveMouseLeft, Slow)
Caps.Map("*l", Fast.MoveMouseRight, Slow)

Slow.Map("*i", Slow.MoveMouseUp)
Slow.Map("*k", Slow.MoveMouseDown)
Slow.Map("*j", Slow.MoveMouseLeft)
Slow.Map("*l", Slow.MoveMouseRight)

Caps.Map("*u", Fast.ScrollWheelUp)
Caps.Map("*o", Fast.ScrollWheelDown)
Caps.Map("*h", Fast.ScrollWheelLeft)
Caps.Map("*;", Fast.ScrollWheelRight)

Slow.Map("*u", Slow.ScrollWheelUp)
Slow.Map("*o", Slow.ScrollWheelDown)
Slow.Map("*h", Slow.ScrollWheelLeft)
Slow.Map("*;", Slow.ScrollWheelRight)

Caps.Map("*n", Fast.LButton())
Caps.Map("*m", Fast.RButton())
Caps.Map("*,", Fast.LButtonDown())
Fast.Map("*space", Fast.LButtonUp())

Slow.Map("*n", Slow.LButton())
Slow.Map("*m", Slow.RButton())
Slow.Map("*,", Slow.LButtonDown())
Slow.Map("*space", Slow.LButtonUp())
slow.Map("*esc", Slow.ExitMouseKeyMap())

; 单按 3 锁定 3 模式
Three := KeymapManager.NewKeymap("*3")
Three.MapSinglePress(Three.ToggleLock)

Three.RemapKey("h", "0")
Three.RemapKey("j", "1")
Three.RemapKey("k", "2")
Three.RemapKey("l", "3")
Three.RemapKey("u", "4")
Three.RemapKey("i", "5")
Three.RemapKey("o", "6")
Three.RemapKey("b", "7")
Three.RemapKey("n", "8")
Three.RemapKey("m", "9")
Three.RemapKey("w", "volume_down")
Three.RemapKey("t", "volume_up")
Three.RemapKey("space", "f1")
Three.RemapKey("2", "f2")
Three.RemapKey("4", "f4")
Three.RemapKey("5", "f5")
Three.RemapKey("9", "f9")
Three.RemapKey("0", "f10")
Three.RemapKey("e", "f11")
Three.RemapKey("r", "f12")


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

KeymapManager.GlobalKeymap.Enable()
