; procs.asm
; Test file for process management.
; Each process attempts to print its ID.

; Assumes the kernel provides a routine:


; User Process with Kernel PID 1
.PROCES 1 64 ; Allocate 64 words for Process 1 - Basic Shell

    . $cmd_buffer 16    ; Buffer to store user command (16 chars)
    . $cmd_buffer_idx 1 ; Current index/length of command in buffer
    . $temp_char 1      ; Temporary storage for character read from keyboard

:shell_loop
    call @print_shell_prompt
    ldi A 0
    sto A $cmd_buffer_idx ; Reset command buffer index

:read_command_loop
    call @KBD_READ      ; Reads key into A, A=\null if no key
    tst A \null
    jmpt :read_command_loop ; Loop if no key pressed yet

    sto A $temp_char    ; Save the character read

    ; Handle \Return (Enter key)
    tst A \Return
    jmpt :process_shell_command

    ; Handle \BackSpace
    tst A \BackSpace
    jmpt :handle_shell_backspace

    ; Handle normal character
    jmp :handle_shell_normal_char

:handle_shell_backspace
    ldm K $cmd_buffer_idx
    tst K 0 ; Is buffer index > 0? (i.e. are there chars to delete?)
    jmpt :read_command_loop ; If index is 0, nothing to backspace

    ; Decrement buffer index
    dec I $cmd_buffer_idx ; I gets old idx, M[$cmd_buffer_idx] gets new (decremented) idx

    ; Erase char on screen by printing space and moving cursor back
    di
    dec X $cursor_x     ; Move cursor left
    ldi A \space
    call @print_char    ; Print space at new cursor_x, cursor_y
    dec X $cursor_x     ; Move cursor left again to position correctly for next char
    ei
    jmp :read_command_loop

:handle_shell_normal_char
    ldm K $cmd_buffer_idx ; K = current number of chars in buffer
    tst K 16 ; Is buffer full (16 chars already stored, indices 0-15)?
    jmpt :read_command_loop ; If K == 16, buffer is full, ignore char.

    ; Store char in buffer
    ldm A $temp_char        ; Get the char to store
    inc I $cmd_buffer_idx   ; I gets current_idx (K), M[$cmd_buffer_idx] becomes K+1 (new count)
    stx A $cmd_buffer       ; M[$cmd_buffer + I] = A (stores at index K)

    ; Echo char to screen
    di
    ldm A $temp_char    ; Get char to print
    call @print_char    ; Prints char in A, uses current $cursor_x, $cursor_y
    inc X $cursor_x     ; Advance cursor_x
    call @check_nl      ; Check if newline needed after char print (if cursor at edge)
    ei
    jmp :read_command_loop

:process_shell_command
    di
    call @print_nl      ; Newline after user presses Enter
    ei

    ; Null-terminate the command in buffer (if space permits)
    ldm I $cmd_buffer_idx ; I = number of chars entered (e.g., 3 for "cls")
                          ; This is also the index for the null terminator.
    tst I 16 ; Is I == 16? (i.e. buffer was filled exactly with 16 chars, no room for null)
    jmpt :parse_command_execute ; If I is 16, buffer is full, can't null-terminate here.
    
    ldi A 0 ; Null terminator
    stx A $cmd_buffer ; M[$cmd_buffer + I] = 0. (e.g. if "cls", I=3, cmd_buffer[0..2]='cls', cmd_buffer[3]=0)

:parse_command_execute
    ldm K $cmd_buffer_idx ; K = length of command
    tst K 0 ; Is length 0 (empty command)?
    jmpt :shell_loop ; If empty command, just show prompt again

    ; --- Try to match "cls" command ---
    tst K 3 ; Is length 3?
    jmpf :try_pid_command ; If not 3, cannot be "cls", try next command

    ldi I 0
    ldx A $cmd_buffer ; A = cmd_buffer[0]
    tst A \c
    jmpf :try_pid_command ; Not 'c'
    ldi I 1
    ldx A $cmd_buffer ; A = cmd_buffer[1]
    tst A \l
    jmpf :try_pid_command ; Not 'l'
    ldi I 2
    ldx A $cmd_buffer ; A = cmd_buffer[2]
    tst A \s
    jmpf :try_pid_command ; Not 's'
    ; If all checks pass, it's "cls"
    call @print_cls ; This is `int 1` via printing.asm
    jmp :shell_loop

:try_pid_command
    ldm K $cmd_buffer_idx ; K = length of command
    tst K 3 ; Is length 3?
    jmpf :unknown_shell_command ; If not 3, cannot be "pid"

    ldi I 0
    ldx A $cmd_buffer
    tst A \p
    jmpf :unknown_shell_command
    ldi I 1
    ldx A $cmd_buffer
    tst A \i
    jmpf :unknown_shell_command
    ldi I 2
    ldx A $cmd_buffer
    tst A \d
    jmpf :unknown_shell_command
    ; It's "pid" command
    di
    ldi A 1 ; This process is PID 1
    call @print_to_BCD
    call @print_nl
    ei
    jmp :shell_loop

:unknown_shell_command
    call @print_unknown_shell_cmd_msg
    jmp :shell_loop



; --- Helper Routines for PROCES 1 Shell ---
@print_shell_prompt ; Local to PROCES 1
    di
    ldi A \>
    call @print_char
    inc X $cursor_x
    ldi A \space
    call @print_char
    inc X $cursor_x
    ei
ret

@print_unknown_shell_cmd_msg ; Local to PROCES 1
    di
    ldi A \u
    call @print_char; inc X $cursor_x
    inc X $cursor_x
    ldi A \n
    call @print_char; inc X $cursor_x
    inc X $cursor_x
    ldi A \k
    call @print_char; inc X $cursor_x
    inc X $cursor_x
    ldi A \n
    call @print_char; inc X $cursor_x
    inc X $cursor_x
    call @print_nl ; Add a newline after the message
    ei
ret




; User Process with Kernel PID 2
.PROCES 2 32 
    ; Load process ID (number 2)
    ; Call kernel print routine
  
    . $var1 1
    % $var1 8

    

:loop1
    call @add1  

    
    di  
        ldm A $var1   
        ;call @print_to_BCD 
    ei

    ; Infinite loop or halt
    jmp :loop1  

    @add1
        ldm A $var1   
        addi A 1
        sto A $var1
    ret
