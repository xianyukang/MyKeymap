#SingleInstance Force
#NoTrayIcon

ListLines(false)
SetWorkingDir(A_ScriptDir)
TraySetIcon("./icons/logo.ico")
SendMode("Input")

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

  ShowGui(title := "连续复制后，在本窗口按空格键") {
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
    this.ShowGui("已把收集到的" this.textList.Length " 行挪入剪切版")
    this.textList := []
    SetTimer(() => this.ShowGui(), -5000)
  }

}

layout := CLayout()
layout.showGui()

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
      ; 临时取消监听
      OnClipboardChange(ClipboardChangeCallbakc, 0)
      res := Trim(join("`n", layout.textList*), " \n\r\n")
      if res {
        A_Clipboard := res
      }
      layout.Restart()
      ; 启动监听
      OnClipboardChange(ClipboardChangeCallbakc)
    case "Escape":
      ExitApp
  }
  return 0
}

OnClipboardChange(ClipboardChangeCallbakc)
ClipboardChangeCallbakc(type) {
  if (type != 1)
    return

  layout.AddItem(A_Clipboard)
  layout.ShowGui()
}