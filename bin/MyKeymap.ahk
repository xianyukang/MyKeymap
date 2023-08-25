#Requires AutoHotkey v2.0
#SingleInstance Force
#UseHook true

#Include lib/Fcunctions.ahk
#Include lib/Actions.ahk
#Include lib/KeymapManager.ahk
#Include lib/TypoTipWindow.ahk
#Include lib/TempFocusGui.ahk
#Include lib/Utils.ahk

; #WinActivateForce   ; 先关了遇到相关问题再打开试试
; InstallKeybdHook    ; 这个可以重装 keyboard hook, 提高自己的 hook 优先级, 以后可能会用到
; ListLines False     ; 也许能提升一点点性能 ( 别抱期待 ), 当有这个需求时再打开试试
; #Warn All, Off      ; 也许能提升一点点性能 ( 别抱期待 ), 当有这个需求时再打开试试

DllCall("SetThreadDpiAwarenessContext", "ptr", -3, "ptr") ; 多显示器不同缩放比例会导致问题: https://www.autohotkey.com/boards/viewtopic.php?f=14&t=13810
SetMouseDelay 0                                           ; SendInput 可能会降级为 SendEvent, 此时会有 10ms 的默认 delay
SetWinDelay 0                                             ; 默认会在 activate, maximize, move 等窗口操作后睡眠 100ms
ProcessSetPriority "High"
SetWorkingDir("../")
InitTrayMenu()
InitKeymap()
OnExit(MyExit)
#include ../data/custom_functions.ahk

RAlt::LCtrl
!e:: ExitApp
!r::
{
  SoundBeep
  Reload
}

