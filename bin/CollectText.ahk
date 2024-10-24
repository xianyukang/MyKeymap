#SingleInstance Force
#NoTrayIcon

ListLines(false)
SetWorkingDir(A_ScriptDir)
TraySetIcon("./icons/logo.ico")
SendMode("Input")


last := ""
layout := CLayout()
layout.showGui()
OnClipboardChange(ClipboardChangeCallbakc)

class CLayout {
  X := 10
  Y := 10
  W := 700
  H := 180
  textList := []

  __New() {
    this.myGui := Gui("+resize +AlwaysOnTop -SysMenu")
    this.hwnd := this.myGUI.hwnd
    this.myGUI.SetFont("s12", "Microsoft YaHei Ui")
    this.myGUI.Add("text", "y-20", "连续复制后，在本窗口按空格键复制下面的文本")
  }

  ShowGui(title := "连续复制后, 在本窗口内按空格或 C 键") {
    this.myGui.Title := title
    this.myGUI.Show("AutoSize NoActivate W" this.W)
  }

  AddItem(text) {
    this.textList.Push(text)
    space := "y+6"
    this.myGUI.Add("text", "y+6 w700 +wrap", text)
  }

  Restart() {
    this.myGui.Destroy()
    this.__New
    this.ShowGui("已把收集到的 " this.textList.Length " 行挪入剪切版")
    this.textList := []
    SetTimer(() => this.ShowGui(), -5000)
  }

}


join(sep, params*) {
  str := ""

  for index, param in params
    str .= sep . param

  return SubStr(str, StrLen(sep) + 1)
}

OnMessage(0x100, WM_KEYDOWN)
WM_KEYDOWN(wParam, lParam, msg, hwnd) {
  switch (GetKeyName(Format("vk{:x}", wparam))) {
    case "Space":
      JoinCopiedText()
    case "Escape":
      ExitApp
    case "c":
      JoinCopiedText()
      ExitApp
  }
  return 0
}

ClipboardChangeCallbakc(type) {
  global last
  if (type != 1)
    return

  text := RTrim(A_Clipboard, " `t`r`n")
  if text == last {
    return
  }
  last := text
  layout.AddItem(text)
  layout.ShowGui()
}

JoinCopiedText()
{
  ; 临时取消监听
  OnClipboardChange(ClipboardChangeCallbakc, 0)
  res := join("`n", layout.textList*)
  if res {
    A_Clipboard := res
  }
  layout.Restart()
  ; 启动监听
  OnClipboardChange(ClipboardChangeCallbakc)
}