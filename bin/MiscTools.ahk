#Requires AutoHotkey v2.0
#SingleInstance Force
#NoTrayIcon

SetWorkingDir A_ScriptDir "\.."

if !A_Args.Length {
  return
}

if A_Args[1] = "GenerateShortcuts" {
  try DirDelete("shortcuts", true)
  try DirCreate("shortcuts")

  ; 把开始菜单中的快捷方式都拷贝到 shortcuts 目录
  copyFiles(A_ProgramsCommon "\*.lnk", "shortcuts\", A_StartupCommon)
  copyFiles(A_Programs "\*.lnk", "shortcuts\", A_Startup)
  ; 然后再生成 UWP 相关的快捷方式
  oFolder := ComObject("Shell.Application").NameSpace("shell:AppsFolder")
  if Type(oFolder) != 'String' {
      for item in oFolder.Items {
          if FileExist("shortcuts\" item.Name ".lnk") {
              continue
          }
          try FileCreateShortcut("shell:appsfolder\" item.Path, "shortcuts\" item.Name ".lnk")
      }
  }
  ; 删除无用快捷方式
  useless := "i)(uninstall|卸载|help|iSCSI 发起程序|ODBC 数据源|ODBC Data|Windows 内存诊断|恢复驱动器|组件服务|碎片整理和优化驱动器|Office 语言首选项|手册|更新|帮助|Tools Command Prompt for|license|Website)"
  Loop Files "shortcuts\*.*" {
    if RegExMatch(A_LoopFileName, useless) {
      FileDelete(A_LoopFilePath)
    }
  }
  return
}


if A_Args[1] = "RunAtStartup" {
  linkFile := A_Startup "\MyKeymap.lnk"
  if A_Args[2] = "On" {
    FileCreateShortcut(A_WorkingDir "\MyKeymap.exe", linkFile, A_WorkingDir)
  } else if (A_Args[2] = "Off") {
    if FileExist(linkFile) {
      FileDelete(linkFile)
    }
  }
  return
}

copyFiles(pattern, dest, ignore := "") {
  Loop Files pattern, "R" {
    if ignore != "" && InStr(A_LoopFilePath, ignore) {
      continue
    }
    try FileCopy(A_LoopFilePath, dest, true)
  }
}