class TempFocusGui extends Gui {
  __New() {
    super.__New("+Owner")
  }

  ShowGui() {
    super.Show("NoActivate")
    WinSetTransparent(0, super.Hwnd)
    WinWait "ahk_class AutoHotkeyGUI"
    WinActivate

    IfLoseFocusThenExit() {
      if ( not WinActive("ahk_id" this.hwnd)) {
        this.Hide
        SetTimer(, 0)
      }
    }

    SetTimer(IfLoseFocusThenExit, 100)
  }
}