Class TypoTipWindow {

  __New(text := "               ", fontSize := 11, marginX := 12, marginY := 2) {
    ; 字体颜色
    FontColor := "000000"
    ; 背景颜色
    BackColor := "ffffe0"

    this.typoTip := Gui("+Owner +ToolWindow +Disabled -SysMenu -Caption +E0x1E +AlwaysOnTop +Border")
    this.typotip.BackColor := BackColor

    this.typoTip.MarginX := marginX
    this.typoTip.MarginY := marginY
    this.typoTip.SetFont("c" FontColor " s" fontSize, "Microsoft Sans Serif")

    this.textCon := this.typoTip.Add("text", "Center", text)
  }

  Show(text := "", offsetX := 9, offsetY := 7) {
    if (text) {
      this.textCon.Value := text
    }

    MouseGetPos(&xpos, &ypos)
    xpos += offsetX
    ypos += offsetY
    this.typoTip.Show("AutoSize Center NoActivate x" xpos " y" ypos)
  }

  Hide() {
    this.typoTip.Hide()
  }
}