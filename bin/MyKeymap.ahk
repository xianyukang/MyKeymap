#Requires AutoHotkey v2.0
#SingleInstance Force
#UseHook true

#Include lib/Functions.ahk
#Include lib/Actions.ahk
#Include lib/KeymapManager.ahk
#Include lib/InputTipWindow.ahk
#Include lib/Utils.ahk

; #WinActivateForce   ; 先关了遇到相关问题再打开试试
; InstallKeybdHook    ; 这个可以重装 keyboard hook, 提高自己的 hook 优先级, 以后可能会用到
; ListLines False     ; 也许能提升一点点性能 ( 别抱期待 ), 当有这个需求时再打开试试
; #Warn All, Off      ; 也许能提升一点点性能 ( 别抱期待 ), 当有这个需求时再打开试试

DllCall("SetThreadDpiAwarenessContext", "ptr", -3, "ptr") ; 多显示器不同缩放比例会导致问题: https://www.autohotkey.com/boards/viewtopic.php?f=14&t=13810
SetMouseDelay 0                                           ; SendInput 可能会降级为 SendEvent, 此时会有 10ms 的默认 delay
SetWinDelay 0                                             ; 默认会在 activate, maximize, move 等窗口操作后睡眠 100ms
A_MaxHotkeysPerInterval := 256                            ; 默认 70 可能有点低, 即使没有热键死循环也触发警告
SendMode "Event"                                          ; 执行 SendInput 的期间会短暂卸载 Hook, 这时候松开引导键会丢失 up 事件, 所以 Event 模式更适合 MyKeymap
SetKeyDelay 0                                             ; 默认 10 太慢了, https://www.reddit.com/r/AutoHotkey/comments/gd3z4o/possible_unreliable_detection_of_the_keyup_event/
ProcessSetPriority "High"
SetWorkingDir("../")
InitTrayMenu()
InitKeymap()
OnExit(MyKeymapExit)
#include ../data/custom_functions.ahk

