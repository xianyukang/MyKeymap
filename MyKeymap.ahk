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
    Run("*RunAs " A_ScriptFullPath " " otherArgs " /restart" )
    ExitApp
  } catch Error as e {
    hasTip := true
    ToolTip("MyKeymap 当前以普通权限运行 `n在一些高权限窗口中会完全失效 ( 比如任务管理器 )")
  }
}

mainAhkFilePath := "./bin/MyKeymap.ahk"

if (A_Args.Length) {
  Run("MyKeymap.exe /script " A_Args.Get(1))
} else {
  ; 通过配置文件生成脚本
  RunWait("./bin/settings.exe GenerateAHK ./data/config.json ./bin/templates/mykeymap.tmpl ./bin/MyKeymap.ahk", ,"Hide")
  ; 启动脚本
  Run("MyKeymap.exe /script " mainAhkFilePath)
}

if IsSet(hasTip) {
  Sleep 6000
}