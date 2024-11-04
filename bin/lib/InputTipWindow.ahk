Class InputTipWindow {

  __New(text := "                       ", fontSize := 12, marginX := 2, marginY := 2, offsetX := 9, offsetY := 7) {
    ; 字体颜色
    FontColor := "000000"
    ; 背景颜色
    BackColor := "ffffe0"

    this.gui := Gui("+Owner +ToolWindow +Disabled -SysMenu -Caption +E0x1E +AlwaysOnTop +Border")
    this.gui.BackColor := BackColor

    this.gui.MarginX := marginX
    this.gui.MarginY := marginY
    this.gui.SetFont("c" FontColor " s" fontSize, "Microsoft YaHei UI")

    this.data := text
    this.textCon := this.gui.Add("text", "Center", this.data)
    this.offsetX := offsetX
    this.offsetY := offsetY
    FrameShadow(this.gui.Hwnd)
  }

  Show(text := "", addition := false) {
    ; 注意 ahk 中 "0" == 0 所以 if ("0") 比较危险, 推荐和空字符串 "" 作比较
    if (text != "") {
      if (addition) {
        this.data := this.data text
      } else {
        this.data := text
      }
    }

    this.ShowWindow()
  }

  ShowWindow() {
    this.textCon.Value := this.data
    GetPosRelativeScreen(&xpos, &ypos, "Mouse")
    xpos += this.offsetX
    ypos += this.offsetY
    this.gui.Show("AutoSize Center NoActivate x" xpos " y" ypos)
    WinSetAlwaysOnTop(true, "ahk_id " this.gui.Hwnd)
  }

  Backspace() {
    ; 空字符串也不会报错, SubStr 很强
    this.data := SubStr(this.textCon.Value, 1, -1)
    this.ShowWindow()
  }

  Hide() {
    this.gui.Hide()
  }
}

; https://www.autohotkey.com/boards/viewtopic.php?t=29117
FrameShadow(handle) {
  DllCall("dwmapi\DwmIsCompositionEnabled", "Int*", &enabled := false) ; Get if DWM Manager is Enabled
  if !enabled {
    return
  }
  margin := Buffer(16)
  NumPut("UInt", 1
    , "UInt", 1
    , "UInt", 1
    , "UInt", 1
    , margin)
  DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", handle, "UInt", 2, "Int*", 2, "UInt", 4)
  DllCall("dwmapi\DwmExtendFrameIntoClientArea", "Ptr", handle, "Ptr", margin)
}