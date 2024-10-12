; 启动后激活一下窗口
target := A_Args[1]
Run target, , , &pid
Sleep 200
if WinExist("ahk_pid " pid) && !WinActive() {
  WinActivate
}