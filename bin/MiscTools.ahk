#Requires AutoHotkey v2.0
#SingleInstance Force
#NoTrayIcon

SetWorkingDir A_ScriptDir "\.."

if !A_Args.Length {
  return
}

if A_Args[1] = "GenerateShortcuts" {
  oFolder := ComObject("Shell.Application").NameSpace("shell:AppsFolder")
  for item in oFolder.Items {
    if RegExMatch(item.Name, "i)(uninstall|卸载|help|iSCSI 发起程序|ODBC 数据源|ODBC Data|Windows 内存诊断|恢复驱动器|组件服务|碎片整理和优化驱动器|Office 语言首选项|手册|更新|帮助|Tools Command Prompt for|license|Website)") {
      continue
    }
    FileCreateShortcut("shell:appsfolder\" item.Path, "shortcuts\" item.Name ".lnk")
  }
  return
}


if A_Args[1] = "RunAtStartup" {
  linkFile := A_Startup "\MyKeymap.lnk"
  if A_Args[2] = "On" {
    FileCreateShortcut(A_WorkingDir "\MyKeymap.exe", linkFile, A_WorkingDir)
  } else if (A_Args[2] = "Off") {
    FileDelete(linkFile)
  }
  return
}