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

    this.textCon := this.gui.Add("text", "Center", text)
    this.offsetX := offsetX
    this.offsetY := offsetY
  }

  Show(text := "", addition := false) {
    ; 注意 ahk 中 "0" == 0 所以 if ("0") 比较危险, 推荐和空字符串 "" 作比较
    if (text != "") {
      if (addition) {
        this.textCon.Value := this.textCon.Value text
      } else {
        this.textCon.Value := text
      }
    }

    this.ShowWindow()
  }

  ShowWindow() {
    GetPosRelativeScreen(&xpos, &ypos, "Mouse")
    xpos += this.offsetX
    ypos += this.offsetY
    this.gui.Show("AutoSize Center NoActivate x" xpos " y" ypos)
    WinSetAlwaysOnTop(true, "ahk_id " this.gui.Hwnd)
  }

  Backspace() {
    ; 空字符串也不会报错, SubStr 很强
    this.textCon.Value := SubStr(this.textCon.Value, 1, -1)
    this.ShowWindow()
  }

  Hide() {
    this.gui.Hide()
  }
}