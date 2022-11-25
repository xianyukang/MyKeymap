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
firstItemName := filename
if InStr(filePath, "`n") {
    firstItemName := "选中了多个文件"
}
Menu, MyMenu, Add, %firstItemName%, MenuHandler
Menu, MyMenu, Disable, %firstItemName%

name := "(&F) 复制路径"
Menu, MyMenu, Add, %name%, MenuHandler
Menu, MyMenu, Icon, %name%, Shell32.dll, 135

; 自定义的
args = {file}
exe = %A_Programs%\Visual Studio Code\Visual Studio Code.lnk
add_menu_item("C", "在 Code 中打开", "icons\vscode.ico", exe, args)

args = -filename {file}
exe = C:\Program Files\Everything\Everything.exe
add_menu_item("E", "在 Everything 中搜索", "icons\everything.png", exe, args)

args = -d {file}
exe = wt.exe
add_menu_item("T", "在 Windows Termianl 中打开", "icons\terminal.png", exe, args)

args = smartArchiveZipFile
exe = C:\Program Files\7-Zip\7zg.exe
add_menu_item("Z", "用 7-Zip 压缩", "icons\7z.ico", exe, args)

args = smartExtractZipFile
exe = C:\Program Files\7-Zip\7z.exe
add_menu_item("X", "用 7-Zip 解压缩", "icons\7z.ico", exe, args)



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

        if (item.args == "smartExtractZipFile") {
            smartExtractZipFile(item.exe, filePath)
            break
        }
        if (item.args == "smartArchiveZipFile") {
            smartArchiveZipFile(item.exe, filePath)
            break
        }

        if (item.workingDir) {
            wr := item.workingDir
            wr := StrReplace(wr, "{file}", filePath)
            wr := StrReplace(wr, "{dir}", fileDir)
            run, %exe% %args%, %wr%
            break
        }

        run, %exe% %args%
        break
    }
}
return

add_menu_item(key, name, icon := "", exe := "", args := "", workingDir := "")
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
    obj.workingDir := workingDir
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


smartExtractZipFile(exe, filepath)
{
    onlyOne := zipContainsOnlyOneItem(exe, filepath)

    SplitPath, exe, OutFileName, OutDir, OutExtension, OutNameNoExt
    exe := OutDir . "\7zg.exe"

    SplitPath, filepath, OutFileName, OutDir, OutExtension, OutNameNoExt
    if onlyOne {
        run, %exe% x "%filepath%" -o"%OutDir%"
    } else {
        run, %exe% x "%filepath%" -o"%OutDir%\%OutNameNoExt%"
    }
}

zipContainsOnlyOneItem(exe,filepath)
{
    cmdLine := """" exe """ l -ba -x!*\* " """" filepath """"
    stdout := RunCMD(cmdLine)
    lines := StrSplit(stdout, "`n")
    return lines.Length() == 2
}


smartArchiveZipFile(exe, filepath)
{
    SplitPath, exe, OutFileName, OutDir, OutExtension, OutNameNoExt
    exe := OutDir . "\7zg.exe"

    ; 选中一个文件/文件夹
    if !InStr(filepath, "`n") {
        SplitPath, filepath, OutFileName, OutDir, OutExtension, OutNameNoExt
        if InStr(FileExist(filepath), "D") {
            run, %exe% a "%filepath%.7z" "%filepath%"
        } else {
            run, %exe% a "%OutDir%\%OutNameNoExt%.7z" "%filepath%"
        }
        return
    }

    ; 选中多个文件,  注意换行符是 `r`n
    files := StrSplit(filepath, "`r`n")

    ; 最后会多出一个空格,  但在命令行中无所谓
    result := ""
    for i,f in files {
        result := result . """" f """ "
    }

    firstFile := files[1]
    SplitPath, firstFile, , OutDir
    SplitPath, OutDir, OutFileName
    run, %exe% a "%OutDir%\%OutFileName%.7z" %result%
}


RunCMD(CmdLine, WorkingDir:="", Codepage:="CP0", Fn:="RunCMD_Output") {  ;         RunCMD v0.94        
Local         ; RunCMD v0.94 by SKAN on D34E/D37C @ autohotkey.com/boards/viewtopic.php?t=74647                                                             
Global A_Args ; Based on StdOutToVar.ahk by Sean @ autohotkey.com/board/topic/15455-stdouttovar

  Fn := IsFunc(Fn) ? Func(Fn) : 0
, DllCall("CreatePipe", "PtrP",hPipeR:=0, "PtrP",hPipeW:=0, "Ptr",0, "Int",0)
, DllCall("SetHandleInformation", "Ptr",hPipeW, "Int",1, "Int",1)
, DllCall("SetNamedPipeHandleState","Ptr",hPipeR, "UIntP",PIPE_NOWAIT:=1, "Ptr",0, "Ptr",0)

, P8 := (A_PtrSize=8)
, VarSetCapacity(SI, P8 ? 104 : 68, 0)                          ; STARTUPINFO structure      
, NumPut(P8 ? 104 : 68, SI)                                     ; size of STARTUPINFO
, NumPut(STARTF_USESTDHANDLES:=0x100, SI, P8 ? 60 : 44,"UInt")  ; dwFlags
, NumPut(hPipeW, SI, P8 ? 88 : 60)                              ; hStdOutput
, NumPut(hPipeW, SI, P8 ? 96 : 64)                              ; hStdError
, VarSetCapacity(PI, P8 ? 24 : 16)                              ; PROCESS_INFORMATION structure

  If not DllCall("CreateProcess", "Ptr",0, "Str",CmdLine, "Ptr",0, "Int",0, "Int",True
                ,"Int",0x08000000 | DllCall("GetPriorityClass", "Ptr",-1, "UInt"), "Int",0
                ,"Ptr",WorkingDir ? &WorkingDir : 0, "Ptr",&SI, "Ptr",&PI)  
     Return Format("{1:}", "", ErrorLevel := -1
                   ,DllCall("CloseHandle", "Ptr",hPipeW), DllCall("CloseHandle", "Ptr",hPipeR))

  DllCall("CloseHandle", "Ptr",hPipeW)
, A_Args.RunCMD := { "PID": NumGet(PI, P8? 16 : 8, "UInt") }      
, File := FileOpen(hPipeR, "h", Codepage)

, LineNum := 1,  sOutput := ""
  While (A_Args.RunCMD.PID + DllCall("Sleep", "Int",0))
    and DllCall("PeekNamedPipe", "Ptr",hPipeR, "Ptr",0, "Int",0, "Ptr",0, "Ptr",0, "Ptr",0)
        While A_Args.RunCMD.PID and (Line := File.ReadLine())
          sOutput .= Fn ? Fn.Call(Line, LineNum++) : Line

  A_Args.RunCMD.PID := 0
, hProcess := NumGet(PI, 0)
, hThread  := NumGet(PI, A_PtrSize)

, DllCall("GetExitCodeProcess", "Ptr",hProcess, "PtrP",ExitCode:=0)
, DllCall("CloseHandle", "Ptr",hProcess)
, DllCall("CloseHandle", "Ptr",hThread)
, DllCall("CloseHandle", "Ptr",hPipeR)

, ErrorLevel := ExitCode

Return sOutput  
}