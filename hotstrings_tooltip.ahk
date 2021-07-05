;This is not my original script. I took from sevral places (please see links below) and combined it in one script.  
;http://www.autohotkey.com/board/topic/58483-how-to-access-the-hotstring-recognizer/
;https://superuser.com/questions/936306/tooltip-should-appear-after-typing-two-letters-of-the-hotstrings/
#UseHook
#SingleInstance, force
#Include, keymap\functions.ahk




7::enterHotString()

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



