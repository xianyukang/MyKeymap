;This is not my original script. I took from sevral places (please see links below) and combined it in one script.  
;http://www.autohotkey.com/board/topic/58483-how-to-access-the-hotstring-recognizer/
;https://superuser.com/questions/936306/tooltip-should-appear-after-typing-two-letters-of-the-hotstrings/
#UseHook
#SingleInstance, force
Loop, Read, %A_ScriptFullPath%
If RegExMatch(A_LoopReadLine,"^\s*:.*?:(.*)", line) ; gathers the hotstrings
hs.= line1 "`n"

7::
Loop 10 {
    Input, out, L1    ;,{BS} ;I removed this ,{BS}
    If out in ,,,`t,`n, ,.,?,! 
    { ; hotstring delimiters
        ToolTip % str:=""
        break
    }
    else
        {
        postCharToTipWidnow(out)
         str.=out
         if (StrLen(str) > 1) ; means 2 or more, so if you want the tooltip to appear after 4 characters it will be > 3
            ToolTip % RegExReplace(hs,"m`a)^(?!\Q" (str) "\E).*\n" ), 1600, 1600 ; I added this in the last so that the tooltip should display in the corner of the PC.
	  SetTimer, RemoveToolTip, 10000 ;This will be displayed for 2 seconds.
        }
     }
BlockInput, off
return

8::
BlockInput, off
return


 ; NewStr := RegExReplace(Haystack, NeedleRegEx [, Replacement = "", OutputVarCount = "", Limit = -1, StartingPosition = 1])

	  RemoveToolTip:
	  SetTimer, RemoveToolTip, Off
	  ToolTip
      return
	  
 ~BackSpace:: StringTrimRight, str, str, 1 
 
;your hotstrings 
::ravig::ravikumarjain@gmail.com
::tyou::Thank You
::ili::I Love India 



postCharToTipWidnow(char) {
    Prev_DetectHiddenWindows := A_DetectHiddenWindows
    DetectHiddenWindows 1
    id := WinExist("ahk_class xianyukang_window")
    PostMessage, 0x0102, Ord(char), 0, , ahk_id %id%
    DetectHiddenWindows %Prev_DetectHiddenWindows%
}
