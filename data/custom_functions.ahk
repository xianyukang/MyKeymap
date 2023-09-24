; 自定义的函数写在这个文件里,  然后能在 MyKeymap 中调用
; 是否启用按键记录，用来 Debug
; KeyHistory

; 使用如下写法，来加载当前目录下的其他AutoHotKey2脚本
; #Include ../data/test.ahk

sendSomeChinese() {
  Send("{text}你好中文!")
}