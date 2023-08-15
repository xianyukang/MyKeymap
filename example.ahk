#Requires AutoHotkey v2.0
#SingleInstance Force
#UseHook true
#Include bin/lib/KeymapManager.ahk

; #WinActivateForce   ; 先关了遇到相关问题再打开试试
; InstallKeybdHook    ; 这个可以重装 keyboard hook, 提高自己的 hook 优先级, 以后可能会用到
; ListLines False     ; 也许能提升一点点性能 ( 别抱期待 ), 当有这个需求时再打开试试
; #Warn All, Off      ; 也许能提升一点点性能 ( 别抱期待 ), 当有这个需求时再打开试试

DllCall("SetThreadDpiAwarenessContext", "ptr", -3, "ptr") ; 多显示器不同缩放比例会导致问题: https://www.autohotkey.com/boards/viewtopic.php?f=14&t=13810
ProcessSetPriority "High"
InitKeymap()

RAlt::LCtrl
!r::
{
    SoundBeep
    Reload
}

InitKeymap()
{
    ; Capslock 和子模式
    Caps := KeymapManager.NewKeymap("*capslock")
    Caps.Map("*c", arg => Run("bin/SoundControl.exe"))
    Caps.Map("*x", arg => WinClose("A"))
    Caps.Map("*d", arg => Run("MyKeymap.exe bin/CustomShellMenu.ahk"))
    Caps.MapSinglePress(Caps.ToggleLock)
    Caps.SendKeys("*w", "!{tab}")
    Caps.SendKeys("*y", "^#{left}")
    Caps.SendKeys("*p", "^#{right}")

    CapsF := KeymapManager.AddSubKeymap(Caps, "*f")
    CapsF.Map("*f", NoOperation)
    CapsF.Map("*n", arg => Run("notepad.exe"))

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
    fast := MouseKeymap(110, 70, "T0.13", "T0.01", 1, "T0.2", "T0.03", KeymapManager.ClearLock)
    slow := MouseKeymap(10, 13, "T0.13", "T0.01", 1, "T0.2", "T0.03", KeymapManager.UnLock)
    MouseKeymap.SetMoveMouseKeys(Caps, fast, slow, "*i", "*k", "*j", "*l")
    MouseKeymap.SetScrollWheelKeys(Caps, fast, slow, "*u", "*o", "*h", "*;")
    MouseKeymap.SetMouseButtonKeys(Caps, fast, slow, "*n", "*m", "*,", "*space")

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


    J := KeymapManager.NewKeymap("*j")
    J.MapSinglePress(arg => Send("{blind}j"))
    J.RemapKey("e", "up")
    J.RemapKey("d", "down")
    J.RemapKey("s", "left")
    J.RemapKey("f", "right")
    J.RemapKey("a", "home")
    J.RemapKey("g", "end")
    J.RemapKey("c", "backspace")
    J.RemapKey("x", "esc")
    J.RemapKey("r", "tab")
    J.RemapKey("q", "appskey")
    J.RemapKey(",", "delete")
    J.RemapKey(".", "insert")

    J.SendKeys("*space", "{blind}{enter}")
    J.SendKeys("*w", "{blind}+{tab}")
    J.SendKeys("*b", "{blind}^{backspace}")
    J.SendKeys("*z", "{blind}^{left}")
    J.SendKeys("*v", "{blind}^{right}")
    J.SendKeys("*2", "{blind}^+{tab}")
    J.SendKeys("*3", "{blind}^{tab}")

    JK := KeymapManager.AddSubKeymap(J, "*k")
    JK.Map("*k", NoOperation)
    JK.SendKeys("*e", "{blind}+{up}")
    JK.SendKeys("*d", "{blind}+{down}")
    JK.SendKeys("*s", "{blind}+{left}")
    JK.SendKeys("*f", "{blind}+{right}")
    JK.SendKeys("*a", "{blind}+{home}")
    JK.SendKeys("*g", "{blind}+{end}")
    JK.SendKeys("*x", "{blind}+{esc}")
    JK.SendKeys("*z", "{blind}^+{left}")
    JK.SendKeys("*v", "{blind}^+{right}")
    JK.SendKeys("*c", "{blind}{backspace}")

    Semicolon := KeymapManager.NewKeymap("*;")
    Semicolon.MapSinglePress(arg => Send(";"))
    Semicolon.SendKeys("*u", "{blind}$")
    Semicolon.SendKeys("*r", "{blind}&")
    Semicolon.SendKeys("*a", "{blind}*")
    Semicolon.SendKeys("*m", "{blind}-")
    Semicolon.SendKeys("*c", "{blind}.")
    Semicolon.SendKeys("*n", "{blind}/")
    Semicolon.SendKeys("*i", "{blind}:")
    Semicolon.SendKeys("*s", "{blind}<")
    Semicolon.SendKeys("*d", "{blind}=")
    Semicolon.SendKeys("*f", "{blind}>")
    Semicolon.SendKeys("*y", "{blind}@")
    Semicolon.SendKeys("*z", "{blind}\")
    Semicolon.SendKeys("*x", "{blind}_")
    Semicolon.SendKeys("*b", "{blind}%")
    Semicolon.SendKeys("*j", "{blind};")
    Semicolon.SendKeys("*k", "{blind}``")
    Semicolon.SendKeys("*g", "{blind}{!}")
    Semicolon.SendKeys("*w", "{blind}{#}")
    Semicolon.SendKeys("*h", "{blind}{+}")
    Semicolon.SendKeys("*e", "{blind}{^}")
    Semicolon.SendKeys("*v", "{blind}|")
    Semicolon.SendKeys("*t", "{blind}~")

    KeymapManager.GlobalKeymap.Enable()
}