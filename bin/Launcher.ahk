#Requires AutoHotkey v2.0
; 该脚本只能编译成Exe使用，只用做启动MyKeymap.ahk和AHk v2使用
#SingleInstance Force
#NoTrayIcon
;@Ahk2Exe-SetMainIcon ./bin/icons/logo3.ico
;@Ahk2Exe-ExeName MyKeymap
SetWorkingDir(A_ScriptDir)

; 以管理员权限运行
full_command_line := DllCall("GetCommandLine", "str")
if not (A_IsAdmin or RegExMatch(full_command_line, " /restart(?!\S)")) {
  otherArgs := ""
  if (A_Args.Length) {
    otherArgs := A_Args.Get(1)
  }

  try {
    if A_IsCompiled
      Run '*RunAs "' A_ScriptFullPath '" ' otherArgs ' /restart'
    else
      Run '*RunAs "' A_AhkPath '" /restart "' A_ScriptFullPath '"'
    ExitApp
  } catch Error as e {
    hasTip := true
    ToolTip("`n    MyKeymap is running with normal privileges.`n    MyKeymap will not work in a window with admin rights  ( e.g., Taskmgr.exe )    `n ")
  }
}

mainAhkFilePath := "./bin/MyKeymap.ahk"

if (A_Args.Length) {
  Run("MyKeymap.exe /script " A_Args.Get(1))
} else {
  ; 通过配置文件生成脚本
  RunWait("./bin/settings.exe GenerateScripts", "./bin", "Hide")
  ; 首次运行则生成快捷方式
  if !FileExist(A_WorkingDir "\shortcuts\*.*") {
    Run("MyKeymap.exe /script ./bin/MiscTools.ahk GenerateShortcuts")
  }
  ; 启动脚本
  Run("MyKeymap.exe /script " mainAhkFilePath)
}

if IsSet(hasTip) {
  Sleep 7000
}