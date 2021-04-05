
__showvar(msg, var) {
        msgbox % msg . " =`r`n`r`n" . var
    }

__showlasterror() {
    __showvar("last error", A_LastError)
}


SendPipeMessage(strMessage) {
	global A__PIPECLIENT
	A__PIPECLIENT.write(strMessage)
	sleep, 100
	A__PIPECLIENT_RESULT := A__PIPECLIENT.read()
	sleep, 100
	return A__PIPECLIENT_RESULT
}

; get version - also required to make sure pipe client is not loaded twice
pipeclient_getversion() {
	return "v1.0"
}

pipeclient_log(strMessage) {

}

class WinApiErrorCodes {
    static ERROR_PIPE_NOT_CONNECTED := 233
    static ERROR_INVALID_HANDLE := 6
    static ERROR_PIPE_BUSY := 231
    static ERROR_NOACCESS := 998
}
    
class pipeclient {
    pipe_name := ""
    pipe_handle := ""

    
    __New(name) {
        this.pipe_name := this.__get_full_pipe_name(name)
        this.pipe_handle := this.__get_pipe_handle(this.pipe_name)
    }


    is_connected() {
        b := this.get_bytes_to_read() ; call the peeknamedpipe, in order to check last error
		return A_LastError == 0  ; this will be something like '233' if there was an error
    }


    get_bytes_to_read() {
        buffer_size := 2
        buffer := ""
        VarSetCapacity(buffer, buffer_size)
        
        bytes_read := 0
        total_bytes_available := 0
        bytes_left_in_message := 0

        ret := DllCall("PeekNamedPipe"
            ,"Ptr", this.pipe_handle
            ,"Ptr", &buffer
            ,"Uint*", buffer_size
            ,"Uint*", bytes_read
            ,"Uint*", total_bytes_available
            ,"Uint*", bytes_left_in_message)


        if (ret == 0)  ; no data to read
        {
            ; MsgBox, problem peeking
            ; showlasterror()
            return -1
        }
        else
        {
            return total_bytes_available
        }
    }


    wait_for_data_to_read(max_wait_time := 0) {
      waited := 0
      step := 100

      buffer_size := this.get_bytes_to_read()

      while (buffer_size <= 0) {
        Sleep, %step%
        waited := waited + step

        if (max_wait_time > 0 && waited >= max_wait_time)
          return False

        buffer_size := this.get_bytes_to_read()
      }

      return True
    }

    read() {
        wait_result := this.wait_for_data_to_read() ;wait infintely for data
        ;showvar("read - wait result", wait_result)

        buffer_size := this.get_bytes_to_read()
        ;showvar("read - buffer_size", buffer_size)

        buffer := ""
        VarSetCapacity(buffer, buffer_size)

        ret := DllCall("ReadFile"
            ,"Ptr", this.pipe_handle
            ,"Str", buffer
            ,"UInt", buffer_size
            ,"UInt*", bytes_read
            ,"UInt", 0)

            ; Trim results data down to only the bytes read
            ; use memcpy to do this
        if (ret == 1)  ; if read was successful
        {
            result := ""
            VarSetCapacity(result, bytes_read)
            DllCall("msvcrt\memcpy", "str", result, "ptr", &buffer, "ptr", bytes_read)
			;showvar("read - results", result)
            return result
        }
        else { ;read failed due to error
            return 
        }
    }

    write(msg) {
        ;add in BOM
        ;msg := (A_IsUnicode ? chr(0xfeff) : chr(239) chr(187) chr(191)) . msg

        buffer := msg
        buffer_length := (A_IsUnicode ? StrLen(buffer) * 2 : StrLen(buffer))
        num_of_bytes_written := 0

        DllCall("WriteFile"
            ,"Ptr", this.pipe_handle
            ,"Str", buffer
            ,"UInt", buffer_length
            ,"UInt*", bytes_written
            ,"UInt", 0)

        return bytes_written
    }

    close() {
        DllCall("CloseHandle", "Ptr", this.pipe_handle)
    }


    __get_full_pipe_name(name) {
        if (RegExMatch(name, "^\\\\.\\pipe\\"))
            return name
        else
            return "\\.\pipe\" . name
    }

    __get_pipe_handle(name) {
        GENERIC_WRITE := 0x40000000  
        GENERIC_READ  := 0x80000000  
        access := GENERIC_READ | GENERIC_WRITE

        return DllCall("CreateFile"
            ,"Str" , name
            ,"UInt", access
            ,"UInt", 3 ; share read / write
            ,"UInt", 0
            ,"UInt", 3 ; open existing file
            ,"UInt", 0
            ,"UInt", 0)			
    }
}



