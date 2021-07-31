#NoEnv
#Persistent
#NoTrayIcon
#SingleInstance Force

SendMode Input
SetBatchLines -1
settitlematchmode, 2
ListLines Off

#Include, D:\MyFiles\MyKeymap\keymap\functions.ahk
currentWindowId := A_ScriptHwnd
return

setParentWindowHwnd(id) {
    global parentWindowHwnd
    parentWindowHwnd := id
}


exec(keyword) {
    if (keyword == "sq") {
        send ^+{esc}
    }
    else if (keyword == "sz") {
        run, %A_workingdir%
    }
    else if (keyword == "dd") 
        run, shell:downloads
    else if (keyword == "dp") 
        run, shell:my pictures
    else if (keyword == "dv") 
        run, run, shell:My Video
    else if (keyword == "da") 
        run, %A_WorkingDir%
    else if (keyword == "dr") 
        run, shell:RecycleBinFolder
    else if (keyword == "sv") 
        run, sndvol.exe -f
    else if (keyword == "se") 
        winmaximize, A
    else if (keyword == "sd") {
        winminimize, A
    }
    else if (keyword == "sr") {
        winrestore, A
    }
    else if (keyword == "ss") {
        send, {LWin down}{left}{Lwin up}
    }
    else if (keyword == "sg") {
        send, {LWin down}{right}{Lwin up}
    }
    else if (keyword == "sc") {
        center_window_to_current_monitor(1200, 800)
    }
    else if (keyword == "sC") {
        center_window_to_current_monitor(1370, 930)
    }
    else if (keyword == "sa") {
        send #+{left}
    }
    else if (keyword == "sf") {
        send #+{right}
    }
    else if (keyword == "sx") {
        close_same_class_window()
    }
    else if (keyword == "st") {
        ; 这里直接调用函数会有问题,  所以用 timer 去调用,  fuck bug
        ; settimer, ToggleTopMost, -100
    }
    else if (SubStr(keyword, 1, 1) == "f") {
        text := copySelectedText()
        if (keyword == "fp") {
            style := "color:#b309bb; font-family: Iosevka;"
            mdTemplate := "<font color='#b309bb'>{{text}}</font>"
            html := addHtmlStyle(text, style)
        }
        else if (keyword == "fo") {
            style := "color:#FF00FF; font-family: Iosevka;"
            mdTemplate := "<font color='#FF00FF'>{{text}}</font>"
            html := addHtmlStyle(text, style)
        }
        else if (keyword == "fk") {
            style := "color:#7B68EE; font-family: Iosevka;"
            mdTemplate := "<font color='#7B68EE'>{{text}}</font>"
            html := addHtmlStyle(text, style)
        }
        else if (keyword == "fr") {
            style := "color:#b309bb; font-family: Iosevka;"
            mdTemplate := "<font color='#b309bb'>{{text}}</font>"
            html := addHtmlStyle(text, style)
        }
        else if (keyword == "fg") {
            style :="color:#080; font-family: Iosevka;"
            mdTemplate := "<font color='#080'>{{text}}</font>"
            html := addHtmlStyle(text, style)
        }
        else if (keyword == "fb") {
            style := "color:#2E66FF; font-family: Iosevka;"
            mdTemplate := "<font color='#2E66FF'>{{text}}</font>"
            html := addHtmlStyle(text, style)
        }
        else if (keyword == "fi") {
            style := "color:#D05; font-family: Iosevka;"
            mdTemplate := "<font color='#D05'>{{text}}</font>"
            html := addHtmlStyle(text, style)
        }
        else if (keyword == "ff") {
            style := "font-family: Iosevka;"
            html := addHtmlStyle(text, style)
        }
        else if (keyword == "fh") {
            text := htmlEscape(text)

            htmlTemplate := "<span style='color: rgb(221, 17, 68);  background:rgb(245, 245, 245); font-family: Iosevka medium;" 
                            . "border: 1px solid rgb(221, 221, 221); border-radius: 4px; '>{{text}}</span>"
            html := strReplace(htmlTemplate, "{{text}}", text)
        }

        if (WinActive(" - Typora")) {
            clipboard := strReplace(mdTemplate, "{{text}}", text)
        } else {
            ; sleep 100
            setHtml( html )
            ; sleep 100
        }

        send {LShift down}{Insert down}{Insert up}{LShift up}
    }
    else {
        return "no match"
    }
    return keyword
}

; 先把主窗口隐藏了,  ahk 脚本执行时, 才有正确的焦点
; func := Func("exec_keyword").Bind(keyword)
; SetTimer, % func, -50
exec_keyword(keyword) {
    WinGetTitle, title, A
    ToolTip, %title%
}



translate(url)
{
    to_translate := copySelectedText()
    if (!to_translate)
        return
    exePath = C:\Program Files (x86)\Google\Chrome\Application\chrome.exe
    pattern = --app="data:text/html,<html><body><script>window.moveTo(150,40);window.resizeTo(1370,850);window.location=``{1}```;</script></body></html>"
    arg := format(pattern, url)
    to_translate := strReplace(to_translate, "`r`n"," ")
    to_translate := strReplace(to_translate, "%","%25")
    to_translate := strReplace(to_translate, "/","%2F")
    to_translate := strReplace(to_translate, "’","'")

    arg := format(arg, UriEncode(to_translate))
    run, %exePath% %arg%
}



close_same_class_window()
{
    WinExist("A" )
    wingetclass, class
    WinGet, pname, ProcessName
    GroupAdd(temp_group, "ahk_class " . class . " ahk_exe " . pname)
    groupclose, %temp_group%, A
}