InitKeymap()
{
  taskSwitch := TaskSwitchKeymap("e", "d", "s", "f", "x", "space")
  fast := MouseKeymap(110, 70, "T0.13", "T0.01", 1, "T0.2", "T0.03", KeymapManager.ClearLock)
  slow := MouseKeymap(10, 13, "T0.13", "T0.01", 1, "T0.2", "T0.03", KeymapManager.UnLock)
  slow.Map("*space", slow.LButtonUp())

  capsHook := InputHook("", "{Capslock}{BackSpace}{Esc}", "dd,dm")
  capsHook.KeyOpt("{CapsLock}", "S")
  capsHook.OnChar := PostCharToCaspAbbr
  Run("bin\MyKeymap-CommandInput.exe")

  semiHook := InputHook("", "{CapsLock}{BackSpace}{Esc}{;}{Space}", "dd,dm")
  semiHook.OnChar := (ih, char) => semiHookAbbrWindow.Show(char)
  semiHookAbbrWindow := TypoTipWindow()

  ; 如果在系统设置中交换了左右键,  那么需要发送左键才能打开右键菜单
  theRealRButton := SysGet(23) ? "{LButton}" : "{RButton}"


  ; Capslock
  km5 := KeymapManager.NewKeymap("*capslock")
  km := km5
  km.Map("*c", _ => ActivateOrRun("记事本", "notepad.exe"))
  km.Map("*a", _ => CenterAndResizeWindow(1370, 930))
  km.Map("*b", _ => WindowMinimize())
  km.Map("*e", _ => Send("^!{tab}"), taskSwitch)
  km.Map("*p", _ => Send("^#{right}"))
  km.Map("*q", _ => WindowMaximize())
  km.Map("*r", _ => SwitchWindows())
  km.Map("*s", _ => CenterAndResizeWindow(1200, 800))
  km.Map("*v", _ => Send("#+{right}"))
  km.Map("*w", _ => Send("!{tab}"))
  km.Map("*x", _ => SmartCloseWindow())
  km.Map("*y", _ => Send("^#{left}"))
  km.Map("*,", fast.LButtonDown()), slow.Map("*,", slow.LButtonDown())
  km.Map("*;", fast.ScrollWheelRight), slow.Map("*;", slow.ScrollWheelRight)
  km.Map("*h", fast.ScrollWheelLeft), slow.Map("*h", slow.ScrollWheelLeft)
  km.Map("*i", fast.MoveMouseUp, slow), slow.Map("*i", slow.MoveMouseUp)
  km.Map("*j", fast.MoveMouseLeft, slow), slow.Map("*j", slow.MoveMouseLeft)
  km.Map("*k", fast.MoveMouseDown, slow), slow.Map("*k", slow.MoveMouseDown)
  km.Map("*l", fast.MoveMouseRight, slow), slow.Map("*l", slow.MoveMouseRight)
  km.Map("*m", fast.RButton()), slow.Map("*m", slow.RButton())
  km.Map("*n", fast.LButton()), slow.Map("*n", slow.LButton())
  km.Map("*o", fast.ScrollWheelDown), slow.Map("*o", slow.ScrollWheelDown)
  km.Map("*u", fast.ScrollWheelUp), slow.Map("*u", slow.ScrollWheelUp)
  km.Map("singlePress", _ => EnterCapslockAbbr(capsHook))

  ; Capslock + F
  km6 := KeymapManager.AddSubKeymap(km5, "*f")
  km := km6
  km.Map("*a", _ => ActivateOrRun("ahk_exe WindowsTerminal.exe", "wt.exe"))
  km.Map("*d", _ => ActivateOrRun("ahk_exe msedge.exe", "msedge.exe"))
  km.Map("*e", _ => ActivateOrRun("ahk_class CabinetWClass ahk_exe Explorer.EXE", "D:\"))
  km.Map("*h", _ => ActivateOrRun("- Microsoft Visual Studio", "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Visual Studio 2019.lnk"))
  km.Map("*i", _ => ActivateOrRun("ahk_exe Typora.exe", "C:\Program Files\Typora\Typora.exe"))
  km.Map("*j", _ => ActivateOrRun("ahk_exe idea64.exe", A_Programs "\JetBrains Toolbox\IntelliJ IDEA Ultimate.lnk"))
  km.Map("*k", _ => ActivateOrRun("ahk_class PotPlayer64", A_ProgramsCommon "\Daum\PotPlayer 64 bit\PotPlayer 64 bit.lnk"))
  km.Map("*l", _ => ActivateOrRun("ahk_exe EXCEL.EXE", A_ProgramsCommon "\Excel.lnk"))
  km.Map("*n", _ => ActivateOrRun("ahk_exe goland64.exe", A_Programs "\JetBrains Toolbox\GoLand.lnk"))
  km.Map("*o", _ => ActivateOrRun("ahk_exe ONENOTE.EXE", "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\OneNote.lnk"))
  km.Map("*p", _ => ActivateOrRun("ahk_exe POWERPNT.EXE", "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\PowerPoint.lnk"))
  km.Map("*q", _ => ActivateOrRun("ahk_class EVERYTHING", "C:\Program Files\Everything\Everything.exe"))
  km.Map("*r", _ => ActivateOrRun("ahk_exe FoxitReader.exe", "D:\install\Foxit Reader\FoxitReader.exe"))
  km.Map("*s", _ => ActivateOrRun("ahk_exe Code.exe", A_Programs "\Visual Studio Code\Visual Studio Code.lnk"))
  km.Map("*w", _ => ActivateOrRun("ahk_exe chrome.exe", "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Google Chrome.lnk"))
  km.Map("*m", _ => ProcessExistSendKeyOrRun("TIM.exe", "^!z", "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\腾讯软件\TIM\TIM.lnk"))

  ; Capslock + Space
  km7 := KeymapManager.AddSubKeymap(km5, "*space")
  km := km7
  km.Map("*n", _ => ActivateOrRun("ahk_exe datagrip64.exe", A_Programs "\JetBrains Toolbox\DataGrip.lnk"))
  km.Map("*w", _ => ProcessExistSendKeyOrRun("WeChat.exe", "^!w", "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\微信\微信.lnk"))

  ; J 模式
  km8 := KeymapManager.NewKeymap("*j")
  km := km8
  km.RemapKey(",", "delete")
  km.RemapKey(".", "insert")
  km.RemapKey("a", "home")
  km.RemapKey("c", "backspace")
  km.RemapKey("d", "down")
  km.RemapKey("e", "up")
  km.RemapKey("f", "right")
  km.RemapKey("g", "end")
  km.RemapKey("q", "appskey")
  km.RemapKey("r", "tab")
  km.RemapKey("s", "left")
  km.RemapKey("x", "esc")
  km.SendKeys("*2", "{blind}^+{tab}")
  km.SendKeys("*3", "{blind}^{tab}")
  km.SendKeys("*b", "{blind}^{backspace}")
  km.SendKeys("*v", "{blind}^{right}")
  km.SendKeys("*w", "{blind}+{tab}")
  km.SendKeys("*z", "{blind}^{left}")
  km.SendKeys("*space", "{blind}{enter}")
  km.SendKeys("singlePress", "{blind}{j}")

  ; J + K 模式
  km9 := KeymapManager.AddSubKeymap(km8, "*k")
  km := km9
  km.SendKeys("*a", "{blind}+{home}")
  km.SendKeys("*c", "{blind}{backspace}")
  km.SendKeys("*d", "{blind}+{down}")
  km.SendKeys("*e", "{blind}+{up}")
  km.SendKeys("*f", "{blind}+{right}")
  km.SendKeys("*g", "{blind}+{end}")
  km.SendKeys("*s", "{blind}+{left}")
  km.SendKeys("*v", "{blind}^+{right}")
  km.SendKeys("*x", "{blind}+{esc}")
  km.SendKeys("*z", "{blind}^+{left}")

  ; 3 模式
  km10 := KeymapManager.NewKeymap("*3")
  km := km10
  km.RemapKey("0", "f10")
  km.RemapKey("2", "f2")
  km.RemapKey("4", "f4")
  km.RemapKey("5", "f5")
  km.RemapKey("9", "f9")
  km.RemapKey("b", "7")
  km.RemapKey("e", "f11")
  km.RemapKey("h", "0")
  km.RemapKey("i", "5")
  km.RemapKey("j", "1")
  km.RemapKey("k", "2")
  km.RemapKey("l", "3")
  km.RemapKey("m", "9")
  km.RemapKey("n", "8")
  km.RemapKey("o", "6")
  km.RemapKey("r", "f12")
  km.RemapKey("t", "volume_up")
  km.RemapKey("u", "4")
  km.RemapKey("w", "volume_down")
  km.RemapKey("space", "f1")
  km.MapSinglePress(km.ToggleLock)

  ; 分号模式
  km12 := KeymapManager.NewKeymap("*;")
  km := km12
  km.SendKeys("*a", "{blind}*")
  km.SendKeys("*b", "{blind}%")
  km.SendKeys("*c", "{blind}.")
  km.SendKeys("*d", "{blind}=")
  km.SendKeys("*e", "{blind}{^}")
  km.SendKeys("*f", "{blind}>")
  km.SendKeys("*g", "{blind}{!}")
  km.SendKeys("*h", "{blind}{+}")
  km.SendKeys("*i", "{blind}:")
  km.SendKeys("*j", "{blind};")
  km.SendKeys("*k", "{blind}``")
  km.SendKeys("*m", "{blind}-")
  km.SendKeys("*n", "{blind}/")
  km.SendKeys("*r", "{blind}&")
  km.SendKeys("*s", "{blind}<")
  km.SendKeys("*t", "{blind}~")
  km.SendKeys("*u", "{blind}$")
  km.SendKeys("*v", "{blind}|")
  km.SendKeys("*w", "{blind}{#}")
  km.SendKeys("*x", "{blind}_")
  km.SendKeys("*y", "{blind}@")
  km.SendKeys("*z", "{blind}\")
  km.Map("singlePress", _ => EnterSemicolonAbbr(semiHook, semiHookAbbrWindow))

  ; 鼠标右键
  km15 := KeymapManager.NewKeymap("*rbutton")
  km := km15
  km.RemapKey("c", "backspace")
  km.RemapKey("x", "esc")
  km.SendKeys("*space", "{blind}{enter}")
  km.SendKeys("*lbutton", "^!{tab}")
  km.SendKeys("*wheelup", "^+{tab}")
  km.SendKeys("*wheeldown", "^{tab}")
  km.SendKeys("singlePress", "{blind}" theRealRButton)


  KeymapManager.GlobalKeymap.Enable()
}

ExecCapslockAbbr(command) {
  switch command {
    case "dd":
      ActivateOrRun("", "shell:downloads")
    case "dm":
      ActivateOrRun("", A_WorkingDir)
  }
}

ExecSemicolonAbbr(command) {
  switch command {
    case "dd":
      ActivateOrRun("", "shell:downloads")
    case "dm":
      ActivateOrRun("", A_WorkingDir)
  }
}

InitTrayMenu() {
  A_TrayMenu.Delete()
  A_TrayMenu.Add("暂停", TrayMenuHandler)
  A_TrayMenu.Add("退出", TrayMenuHandler)
  A_TrayMenu.Add("重启程序", TrayMenuHandler)
  A_TrayMenu.Add("打开设置", TrayMenuHandler)
  A_TrayMenu.Add("帮助文档", TrayMenuHandler)
  A_TrayMenu.Add("查看窗口标识符", TrayMenuHandler)
  A_TrayMenu.Default := "暂停"
  A_TrayMenu.ClickCount := 1

  A_IconTip := "MyKeymap 2.0.0 created by 咸鱼阿康"
  TraySetIcon("./bin/icons/logo.ico")
}