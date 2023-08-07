; 托盘菜单被点击
TrayMenuHandler(ItemName, ItemPos, MyMenu) {
  switch ItemName {
    case "退出":
      MyExit()
    case "暂停":
      ToggleSuspend()
    case "重启程序":
      ReloadPropram()
    case "打开设置":
      OpenSettings()
    case "帮助文档":
      Run("https://xianyukang.com/MyKeymap.html")
    case "查看窗口标识符":
      run("MyKeymap.exe bin\WindowSpy.ahk")
      
  }
}

; 关闭程序
MyExit() {
    thisPid := DllCall("GetCurrentProcessId")
    ProcessClose(thisPid)
}

; 暂停
ToggleSuspend() {
  Suspend(!A_IsSuspended)
  if (A_IsSuspended) {
    TraySetIcon("./bin/icons/logo2.ico", ,1)
    A_TrayMenu.Check("暂停")
    Tip("  暂停 MyKeymap  ", -500)
  } else {
    TraySetIcon("./bin/icons/logo.ico", ,0)
    A_TrayMenu.UnCheck("暂停")
    Tip("  恢复 MyKeymap  ", -500)
  }
}

; 打开设置
OpenSettings() {
  if(!WinExist("\bin\settings.exe"))
    Run("./bin/settings.exe ./bin")

  try {
    WinActivate("MyKeymap Settings")
  } catch Error as e {
    Run("http://127.0.0.1:12333")
  }
}

; 重启程序
ReloadPropram() {
  Tip("Reload")
  Run("MyKeymap.exe")
}

; 自动关闭的提示窗口
Tip(message, time := -1500) {
  ToolTip(message)
  SetTimer(() => ToolTip(), time)
}