init_menu()
{
    settitlematchmode, 2

    Menu, menuSearch, Add, (&F)  Google, handler_for_menu_search
    Menu, menuSearch, Add, (&B)  Bing, handler_for_menu_search

    Menu, menuStyle, Add, (&R)  Red, handler_for_menu_style
    Menu, menuStyle, Add, (&B)  Blue, handler_for_menu_style
    Menu, menuStyle, Add, (&G)  Green, handler_for_menu_style
    Menu, menuStyle, Add, (&I)  Pink, handler_for_menu_style
    Menu, menuStyle, Add, (&P)  Purple, handler_for_menu_style
    Menu, menuStyle, Add, (&O)  Magenta, handler_for_menu_style
    Menu, menuStyle, Add, (&K)  SlateBlue, handler_for_menu_style
    Menu, menuStyle, Add, (&D)  Plain text, handler_for_menu_style
    Menu, menuStyle, Add, (&E)  Bold, handler_for_menu_style
    Menu, menuStyle, Add, (&H)  Hightlight, handler_for_menu_style
    Menu, menuStyle, Add, (&F)  Font, handler_for_menu_style

    ; 把子菜单添加到主菜单
    Menu, menuMain, Add, (&S)  Window, :menuWindow
    Menu, menuMain, Add, (&F)  Style,  :menuStyle
    Menu, menuMain, Add, (&D)  Search,  :menuSearch
    Menu, menuMain, Add, (&O)  OCR,  handler_for_menu_OCR
    Menu, menuMain, Add, (&X)  XXX,  :menuX



    ; Menu, menuMain, Icon, (&S)  Window, exe.ico,,21
    ;Menu, menuMain, Icon, (&2)  Item2, D:\MyFiles\shuaihua\图标\mychangeicon\some_icons\shell.ico,,21

}

handler_for_menu_OCR:
    run, E:\projects\apps\web-api\target\ocr.lnk
return


handler_for_menu_search:
    selected_item := RegExReplace(A_ThisMenuItem,"\(&(.*)\)\s*(.*)","$1")
    if (selected_item == "F") {
        url := "https://translate.google.cn/?op=translate&sl=auto&tl=zh-CN&text={1}"
        translate(url)
    }
    else if (selected_item == "B") {
        url := "https://cn.bing.com/dict/search?q={1}"
        translate(url)
    }

return


handler_for_menu_style:
    selected_item := RegExReplace(A_ThisMenuItem,"\(&(.*)\)\s*(.*)","$1")

    text := copySelectedText()

    if (!text)
        return

    if (selected_item == "E") {
        send ^b
        send ^+{>}^+{>}
        return
    }
    else if (selected_item == "D") {
        if (winactive("ahk_exe evernote.exe"))
            send ^+{space}
        else if (winactive("ahk_exe onenote.exe"))
            send ^+n
        else {
            clipboard := text
            send {LShift down}{Insert down}{Insert up}{LShift up}
        }
        return
    }


    if (selected_item == "P") {
        style := "color:#b309bb; font-family: Iosevka;"
        mdTemplate := "<font color='#b309bb'>{{text}}</font>"
        html := addHtmlStyle(text, style)
    }
    if (selected_item == "O") {
        style := "color:#FF00FF; font-family: Iosevka;"
        mdTemplate := "<font color='#FF00FF'>{{text}}</font>"
        html := addHtmlStyle(text, style)
    }
    if (selected_item == "K") {
        style := "color:#7B68EE; font-family: Iosevka;"
        mdTemplate := "<font color='#7B68EE'>{{text}}</font>"
        html := addHtmlStyle(text, style)
    }
    else if (selected_item == "R") {
        style := "color:#b309bb; font-family: Iosevka;"
        mdTemplate := "<font color='#b309bb'>{{text}}</font>"
        html := addHtmlStyle(text, style)
    }
    else if (selected_item == "G") {
        style :="color:#080; font-family: Iosevka;"
        mdTemplate := "<font color='#080'>{{text}}</font>"
        html := addHtmlStyle(text, style)
    }
    else if (selected_item == "B") {
        style := "color:#2E66FF; font-family: Iosevka;"
        mdTemplate := "<font color='#2E66FF'>{{text}}</font>"
        html := addHtmlStyle(text, style)
    }
    else if (selected_item == "I") {
        style := "color:#D05; font-family: Iosevka;"
        mdTemplate := "<font color='#D05'>{{text}}</font>"
        html := addHtmlStyle(text, style)
    }
    else if (selected_item == "F") {
        style := "font-family: Iosevka;"
        html := addHtmlStyle(text, style)
    }
    else if (selected_item == "H") {
        text := htmlEscape(text)

        htmlTemplate := "<span style='color: rgb(221, 17, 68);  background:rgb(245, 245, 245); font-family: Iosevka medium;" 
                         . "border: 1px solid rgb(221, 221, 221); border-radius: 4px; '>{{text}}</span>"
        html := strReplace(htmlTemplate, "{{text}}", text)
    }

    if (WinActive(" - Typora")) {
        clipboard := strReplace(mdTemplate, "{{text}}", text)
    } else {
        sleep 200
        setHtml( html )
        sleep 300
    }


    send {LShift down}{Insert down}{Insert up}{LShift up}
return




MsgMonitor(wParam, lParam, msg)
{
    if (msg == 0x5555) {
        ; show_menu()
    }
    ; ToolTip Message %msg% arrived:`nWPARAM: %wParam%`nLPARAM: %lParam%
}
