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
    ldi A \space        ; Character to print for erasing
    int ~SYSCALL_PRINT_CHAR ; Prints space at pos 5, syscall advances cursor to 6 and handles newline check
    dec X $cursor_x     ; Move cursor back to where the space was (pos 5)
    ;dec X $cursor_x     ; Move cursor to position before the erased char (pos 4)
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
    ldm A $temp_char        ; Get char to print
    int ~SYSCALL_PRINT_CHAR ; Syscall prints char, advances cursor, and handles newline check
    jmp :read_command_loop

:process_shell_command
    int ~SYSCALL_PRINT_NL ; Newline after user presses Enter via syscall

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

    ; --- Try commands of length 3 ---
    tst K 3 ; Is length 3?
    jmpf :try_len5_commands ; If not length 3, try length 5 commands

    ; Command is length 3. Try "cls" first.
    ldi I 0
    ldx A $cmd_buffer ; A = cmd_buffer[0]
    tst A \c
    jmpf :try_ext_command ; Not 'c', try "ext"
    ldi I 1
    ldx A $cmd_buffer ; A = cmd_buffer[1]
    tst A \l
    jmpf :try_ext_command ; Not 'l', try "ext"
    ldi I 2
    ldx A $cmd_buffer ; A = cmd_buffer[2]
    tst A \s
    jmpf :try_ext_command ; Not 's', try "ext"
    ; If all checks pass, it's "cls"
    call @print_cls ; This is `int 1` via printing.asm
    jmp :shell_loop

:try_ext_command ; Still length 3
    ldi I 0
    ldx A $cmd_buffer
    tst A \e
    jmpf :unknown_shell_command ; Not 'e', and not 'cls', so unknown for length 3
    ldi I 1
    ldx A $cmd_buffer
    tst A \x
    jmpf :unknown_shell_command ; Not 'x'
    ldi I 2
    ldx A $cmd_buffer
    tst A \t
    jmpf :unknown_shell_command ; Not 't'
    ; It's "ext" command - stop self (PID 1)
    ldi A 1 ; This process is PID 1
    int ~SYSCALL_STOP_PROCESS ; Kernel syscall to stop process
    ; If the shell is successfully stopped by the kernel,
    ; it might not reach the instructions below.
    ; The kernel's _isr_stop_process would need to handle descheduling
    ; the current process and switching to another.

    ; If ext fails or kernel returns, it will loop.
    ; Ideally, the process halts or the system switches away.
    jmp :shell_loop

:try_len5_commands
    ldm K $cmd_buffer_idx ; K = length of command (re-check, though branched here)
    tst K 5 ; Is length 5? (e.g. "sta P" or "sto P")
    jmpf :unknown_shell_command ; If not 5 (and wasn't 3), then unknown.

    ; Command is length 5. Try "sta P"
    ldi I 0
    ldx A $cmd_buffer
    tst A \s
    jmpf :try_sto_command 
    ldi I 1
    ldx A $cmd_buffer
    tst A \t
    jmpf :try_sto_command
    ldi I 2
    ldx A $cmd_buffer
    tst A \a
    jmpf :try_sto_command
    ldi I 3
    ldx A $cmd_buffer
    tst A \space ; Check for space separator
    jmpf :try_sto_command
    ; If all checks pass, it's "sta P"
    ldi I 4           ; Index of PID character
    ldx A $cmd_buffer ; A = ASCII char for PID
    subi A 20         ; Convert ASCII '0'(20)...'9'(29) to number 0...9
                      ; TODO: Add validation: PID should be >0 and <MAX_PROCESSES
                      ; The kernel's _isr_start_process should also validate.
    int ~SYSCALL_START_PROCESS ; Kernel syscall to start process
    jmp :shell_loop

:try_sto_command ; Still length 5
    ldi I 0
    ldx A $cmd_buffer
    tst A \s
    jmpf :unknown_shell_command ; Not 's', so unknown for length 5
    ldi I 1
    ldx A $cmd_buffer
    tst A \t
    jmpf :unknown_shell_command
    ldi I 2
    ldx A $cmd_buffer
    tst A \o
    jmpf :unknown_shell_command
    ldi I 3
    ldx A $cmd_buffer
    tst A \space ; Check for space separator
    jmpf :unknown_shell_command
    ; If all checks pass, it's "sto P"
    ldi I 4           ; Index of PID character
    ldx A $cmd_buffer ; A = ASCII char for PID
    subi A 20         ; Convert ASCII '0'(20)...'9'(29) to number 0...9
                      ; TODO: Add validation for PID. Kernel's _isr_stop_process should validate.
    int ~SYSCALL_STOP_PROCESS ; Kernel syscall to stop process
    jmp :shell_loop

:unknown_shell_command
    call @print_unknown_shell_cmd_msg
    jmp :shell_loop



; --- Helper Routines for PROCES 1 Shell ---
@print_shell_prompt ; Local to PROCES 1
    ldi A \>                ; First char of prompt
    int ~SYSCALL_PRINT_CHAR ; Syscall prints '>', advances cursor, checks newline
    ldi A \space
    int ~SYSCALL_PRINT_CHAR ; Syscall prints ' ', advances cursor, checks newline
ret

@print_unknown_shell_cmd_msg ; Local to PROCES 1
    ; Prints "unkn" then a newline
    ldi A \u
    int ~SYSCALL_PRINT_CHAR
    ldi A \n
    int ~SYSCALL_PRINT_CHAR
    ldi A \k
    int ~SYSCALL_PRINT_CHAR
    ldi A \n
    int ~SYSCALL_PRINT_CHAR
    int ~SYSCALL_PRINT_NL ; Explicitly request a newline via syscall
ret




; User Process with Kernel PID 2
.PROCES 2 32 
    ; Load process ID (number 2)
    ; Call kernel print routine
  
    . $var1 1
    % $var1 8

    

:loop1
    ;call @add1  

    ldm A $var1
    ;int ~SYSCALL_PRINT_NUMBER

    ; Infinite loop or halt
    jmp :loop1  

    @add1
        ldm A $var1   
        addi A 1
        sto A $var1
    ret
