#Requires AutoHotkey v2.0
#NoTrayIcon
#SingleInstance Force
SetWorkingDir A_ScriptDir

AlignText()

AlignText() {
  text := GetSelectedText()
  value := URIEncode(text)
  Run("msedge.exe --app=" A_WorkingDir "\html\AlignText.html?text=" value)
}

GetSelectedText() {
  temp := A_Clipboard
  ; 清空剪贴板
  A_Clipboard := ""

  Send("^c")
  if not (ClipWait(0.4)) {
    Tip("没有选中的文本或文件", -1200)
    return
  }
  text := A_Clipboard

  A_Clipboard := temp
  return RTrim(text, "`r`n")
}

Tip(message, time := -1500) {
  ToolTip(message)
  SetTimer(() => ToolTip(), time)
}

URIEncode(uri, encoding := "UTF-8") {
  if !uri {
    return
  }
  var := Buffer(StrPut(uri, encoding), 0)
  StrPut(uri, var, encoding)
  pos := 1
  ; 按字节遍历 buffer 中的 utf-8 字符串, 注意字符串有  null-terminator
  While pos < var.Size {
    code := NumGet(var, pos - 1, "UChar")
    if (code >= 0x30 && code <= 0x39) || (code >= 0x41 && code <= 0x5A) || (code >= 0x61 && code <= 0x7A)
      res .= Chr(code)
    else
      res .= "%" . Format("{:02X}", code)
    pos++
  }
  return res
}