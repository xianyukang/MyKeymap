; 启动后激活一下窗口
target := A_Args[1]
Run target, , , &pid
exists := WinWait("ahk_pid " pid, , 1)
if exists && !WinActive() {
  WinActivate
}