InitKeymap()
{
  taskSwitch := TaskSwitchKeymap("e", "d", "s", "f", "c", "space")
  mouseTip := false
  slow := MouseKeymap("slow mouse", false, mouseTip, 10, 13, "T0.13", "T0.01", 1, "T0.2", "T0.03")
  fast := MouseKeymap("fast mouse", false, mouseTip, 110, 70, "T0.13", "T0.01", 1, "T0.2", "T0.03", slow)
  slow.Map("*space", slow.LButtonUp())

  capsHook := InputHook("", "{CapsLock}{Esc}", "bb,ca,cc,cmd,dd,dm,ex,ga,gj,kp,ld,lj,ly,mm,ms,mu,no,rb,rex,se,sl,sp,ss,tm,vm,we,wf,wt")
  capsHook.KeyOpt("{CapsLock}", "S")
  capsHook.KeyOpt("{Backspace}", "N")
  capsHook.OnChar := PostCharToCaspAbbr
  capsHook.OnKeyDown := PostBackspaceToCaspAbbr
  Run("bin\MyKeymap-CommandInput.exe")

  semiHook := InputHook("", "{CapsLock}{Esc}{;}", ",,,.,/,dk,dq,fz,gg,gt,i love nia,jt,sj,sk,xf,xk,zh,zk")
  semiHook.KeyOpt("{CapsLock}", "S")
  semiHook.KeyOpt("{Backspace}", "N")
  semiHook.OnChar := (ih, char) => semiHookAbbrWindow.Show(char, true)
  semiHook.OnKeyDown := (ih, vk, sc) => semiHookAbbrWindow.Backspace()
  semiHookAbbrWindow := InputTipWindow()


  ; 路径变量
  programs := "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\"

  ; 窗口组
  GroupAdd("MY_WINDOW_GROUP_1", "ahk_exe chrome.exe")
  GroupAdd("MY_WINDOW_GROUP_1", "ahk_exe msedge.exe")
  GroupAdd("MY_WINDOW_GROUP_1", "ahk_exe firefox.exe")

  ; CapsLock
  km5 := KeymapManager.NewKeymap("*CapsLock", "CapsLock", "")
  km := km5
  km.Map("*c", _ => SoundControl())
  km.Map("*z", _ => CopySelectedAsPlainText())
  km.Map("*.", _ => MakeWindowDraggable())
  km.Map("*a", _ => CenterAndResizeWindow(1370, 930))
  km.Map("*b", _ => MinimizeWindow())
  km.Map("*e", _ => Send("^!{tab}"), taskSwitch)
  km.Map("*g", _ => ToggleWindowTopMost())
  km.Map("*p", _ => GoToNextVirtualDesktop())
  km.Map("*q", _ => MaximizeWindow())
  km.Map("*r", _ => LoopRelatedWindows())
  km.Map("*s", _ => CenterAndResizeWindow(1200, 800))
  km.Map("*t", BindWindow())
  km.Map("*v", _ => MoveWindowToNextMonitor())
  km.Map("*w", _ => GoToLastWindow())
  km.Map("*x", _ => SmartCloseWindow())
  km.Map("*y", _ => GoToPreviousVirtualDesktop())
  km.Map("*,", fast.LButtonDown()), slow.Map("*,", slow.LButtonDown())
  km.Map("*/", _ => MoveMouseToCaret()), slow.Map("*/", _ => MoveMouseToCaret())
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
  km.Map("*0", _ => (Send("{home}+{end}{backspace}"), Send("{text}i love homura and hikari"), Sleep(1000), Send("{enter}yes{enter}")))
  km.Map("*d", _ => CenterAndResizeWindow(1740, 1000))
  km.Map("singlePress", _ => EnterCapslockAbbr(capsHook))

  ; CapsLock + F
  km6 := KeymapManager.AddSubKeymap(km5, "*f", "CapsLock + F", "")
  km := km6
  km.Map("*a", _ => ActivateOrRun("ahk_exe WindowsTerminal.exe", "shortcuts\终端预览.lnk"))
  km.Map("*d", _ => ActivateOrRun("ahk_exe msedge.exe", "shortcuts\Microsoft Edge.lnk"))
  km.Map("*e", _ => ActivateOrRun("ahk_class CabinetWClass ahk_exe Explorer.EXE", "D:\"))
  km.Map("*h", _ => ActivateOrRun("- Microsoft Visual Studio", "shortcuts\Visual Studio 2019.lnk"))
  km.Map("*i", _ => ActivateOrRun("ahk_exe Typora.exe", "shortcuts\Typora.lnk"))
  km.Map("*j", _ => ActivateOrRun("ahk_exe idea64.exe", "shortcuts\IntelliJ IDEA Ultimate.lnk"))
  km.Map("*k", _ => ActivateOrRun("ahk_class PotPlayer64", "shortcuts\PotPlayer 64 bit.lnk"))
  km.Map("*l", _ => ActivateOrRun("ahk_exe EXCEL.EXE", "shortcuts\Excel.lnk"))
  km.Map("*n", _ => ActivateOrRun("ahk_exe goland64.exe", "shortcuts\GoLand.lnk"))
  km.Map("*o", _ => ActivateOrRun("ahk_exe ONENOTE.EXE", "shortcuts\OneNote.lnk"))
  km.Map("*p", _ => ActivateOrRun("ahk_exe POWERPNT.EXE", "shortcuts\PowerPoint.lnk"))
  km.Map("*q", _ => ActivateOrRun("ahk_class EVERYTHING", "shortcuts\Everything.lnk"))
  km.Map("*r", _ => ActivateOrRun("ahk_exe FoxitReader.exe", "D:\install\Foxit Reader\FoxitReader.exe"))
  km.Map("*s", _ => ActivateOrRun("ahk_exe Code.exe", "shortcuts\Visual Studio Code.lnk"))
  km.Map("*w", _ => ActivateOrRun("ahk_exe chrome.exe", "shortcuts\Google Chrome.lnk"))
  km.Map("singlePress", _ => (Send("{blind}{f}")))
  km.Map("*m", _ => ProcessExistSendKeyOrRun("TIM.exe", "^!z", "shortcuts\TIM.lnk"))

  ; CapsLock + Space
  km7 := KeymapManager.AddSubKeymap(km5, "*Space", "CapsLock + Space", "")
  km := km7
  km.Map("*d", _ => ActivateOrRun("ahk_exe datagrip64.exe", "shortcuts\DataGrip.lnk"))
  km.Map("singlePress", _ => (Send("{blind}{space}")))
  km.Map("*w", _ => ProcessExistSendKeyOrRun("WeChat.exe", "^!w", "shortcuts\微信.lnk"))

  ; J 模式
  km8 := KeymapManager.NewKeymap("*j", "J 模式", "")
  km := km8
  km.Map("singlePress", _ => (Send("{blind}{j}")))
  km.RemapKey(",", "delete")
  km.RemapKey(".", "insert")
  km.Map("*2", _ => (Send("^+{tab}")))
  km.Map("*3", _ => (Send("^{tab}")))
  km.RemapKey("a", "home")
  km.Map("*b", _ => (Send("^{backspace}")))
  km.RemapKey("c", "backspace")
  km.RemapKey("d", "down")
  km.RemapKey("e", "up")
  km.RemapKey("f", "right")
  km.RemapKey("g", "end")
  km.Map("*k", _ => HoldDownModifierKey("LShift"))
  km.RemapKey("q", "appskey")
  km.RemapKey("r", "tab")
  km.RemapKey("s", "left")
  km.Map("*t", _ => (Send("{home}+{end}{backspace}")))
  km.Map("*v", _ => (Send("{blind}^{right}")))
  km.Map("*w", _ => (Send("{blind}+{tab}")))
  km.RemapKey("x", "esc")
  km.Map("*z", _ => (Send("{blind}^{left}")))
  km.Map("*space", _ => (Send("{blind}{enter}")))

  ; 3 模式
  km10 := KeymapManager.NewKeymap("*3", "3 模式", "")
  km := km10
  km.RemapKey("0", "F10")
  km.RemapKey("2", "F2")
  km.RemapKey("4", "F4")
  km.RemapKey("5", "F5")
  km.RemapKey("9", "F9")
  km.RemapKey("b", "7")
  km.RemapKey("e", "F11")
  km.RemapKey("h", "0")
  km.RemapKey("i", "5")
  km.RemapKey("j", "1")
  km.RemapKey("k", "2")
  km.RemapKey("l", "3")
  km.RemapKey("m", "9")
  km.RemapKey("n", "8")
  km.RemapKey("o", "6")
  km.RemapKey("r", "F12")
  km.RemapKey("t", "Volume_Up")
  km.RemapKey("u", "4")
  km.RemapKey("w", "Volume_Down")
  km.RemapKey("space", "F1")
  km.Map("singlePress", _ => (Send("{blind}{3}")))
  km.Map("*/", km.ToggleLock)

  ; 分号模式( ; )
  km13 := KeymapManager.NewKeymap("*;", "分号模式( `; )", "")
  km := km13
  km.Map("*a", _ => (Send("{blind}*")))
  km.Map("*b", _ => (Send("{blind}%")))
  km.Map("*c", _ => (Send("{blind}.")))
  km.Map("*d", _ => (Send("{blind}=")))
  km.Map("*e", _ => (Send("{blind}{^}")))
  km.Map("*f", _ => (Send("{blind}>")))
  km.Map("*g", _ => (Send("{blind}{!}")))
  km.Map("*h", _ => (Send("{blind}{+}")))
  km.Map("*i", _ => (Send("{blind}:")))
  km.Map("*j", _ => (Send("{blind};")))
  km.Map("*k", _ => (Send("{blind}``")))
  km.Map("*m", _ => (Send("{blind}-")))
  km.Map("*n", _ => (Send("{blind}/")))
  km.Map("*r", _ => (Send("{blind}&")))
  km.Map("*s", _ => (Send("{blind}<")))
  km.Map("*t", _ => (Send("{blind}~")))
  km.Map("*u", _ => (Send("{blind}$")))
  km.Map("*v", _ => (Send("{blind}|")))
  km.Map("*w", _ => (Send("{blind}{#}")))
  km.Map("*x", _ => (Send("{blind}_")))
  km.Map("*y", _ => (Send("{blind}@")))
  km.Map("*z", _ => (Send("{blind}\")))
  km.Map("singlePress", _ => EnterSemicolonAbbr(semiHook, semiHookAbbrWindow))

  ; 句号模式( . )
  km14 := KeymapManager.NewKeymap("*.", "句号模式( . )", "")
  km := km14
  km.Map("singlePress", _ => (Send("{blind}{.}")))
  km.Map("*,", _ => HoldDownModifierKey("LShift"))
  km.Map("*2", _ => (Send("^+{tab}")))
  km.Map("*3", _ => (Send("^{tab}")))
  km.RemapKey("a", "home")
  km.Map("*b", _ => (Send("^{backspace}")))
  km.RemapKey("c", "backspace")
  km.RemapKey("d", "down")
  km.RemapKey("e", "up")
  km.RemapKey("f", "right")
  km.RemapKey("g", "end")
  km.RemapKey("q", "appskey")
  km.RemapKey("r", "tab")
  km.RemapKey("s", "left")
  km.Map("*v", _ => (Send("{blind}^{right}")))
  km.Map("*w", _ => (Send("{blind}+{tab}")))
  km.RemapKey("x", "esc")
  km.Map("*z", _ => (Send("{blind}^{left}")))
  km.Map("*space", _ => (Send("{blind}{enter}")))

  ; 鼠标右键
  km16 := KeymapManager.NewKeymap("RButton", "鼠标右键", "")
  km := km16
  km.Map("*XButton1", _ => GoToNextVirtualDesktop())
  km.Map("*XButton2", _ => GoToPreviousVirtualDesktop())
  km.Map("singlePress", fast.RButton()), slow.Map("singlePress", slow.RButton())
  km.Map("*LButton", _ => (Send("^!{tab}")))
  km.Map("*MButton", _ => (Send("#{tab}")))
  km.RemapKey("c", "backspace")
  km.RemapKey("d", "delete")
  km.RemapKey("x", "esc")
  km.Map("*space", _ => (Send("{blind}{enter}")))
  km.Map("*WheelUp", _ => (Send("^+{tab}")))
  km.Map("*WheelDown", _ => (Send("^{tab}")))

  ; Custom Hotkeys
  km1 := KeymapManager.NewKeymap("customHotkeys", "Custom Hotkeys", "")
  km := km1
  km.RemapInHotIf("RAlt", "LControl")
  km.Map("!'", _ => MyKeymapReload(), , , , "S")
  km.Map("!+'", _ => MyKeymapToggleSuspend(), , , , "S")
  km.Map("!CapsLock", _ => ToggleCapslock())


  KeymapManager.GlobalKeymap.Enable()
}

ExecCapslockAbbr(command) {
  ; 路径变量
  programs := "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\"

  switch command {
    case "bb":
      ActivateOrRun("Bing 词典", "msedge.exe", "--app=https://www.bing.com/dict/search?q={selected}", "", false, false, false)
    case "ca":
      ActivateOrRun("计算器", "calc.exe")
    case "cc":
      ActivateOrRun("", "shortcuts\Visual Studio Code.lnk", "-n `"{selected}`"", "", false, false, false)
    case "cmd":
      ActivateOrRun("ahk_exe cmd.exe", "cmd.exe", "/k cd /d %userprofile%", "", false, false, false)
    case "dd":
      ActivateOrRun("", "shell:downloads")
    case "dm":
      ActivateOrRun("", A_WorkingDir)
    case "ex":
      MyKeymapExit()
    case "ga":
      ActivateOrRun("Game ahk_exe explorer.exe", A_Desktop "\Game")
    case "gj":
      SystemShutdown()
    case "kp":
      CloseWindowProcesses()
    case "ld":
      BrightnessControl()
    case "lj":
      ActivateOrRun("", "shell:RecycleBinFolder")
    case "ly":
      ActivateOrRun("", "ms-settings:bluetooth")
    case "mm":
      ActivateOrRun("MyKeymap2 - Visual Studio Code", "shortcuts\Visual Studio Code.lnk", "D:\MyFiles\MyKeymap2", "", false, false, false)
    case "ms":
      ActivateOrRun("my_site - Visual Studio Code", "shortcuts\Visual Studio Code.lnk", "D:\project\my_site", "", false, false, false)
    case "mu":
      MuteActiveApp()
    case "no":
      ActivateOrRun("记事本", "notepad.exe")
    case "rb":
      SystemReboot()
    case "rex":
      SystemRestartExplorer()
    case "se":
      MyKeymapOpenSettings()
    case "sl":
      SystemSleep()
    case "sp":
      ActivateOrRun("Spotify", "https://open.spotify.com/")
    case "ss":
      ActivateOrRun("ahk_exe Spotify.exe", "shortcuts\Spotify.lnk")
    case "tm":
      Send("^+{esc}")
    case "vm":
      ActivateOrRun("", "ms-settings:apps-volume")
    case "we":
      ActivateOrRun("网易云音乐", "shortcuts\网易云音乐.lnk")
    case "wf":
      ActivateOrRun("", "ms-availablenetworks:")
    case "wt":
      ActivateOrRun("", "wt.exe", "-d `"{selected}`"", "", false, false, false)
  }
}

ExecSemicolonAbbr(command) {
  ; 路径变量
  programs := "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\"

  switch command {
    case ",":
      Send("，")
    case ".":
      Send("。")
    case "/":
      Send("、")
    case "dk":
      Send("{text}{}"), Send("{left}")
    case "dq":
      ActivateOrRun("", "bin\AutoHotkey64.exe", "bin\AlignComment.ahk", "", false, false, true)
    case "fz":
      ActivateOrRun("", "bin\AutoHotkey64.exe", "bin\CollectText.ahk", "", false, false, false)
    case "gg":
      Send("{text}git add -A; git commit -a -m `"`"; git push origin (git branch --show-current);"), Send("{left 47}")
    case "gt":
      Send("🐶")
    case "i love nia":
      Send("{text}我爱尼娅! "), Send("{text}( 还 有 大 家 )")
    case "jt":
      Send("{text}➤ ")
    case "sj":
      Send(Format("{}年{}月{}日 {}:{}", A_YYYY, A_MM, A_DD, A_Hour, A_Min))
    case "sk":
      Send("「  」"), Send("{left 2}")
    case "xf":
      Send("();{left 2}")
    case "xk":
      Send("(){left}")
    case "zh":
      Send("{text} site:zhihu.com inurl:question")
    case "zk":
      Send("[]{left}")
  }
}

InitTrayMenu() {
  m := GetMenuName()
  A_TrayMenu.Delete()
  A_TrayMenu.Add(m.Pause, TrayMenuHandler)
  A_TrayMenu.Add(m.Exit, TrayMenuHandler)
  A_TrayMenu.Add(m.Reload, TrayMenuHandler)
  A_TrayMenu.Add(m.Settings, TrayMenuHandler)
  A_TrayMenu.Add(m.Spy, TrayMenuHandler)
  A_TrayMenu.Default := m.Pause
  A_TrayMenu.ClickCount := 1

  A_IconTip := "MyKeymap 2.0-beta29 created by 咸鱼阿康"
  TraySetIcon("./bin/icons/logo.ico", , true)
}


#HotIf
RAlt::LControl

#HotIf