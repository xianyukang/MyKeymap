#NoEnv
#SingleInstance, force
#NoTrayIcon
SetWorkingDir %A_ScriptDir%
CoordMode, Mouse, Screen
SendMode Input

menuItems := []
filePath := getSelectedFilePath()
SplitPath, filePath , filename, fileDir, fileExt, filenameNoExt

; 固定的
Menu, MyMenu, Add, %filename%, MenuHandler
Menu, MyMenu, Disable, %filename%

name := "(&F) 复制路径"
Menu, MyMenu, Add, %name%, MenuHandler
Menu, MyMenu, Icon, %name%, Shell32.dll, 135

; 自定义的
{{ .Settings.CustomShellMenu }}


WinGetPos, , , Width, Height, A
offsetX := Width/2
offsetY := Height/2
Menu, MyMenu, Show, %offsetX%, %offsetY%
return

MenuHandler:
; MsgBox file: %filePath%`nitem: %A_ThisMenuItem%. `n x: %x% `n y: %y%
if (A_ThisMenuItem == "(&F) 复制路径") {
    Clipboard := filePath
    ToolTip, 复制了 %filePath%
    sleep 600
    return
}
for index, item in menuItems {
    if (A_ThisMenuItem == item.name) {
        exe := item.exe
        args := item.args
        args := StrReplace(args, """{file}""", """" filePath """")
        args := StrReplace(args, "{file}", """" filePath """")
        args := StrReplace(args, """{dir}""", """" fileDir """")
        args := StrReplace(args, "{dir}", """" fileDir """")
        args := StrReplace(args, """{filename}""", """" filename """")
        args := StrReplace(args, "{filename}", """" filename """")
        args := StrReplace(args, """{filenameNoExt}""", """" filenameNoExt """")
        args := StrReplace(args, "{filenameNoExt}", """" filenameNoExt """")
        run, %exe% %args%
        break
    }
}
return

add_menu_item(key, name, icon := "", exe := "", args := "")
{
    global menuItems

    name := "(&" key ") " name
    Menu, MyMenu, Add, %name%, MenuHandler
    if (icon && icon != "NoIcon") {
        ; 如果是 .lnk 并且它指向 exe 文件,  那么用这个 exe 作为 icon
        if (SubStr(icon, -3) == ".lnk") {
            FileGetShortcut, %exe%, lnkTarget
            if (SubStr(lnkTarget, -3) == ".exe") {
                icon := lnkTarget
            }
        }
        Menu, MyMenu, Icon, %name%, %icon%
    }

    obj := {}
    obj.exe := exe
    obj.args := args
    obj.name := name
    menuItems.Push(obj)    
}

getSelectedFilePath()
{
    tmp := Clipboardall
    Clipboard := ""
    Send, ^c
    ClipWait, 0.6
    path := Clipboard
    Clipboard := tmp
    if ErrorLevel {
        tooltip, 没有获取到路径
        sleep, 1000
        ExitApp
    }
    return path
}