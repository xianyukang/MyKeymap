#Requires AutoHotkey v2.0
#SingleInstance Force
#NoTrayIcon

SetWorkingDir A_ScriptDir "\.."

oFolder := ComObject("Shell.Application").NameSpace("shell:AppsFolder")
for item in oFolder.Items {
  if RegExMatch(item.Name, "i)(uninstall|卸载|help|iSCSI 发起程序|ODBC 数据源|ODBC Data|Windows 内存诊断|恢复驱动器|组件服务|碎片整理和优化驱动器|Office 语言首选项|手册|更新|帮助|Tools Command Prompt for|license|Website)") {
    continue
  }
  FileCreateShortcut("shell:appsfolder\" item.Path, "shortcuts\" item.Name ".lnk")
}