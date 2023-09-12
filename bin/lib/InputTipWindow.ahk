Class InputTipWindow {

  __New(text := "                       ", fontSize := 12, marginX := 2, marginY := 2) {
    ; 字体颜色
    FontColor := "000000"
    ; 背景颜色
    BackColor := "ffffe0"

    this.typoTip := Gui("+Owner +ToolWindow +Disabled -SysMenu -Caption +E0x1E +AlwaysOnTop +Border")
    this.typotip.BackColor := BackColor

    this.typoTip.MarginX := marginX
    this.typoTip.MarginY := marginY
    this.typoTip.SetFont("c" FontColor " s" fontSize, "Microsoft YaHei UI")

    this.textCon := this.typoTip.Add("text", "Center", text)
    this.text := text
  }

  Show(text := "", offsetX := 9, offsetY := 7, addition := false) {
    if text == "" {
      text := this.text
    }
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
    this.typoTip.Show("AutoSize Center NoActivate x" xpos " y" ypos)
  }

  Hide() {
    this.typoTip.Hide()
  }
}