Class InputTipWindow {

  __New(text := "                       ", fontSize := 12, marginX := 2, marginY := 2) {
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
  }

  Show(text := "", offsetX := 9, offsetY := 7, addition := false) {
    ; 注意 ahk 中 "0" == 0 并且 if ("0") 会执行 else 分支
    if (text != "") {
      if (addition) {
        this.textCon.Value := this.textCon.Value text
      } else {
        this.textCon.Value := text
      }
    }

    GetPosRelativeScreen(&xpos, &ypos, "Mouse")
    xpos += offsetX
    ypos += offsetY
    this.gui.Show("AutoSize Center NoActivate x" xpos " y" ypos)
    WinSetAlwaysOnTop(true, "ahk_id " this.gui.Hwnd)
  }

  Hide() {
    this.gui.Hide()
  }
}