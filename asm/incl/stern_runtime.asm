# This version is updated for STERN-1 multiprocessing:
# - Uses the native CPU stack for STACKS data operations (native push/pop).
# - Uses kernel syscalls for SIO and basic printing.

# --- STACKS Runtime Data Stack ---
# The STACKS runtime now uses the native CPU stack of the current process.
# The global variables $sr_stack_mem, $sr_stack_ptr, and $sr_stack_idx,
# and custom routines @push_A, @pop_A, @push_B, @pop_B are no longer used.
# Native CPU instructions 'push R' and 'pop R' should be used by STACKS compiled code
# or by these runtime routines.         

; --- Shared Heap Constants ---
equ ~$SHARED_HEAP_START_ADDRESS 8192
equ ~$SHARED_HEAP_SIZE 3072
equ ~$SHARED_HEAP_END_ADDRESS 11263 ; $SHARED_HEAP_START_ADDRESS + $SHARED_HEAP_SIZE - 1


# --- Temporary variables for string operations (if any remain needed) ---

# Used by CHAR_AT to temporarily store the index value for loading into I
# Used by STRLEN to store calculated length
# These are kept for now, assuming CHARAT and STRLEN might be implemented later
# based on stack strings or might be removed if not needed.
#. $_str_op_idx_val 1    
#. $_str_op_len_val 1    

# --- Temporary variable for HASH ---
. $_hash_accumulator 1

# --- Temporary variable for ARRAY operations ---
. $_array_base_pntr_temp 1
# Used to hold the base address of an array for indexed access by array routines

# --- Timer Management ---
. $TIMER_EPOCHS 8
# Stores the epoch for up to 8 timers (index 0 to 7)
equ ~MAX_TIMER_IDX 7
# Max valid timer index

. $_timer_instance_temp 1
# Temporary storage for timer instance during print
. $_timer_init_idx 1

# Temp var for loop index




#################################
@stern_runtime_init
    # when the lib must be initalized

    # Initialize timer epochs.
    call @stacks_timer_init
    
ret

#################################
@get_mypid
    pop L
    ldm A $CURRENT_PROCESS_ID
    push A
    push L
ret

;@push_A
;    push A
;ret

;@push_B
;    push B
;ret


;@pop_A
;    pop A
;ret

;@pop_B
;    pop B
;ret

#################################
@dup 
    pop L
    pop A
    push A
    push A
    push L
ret

@swap
    pop L
    pop A
    pop B
    push A
    push B
    push L
ret

@drop
    pop L
    pop A ; Value popped into A is discarded
    push L
ret

@over
    # ( x1 x2 -- x1 x2 x1 )
    # Duplicates the second item on the stack to the top.
    pop L
    pop A  ; x2
    pop B  ; x1
    push B ; x1
    push A ; x2
    push B ; x1
    push L
ret

#################################
@plus
    pop L
    pop B
    pop A
    add A B
    push A
    push L
ret

@minus
    pop L
    pop B
    pop A
    sub A B
    push A
    push L
ret

@multiply
    pop L
    pop B
    pop A
    mul A B
    push A
    push L
ret

@divide
    pop L
    pop B
    pop A
    div A B
    push A
    push L
ret

@mod
    pop L
    pop B
    pop A
    dmod A B
    push B ; dmod A B stores remainder in B
    push L
ret

@stacks_gcd
    # Pops two numbers from the STACKS data stack,
    # calculates their Greatest Common Divisor (GCD) using the Euclidean algorithm by subtraction,
    # and pushes the result back onto the STACKS data stack.
    # Assumes non-negative inputs for simplicity.
    # GCD(x, 0) = |x|, GCD(0, y) = |y|, GCD(0,0) = 0 (conventionally).
    pop L
    pop B ; B gets the second operand (num2)
    pop A ; A gets the first operand (num1)

    # Handle cases where one or both operands are zero.
    tst B 0                 ; Is B zero?
    jmpt :_gcd_A_is_result  ; If B is 0, GCD is A.
    tst A 0                 ; Is A zero?
    jmpt :_gcd_B_is_result  ; If A is 0, GCD is B.

:_gcd_loop
    tste A B                ; Is A equal to B?
    jmpt :_gcd_A_is_result  ; If A == B, then GCD is A (or B).

    tstg A B                ; Is A > B?
    jmpt :_gcd_A_greater_B  ; If A > B, jump to subtract B from A.
                            ; Else (A < B, since A != B), so B = B - A.
    sub B A
    jmp :_gcd_loop
:_gcd_A_greater_B
    sub A B                 ; A > B, so A = A - B
    jmp :_gcd_loop

:_gcd_B_is_result
    ld A B                  ; Result was B, move to A for pushing.
:_gcd_A_is_result
    push A                  ; Push the result (which is in A).
    push L
ret
    

# --- SIO Channel Control ---
# These STACKS runtime routines now use kernel syscalls for SIO management.

@sio_channel_on
    # Pops channel number from the STACKS stack.
    # Calls SYSCALL_REQUEST_SIO_CHANNEL.
    pop L
    pop A  ; A = channel_id
    int ~SYSCALL_REQUEST_SIO_CHANNEL ; Kernel handles request, returns status in A
    ; TODO: After a return of an SYSCALL A does not holds the exitstatus (namymore)
    ; push A ; Push status onto STACKS stack (assuming syscall returns status in A)
    push L
ret

@sio_channel_off
    # Pops channel number from the STACKS stack.
    # Calls SYSCALL_RELEASE_SIO_CHANNEL.
    pop L
    pop A  ; A = channel_id
    int ~SYSCALL_RELEASE_SIO_CHANNEL ; Kernel handles release, returns status in A
    ; TODO: After a return of an SYSCALL A does not holds the exitstatus (namymore)
    ; push A ; Push status onto STACKS stack (assuming syscall returns status in A)
    push L
ret

# --- Timer Operations ---

@stacks_sleep
    pop L
    pop B ; B = sleep_duration
    ldm A $CURRENT_TIME
    add B A
    :sleep_loop
        ; Check if the target time has been reached or passed
        ldm A $CURRENT_TIME
        tstg A B            ; Sets status bit if A (current_time) > B (target_time)
        jmpt :_sleep_done   ; If current_time > target_time, sleep is finished

        ; Not yet time to wake up, so yield to other processes
        int ~SYSCALL_YIELD

        jmp :sleep_loop ; Continue checking
    :_sleep_done
    push L
ret

@stacks_timer_init
    # Initialize all timer epochs to 0.
    sto Z $_timer_init_idx
    # M[$_timer_init_idx] = 0

    ldi K 0
    # K = value to store (0)

:_timer_init_loop
    inc I $_timer_init_idx
    # I_reg = M[$_timer_init_idx] (value *before* increment).
    # M[$_timer_init_idx] is then incremented.
    # So, I_reg holds the correct index for the current iteration (0, 1, 2,...).
    stx K $TIMER_EPOCHS
    # M[$TIMER_EPOCHS + I_reg] = 0.

    # Load the (already incremented by 'inc I') index for the loop test.
    ldm L $_timer_init_idx
    # L_reg = new value of M[$_timer_init_idx] (1, 2, 3,...).
    tst L 8
    # Compare L_reg (new index) with 8. Loop if L_reg < 8.
    # If L_reg is 1..7, tst L 8 is false. jmpf.
    # If L_reg is 8, tst L 8 is true. Loop terminates.
    jmpf :_timer_init_loop
ret

@_validate_and_get_timer_address
    # Pops timer instance from stack into A.
    # MODIFIED: Expects timer instance in register A. Does NOT pop from stack.
    # Validates if 0 <= A <= ~MAX_TIMER_IDX.
    # If valid, Register I is set to the timer instance value (for indexed access),
    # and Register A contains the timer instance.
    # If invalid, calls @fatal_error and does not return.
    # Clobbers: K
    # A (input) now has the timer instance.

    ldi K ~MAX_TIMER_IDX
    tstg A K
    # If A > K (e.g. A=8, K=7), status is TRUE (invalid)
    jmpt :_timer_instance_invalid_path

    # Valid path: A <= ~MAX_TIMER_IDX.
    # Assuming A is non-negative as it's a timer index.
    ld I A
    # Set I_reg to the timer instance for indexed access to $TIMER_EPOCHS.
    # A_reg still holds the instance.
ret

:_timer_instance_invalid_path
    # Instance is invalid. A_reg holds the invalid instance.
    call @fatal_error
    # @fatal_error halts execution, so this routine will not return.
ret

@stacks_timer_set
    # Expects: timer_instance on top of stack.
    # Pops timer_instance.
    # If valid (0-~MAX_TIMER_IDX), stores $CURRENT_TIME into $TIMER_EPOCHS[instance].
    # If invalid, @fatal_error is called.
    pop L
    pop A ; Pop timer_instance into A
    call @_validate_and_get_timer_address
    # If @_validate_and_get_timer_address returns, A is valid and I is set.
    # No need to check status flag here.

    # Instance is valid, I_reg is set to instance, A_reg holds instance.
    ldm K $CURRENT_TIME
    # K_reg = current time.
    stx K $TIMER_EPOCHS
    # M[$TIMER_EPOCHS + I_reg] = K_reg.
:_timer_set_end
    # This label is no longer strictly needed if there's only one path to ret,
    # but kept for clarity or future conditional logic if any.
    push L
ret

@stacks_timer_get
    # Expects: timer_instance on top of stack.
    # Pops timer_instance.
    # If valid, calculates elapsed time ($CURRENT_TIME - epoch) and pushes it.
    # If invalid, calls @fatal_error.
    pop L
    pop A ; Pop timer_instance into A
    call @_validate_and_get_timer_address
    # If @_validate_and_get_timer_address returns, A is valid and I is set.

    # Instance is valid, I_reg is set to instance, A_reg holds instance.
    ldx K $TIMER_EPOCHS
    # K_reg = stored epoch M[$TIMER_EPOCHS + I_reg].
    ldm A $CURRENT_TIME
    # A_reg = current time.
    sub A K ; A_reg = current_time - epoch.
    push A  ; Push elapsed time
    push L
ret

@stacks_timer_print
    # Expects: timer_instance on top of stack.
    # Pops timer_instance.
    # If valid, prints "Timer [N]: [elapsed_time]\n".
    # Assumes @print_char does not advance cursor; @print_to_BCD does.
    # If invalid, @fatal_error is called.
    pop L
    pop A ; Pop timer_instance into A
    call @_validate_and_get_timer_address


    # Instance is valid. I_reg is set to instance, A_reg holds instance.
    # Save instance A_reg for printing later.
    sto A $_timer_instance_temp

    # Calculate elapsed time
    ldx K $TIMER_EPOCHS
    # K_reg = stored epoch M[$TIMER_EPOCHS + I_reg].
    ldm B $CURRENT_TIME
    # B_reg = current time.
    sub B K
    addi B 5
    divi B 10 
    # B_reg = current_time - epoch (elapsed time).

    # Print "timer "
    ldi A \t
    int ~SYSCALL_PRINT_CHAR
    ldi A \i
    int ~SYSCALL_PRINT_CHAR
    ldi A \m
    int ~SYSCALL_PRINT_CHAR
    ldi A \e
    int ~SYSCALL_PRINT_CHAR
    ldi A \r
    int ~SYSCALL_PRINT_CHAR
    ldi A \space
    int ~SYSCALL_PRINT_CHAR

    # Print timer instance number (from $_timer_instance_temp)
    ldm A $_timer_instance_temp
    int ~SYSCALL_PRINT_NUMBER ; Syscall handles BCD conversion and printing

    # Print ": "
    ldi A \:
    int ~SYSCALL_PRINT_CHAR
    ldi A \space
    int ~SYSCALL_PRINT_CHAR

    # Print elapsed time (which is in B_reg)
    ld A B
    # Move elapsed time to A_reg for @print_to_BCD.
    int ~SYSCALL_PRINT_NUMBER

    # Print newline
    int ~SYSCALL_PRINT_NL
    jmp :_timer_print_end 
    # Successfully printed, go to the end.

:_timer_print_end
    push L
ret

#################################
@print
    pop L
    pop A                           ; Number to print
    int ~SYSCALL_PRINT_NUMBER
    int ~SYSCALL_PRINT_NL
    push L
ret

#equ ~channel_id 0
#@plot 
#    ; Plot always use channel_id 0 
#    ; Expects: data on stack (top).
#    pop L
#    pop B ; B = data
#    ldi A ~channel_id
#    int ~SYSCALL_WRITE_SIO_CHANNEL  ; Kernel handles write, returns status in A
#    ; push A                          ; Push status onto STACKS stack
#    push L
#ret

#################################
#@draw
#    ; Expects: y, then x on stack (top to bottom: y, x)
#    ; Sends x, then y to SIO channel 1 for the XY Plotter.
#    pop L   ; Save return address
#    pop B   ; B = y
#    pop A   ; A = x
#nop
#    int ~SYSCALL_DRAW_XY_POINT
#
#    push L  ; Restore return address
#ret


#################################
@eq
    pop L
    pop B
    pop A
    tste A B
    jmpf :eq_is_false
        ; stet TRUE = 0 in stacks
        ldi A 0
        push A
    jmp :eq_end
    :eq_is_false
        ldi A 1
        push A
    :eq_end
    push L
ret

@ne
    pop L
    pop B
    pop A
    tste A B
    jmpf :ne_true
        ; set FALSE
        ldi A 1
        push A ; was call @push_A
    jmp :ne_end
    :ne_true
        ldi A 0
        push A ; was call @push_A
:ne_end
    push L
ret


@gt 
    pop L
    pop B
    pop A
    tstg A B
    jmpf :gt_is_false
        ldi A 0
        push A
    jmp :gt_end
    :gt_is_false
        ldi A 1
        push A
    :gt_end
    push L
ret

@lt
    pop L
    pop A       ; order of pop matters for LT: ( x y -- x<y ) -> pop y, pop x
    pop B
    tstg A B
    jmpf :lt_is_false
        ldi A 0
        push A
    jmp :lt_end
    :lt_is_false
        ldi A 1
        push A
    :lt_end
    push L
ret


#################################




#################################
# Temporary variables for @input parsing
. $_input_read_offset 1
# This variable will hold the current offset for reading from $stacks_buffer.
. $_parsed_number 1
# This variable accumulates the integer value as it's parsed.
. $_number_sign 1
# This variable stores the sign of the number (1 for positive, -1 for negative).
. $_digit_found_flag 1
# This flag is set to 1 if at least one valid digit has been processed, 0 otherwise.

@_is_digit_stacks_input
# Helper routine to check if the character in register A is a digit ('0'-'9').
# Assumes '0' is ASCII character code 20 and '9' is ASCII character code 29
# for the STACKS input context.
# Output: The CPU status flag is set if A is a digit, cleared otherwise.
# Clobbers: M
    ldi M \:
    # ASCII \: (19) \0 (20) 
    tstg A M
    jmpf :_is_digit_stacks_input_false
    ldi M \9
    # ASCII '9'
    tstg A M
    # Is A > '9'?
    jmpt :_is_digit_stacks_input_false
    # If neither jump was taken, A is a digit between '0' and '9' inclusive.
    # make sure to return the right status
    tste A A
    # Set the status flag to True, because A equals A
ret
:_is_digit_stacks_input_false
    # Ensure the status flag is cleared if it's not a digit.
    # This can be done by comparing two known unequal values.
    tstg A A
    # tstg A A clears status because A is not greater then A.
ret



@stacks_input
pop L
# call @prompt_stacks
:_input_start_over
# This label is a loop point to re-prompt the user if the input is completely invalid.
    
    call @cursor_on

    # Get the user's input. This populates $stacks_buffer.
    # After this call, M[$stacks_buffer_indx] holds the count of characters
    # entered, including the terminating \Return character.
    call @stacks_read_input
    int ~SYSCALL_PRINT_NL

    # Initialize parsing variables for the new input line.
    sto Z $_input_read_offset
    # Set current read offset to 0 (assuming Z register holds 0).

    sto Z $_parsed_number
    # Reset accumulated number to 0.

    ldi A 1
    sto A $_number_sign
    # Default sign is positive (1).

    sto Z $_digit_found_flag
    # Reset flag indicating no digits have been found yet.

    # --- Initial check of the first character ---
    ldm I $_input_read_offset
    # Load I with the current read offset (which is 0 for the first character).
    ldx A $stacks_buffer_pntr
    # Load the first character from $stacks_buffer into A.
    # A = M[M[$stacks_buffer_pntr] + I]

    tst A \Return
    jmpt :_input_start_over
    # If the first character is \Return (empty input), re-prompt.

    # Check for a leading negative sign.
    ldi M \-
    tste A M
    jmpf :_input_check_plus_sign
        # It's a negative sign.
        ldi X -1
        sto X $_number_sign
        # Set sign to negative.

        inc I $_input_read_offset
        # Advance read offset past the '-'.

        jmp :_input_parse_loop_entry
        # Proceed to the main parsing loop.

:_input_check_plus_sign
    # Check for a leading positive sign.
    ldi M \+
    tste A M
    jmpf :_input_parse_loop_entry
    # Not a '-' or '+', so start parsing with the current character.

        # It's a positive sign.
        inc I $_input_read_offset
        # Advance read offset past the '+'.
        # The sign is already positive, and $_digit_found_flag is 0.

        jmp :_input_parse_loop_entry
        # Proceed to the main parsing loop.

    # --- Main parsing loop to process digits ---
:_input_parse_loop_entry
    # Check if we've read all characters indicated by $stacks_buffer_indx.
    ldm K $stacks_buffer_indx
    # K = total characters in buffer (count from @stacks_read_input).

    ldm I $_input_read_offset
    # I = current read offset.

    tste I K
    # Have we read all characters (is offset equal to count)?
    jmpt :_input_finalize
    # Yes, all characters processed. Finalize the number.
    # This also handles cases where input was only a sign.

    # Load the current character based on $_input_read_offset.
    # Register I already holds M[$_input_read_offset] from the previous ldm.
    ldx A $stacks_buffer_pntr
    # A = M[M[$stacks_buffer_pntr] + I]

    tst A \Return
    # If the current character is \Return, it's the end of the user's actual input.
    jmpt :_input_finalize

    call @_is_digit_stacks_input
    # Check if the character in A is a digit '0'-'9'.
    jmpf :_input_non_digit_char_found
    # If not a digit, jump to handle it.

    # The character in A is a digit.
    ldi X 1
    sto X $_digit_found_flag
    # Mark that we have found and processed at least one valid digit.

    subi A 20
    # Convert ASCII digit to its numeric value (e.g., '0' (char 20) -> number 0).
    # Adjust the value 20 if your system's ASCII '0' is different (e.g., 48 for standard ASCII).
    ldm K $_parsed_number
    # K = current accumulated number.
    muli K 10
    # K = K * 10 (shift existing number left by one decimal place).
    add K A
    # Add the numeric value of the new digit.
    sto K $_parsed_number
    # Store the updated accumulated number.

    inc I $_input_read_offset
    # Advance the read offset to prepare for the next character.
    jmp :_input_parse_loop_entry
    # Loop back to process the next character.

:_input_non_digit_char_found
    # This point is reached if a non-digit character (and not \Return) is encountered.
    # If we have already found some digits (e.g., "123x"), then "123" is our number.
    # If no digits were found yet (e.g., "-x", "+x", "abc"), it's an invalid input.
    ldm K $_digit_found_flag
    tst K 1
    # Was the $_digit_found_flag set to 1 (meaning we processed valid digits)?
    jmpt :_input_finalize
    # Yes, a valid number part was found and ended by this non-digit. Finalize.
    
    # call @prompt_stacks_err
    jmp :_input_start_over
    # No, the sequence is invalid (e.g., "-abc", "abc"). Restart the input process.

:_input_finalize
    # Before finalizing, ensure at least one digit was actually processed.
    # This handles cases where the input was only a sign like "-" or "+"
    # followed immediately by \Return or a non-digit.
    ldm K $_digit_found_flag
    tst K 1
    # Was the $_digit_found_flag set to 1?
    jmpt :_found_valid_digits
    
    # No valid digits were found. Restart the input process.
    # call @prompt_stacks_err
    jmp :_input_start_over

    :_found_valid_digits
    # Apply the determined sign to the parsed number.
    ldm A $_parsed_number
    ldm K $_number_sign
    mul A K         ; A = parsed_number * sign.
    push A          ; Push the final integer result onto the STACKS data stack.
push L
ret


#################################
@stacks_raw_input_string
# Implements the RAWIN functionality for STACKS. (Modified for on-stack strings)
# 1. Prompts the user for input.
# 2. Reads a line of raw characters using @stacks_read_input (into $stacks_buffer).
# 3. Pushes the characters from $stacks_buffer onto the data stack in correct order:
#    char1, char2, ..., charN, null_terminator (0) (top to bottom on stack).
    
    pop L ; Save return address

    #  call @prompt_stacks
:_rawin_start_over
    # Loop point for re-prompting if input is empty.
    call @cursor_on
    # print \_ as cursor, will be overwritten by the value
    call @stacks_read_input

    # $stacks_buffer is now filled with user input.
    # M[$stacks_buffer_indx] contains the length, including the trailing \Return.
    
    int ~SYSCALL_PRINT_NL   ; Print a newline after the user presses Enter.


    # --- Calculate the length of the actual string content ---
    # (excluding the \Return character from $stacks_buffer_indx count)
    ldm K $stacks_buffer_indx
    # K = total length of input including the trailing \Return.
    # K must be at least 1 at this point because @stacks_read_input adds \Return.
    subi K 1
    # K now holds the length of the actual string content (0 if only \Return was entered).

    # Check if the content length K is 0 (meaning only \Return was entered).
    # If K is 0, status is set. jmpf (jump if false/clear) will not jump.
    # If K is not 0, status is clear. jmpf will jump to _rawin_len_ok.
    tst K 0
    jmpf :_rawin_len_ok
        # Content length is 0, input was empty. Re-prompt.
        # call @prompt_stacks_err 
        jmp :_rawin_start_over

:_rawin_len_ok
    # K holds the content length.

    # --- Push string onto data stack ---
    # Push null terminator first (will be deepest element of string on stack)
    ldi A 0
    push A 

    # Loop K times to push characters from $stacks_buffer in reverse order.
    # K currently holds the length. We need to access buffer indices from K-1 down to 0.
    # Register K will be used as the loop counter and to derive the index.

:_rawin_push_char_loop
    # If K is 0, all chars pushed.
    tst K 0
    jmpt :_rawin_push_done 

    subi K 1 
        # K is now the 0-based index of the char to push
        # (e.g., if length was 2, K becomes 1 for 'I', then 0 for 'H')

    sto K $_input_read_offset 
        # Store K into memory to safely load into I
        # (assuming $_input_read_offset can be reused here)

    ldm I $_input_read_offset   ; I = index of char to read from buffer

    ldx A $stacks_buffer_pntr   ; A = M[M[$stacks_buffer_pntr] + I] (get char from $stacks_buffer).
    push A                      ; Push the character

    ldm K $_input_read_offset   ; K still holds current index, which is also remaining count before this iteration
    jmp :_rawin_push_char_loop

:_rawin_push_done
push L  ;restore return address
ret

#################################
# is used by INPUT and RAWIN for reading from KBD (buffer)
# Stores keypresses in $stacks_bufer of 16 adresses
# return status bit as TRUE

. $stacks_buffer 16
. $stacks_buffer_pntr 1
. $stacks_buffer_indx 1
% $stacks_buffer_pntr $stacks_buffer
% $stacks_buffer_indx 0

 
equ ~STACKS_BUFFER_MAX_DATA 15

@stacks_read_input
    sto Z $stacks_buffer_indx
    :read_input
        call @KBD_READ
        tst A \null
        jmpt :read_input

        tst A \Return
        jmpt :end_input

        ; Backspace handling
        tst A \BackSpace
        jmpf :store_in_buffer
            ldm X $cursor_x
            tst X 0                     ; Is cursor at column 0?
            jmpt :read_input            ; If so, can't backspace further

            dec I $stacks_buffer_indx   ; Decrement buffer index

            ; Screen erase logic (similar to processes3.asm shell)
            ; Remember After a SYSCALLs return, interrupts are enabled
            ;di ; Disable interrupts during cursor manipulation potentially
            ldm K $cursor_x
            subi K 1
            sto K $cursor_x             ; Move global cursor_x left
            ldi A \space                ; Character to print for erasing
            int ~SYSCALL_PRINT_CHAR     ; Prints space, syscall advances $cursor_x
            ldm K $cursor_x
            subi K 1
            sto K $cursor_x             ; Move global $cursor_x back to where the space was
            ;ei                          ; Re-enable interrupts

        jmp :read_input


        :store_in_buffer
        # Buffer overflow check:
        # Check if buffer is full of data characters before adding a new one.
            inc I $stacks_buffer_indx
            tst I ~STACKS_BUFFER_MAX_DATA
            jmpt :read_input

            stx A $stacks_buffer_pntr
            int ~SYSCALL_PRINT_CHAR ; Echo char, syscall handles cursor advancement
        jmp :read_input


    :end_input
        # Terminate the input string in the buffer with \Return.
        # $stacks_buffer_indx at this point holds the number of data characters.
        # The \Return will be placed at offset $stacks_buffer_indx.
        # After inc I, $stacks_buffer_indx will hold total_chars_including_terminator.
        # return Status bit is TRUE
    
        
        ldi A \Return
        inc I $stacks_buffer_indx
        stx A $stacks_buffer_pntr
        tste A A
ret


#################################
# STACKS String Operations
#################################

@stacks_show_from_stack
# Pops a null-terminated string from the data stack and prints it.
# String on stack (top to bottom): char1, char2, ..., charN, 0
# Consumes the string from the stack.
# Expects @print_char to print the character in register A.
# Expects @print_nl to print a newline.
    pop L ; Save return address
:_sshow_loop
    # Get character from data stack (A = char)
    pop A             

    tst A 0
    # Is character in A the null terminator (0)?
    jmpt :_sshow_done
    # Yes, end of string

    # Print character in A
    int ~SYSCALL_PRINT_CHAR ; Syscall prints char and handles cursor     

    jmp :_sshow_loop

:_sshow_done
    # String fully printed. Optionally print a newline or space.
    # For example, to print a newline:
    # call @print_nl
    # Or just ensure cursor is advanced if not done by print_char:
    # inc X $cursor_x (already done in loop, maybe one final one if needed)
    push L ; Restore return address
ret
    
    
@stacks_hash_from_stack
# Pops a null-terminated string from the data stack.
# Calculates a hash of the string.
# Pushes the final hash value onto the data stack.
# Consumes the string from the stack.
# Uses: $_hash_accumulator
    # Initialize hash accumulator (assuming Z is 0)
    pop L ; Save return address
    sto Z $_hash_accumulator  

:_shfs_loop
    # Get character (A = char)
    # Null terminator? Yes, finalize hash
    pop A          
    tst A 0                 
    jmpt :_shfs_finalize    

    # Simple hash: hash = (hash * 31) + char_code
    # This is just an example; choose a suitable algorithm.
    ldm K $_hash_accumulator
    muli K 31                 ; K = hash * 31
    add K A                   ; K = (hash * 31) + char_code
    sto K $_hash_accumulator  ; Store updated hash

    jmp :_shfs_loop

:_shfs_finalize
    ldm A $_hash_accumulator    ; Load final hash into A
    ; --- Add modulo operation to keep hash in a desired range ---
    ldi K 1000000000000000 ; Modulo for up to 15 digits (10^15)
                           ; Note: This immediate value is too large for LDI's typical operand.
                           ; This needs to be handled by loading it in parts or from memory.
    ; For now, let's assume a smaller, representable modulo for demonstration, e.g., 10^9
    ; ldi K 1000000000 ; Example: 1,000,000,000 (fits in a 32-bit-like range if LDI supports it)
    ; If K needs to be larger, it must be loaded from a memory variable:
    ; ldm K $HASH_MODULO_VALUE ; where . $HASH_MODULO_VALUE 1 and % $HASH_MODULO_VALUE 1000000000000000
    dmod A K      ; A = A / K (quotient), K = A % K (remainder)
    ;ld A K        ; Load the remainder (the actual hash value) into A
    ; --- End modulo operation ---
    ;push A
    push K                      ; Push final (modulo-adjusted) hash onto the data stack
    push L                      ; Restore return address
ret

;-------------------------------------------------------------------------------
; @stacks_shared_var_write
; Writes a value to a shared heap address, handling heap locking.
; Expects on STACKS stack (top first): value, heap_address
; Clobbers: A, B, K, M, I (internal usage for syscalls and memory access)
;-------------------------------------------------------------------------------
@stacks_shared_var_write
    pop L                       ; Save return address
    pop B                       ; B = heap_address (which is on top of the stack)
    pop A                       ; A = value (which is below the address)

    ; Loop to acquire the heap lock
:_ssvw_retry_lock
    int ~SYSCALL_LOCK_HEAP      ; Attempt to lock the heap

    ; Get current PID
    ldm K $CURRENT_PROCESS_ID   ; K = current_pid

    ; Calculate address of PTE[current_pid].syscall_retval
    ldm M $PROCESS_TABLE_BASE   ; M = base of process table
    ld I K                      ; I = current_pid
    muli I ~PTE_SIZE            ; I = current_pid * ~PTE_SIZE
    add M I                     ; M = address of PTE for current_pid
    addi M ~PTE_SYSCALL_RETVAL  ; M = address of PTE[current_pid].syscall_retval
    ld I M                      ; I = direct address of the syscall_retval field
    ldx K $mem_start            ; K = M[I] = syscall_retval

    tst K 0                     ; Test if K is 0 (lock acquisition successful)
    jmpt :_ssvw_lock_acquired   ; If successful, jump to critical section
    int ~SYSCALL_YIELD          ; Otherwise, yield the CPU
    jmp :_ssvw_retry_lock       ; And try again

    ; Lock acquired successfully
:_ssvw_lock_acquired
    ; Write the value (A) to the heap address (B)
    ld I B                      ; I = heap_address
    stx A $mem_start            ; Memory[I] = A

    ; Unlock the heap
    int ~SYSCALL_UNLOCK_HEAP    ; Release the heap lock

    push L                      ; Restore return address
    ret

;-------------------------------------------------------------------------------
; @stacks_shared_var_read
; Reads a value from a shared heap address, handling heap locking.
; Expects on STACKS stack (top first): heap_address
; Pushes onto STACKS stack: value_read
; Clobbers: A, B, K, M, I (internal usage for syscalls and memory access)
;-------------------------------------------------------------------------------
@stacks_shared_var_read
    pop L                       ; Save return address
    pop B                       ; B = heap_address

    ; Loop to acquire the heap lock
:_ssvr_retry_lock
    int ~SYSCALL_LOCK_HEAP      ; Attempt to lock the heap

    ; Get current PID
    ldm K $CURRENT_PROCESS_ID   ; K = current_pid

    ; Calculate address of PTE[current_pid].syscall_retval
    ldm M $PROCESS_TABLE_BASE   ; M = base of process table
    ld I K                      ; I = current_pid
    muli I ~PTE_SIZE            ; I = current_pid * ~PTE_SIZE
    add M I                     ; M = address of PTE for current_pid
    addi M ~PTE_SYSCALL_RETVAL  ; M = address of PTE[current_pid].syscall_retval
    ld I M                      ; I = direct address of the syscall_retval field
    ldx K $mem_start            ; K = M[I] = syscall_retval

    tst K 0                     ; Test if K is 0 (lock acquisition successful)
    jmpt :_ssvr_lock_acquired   ; If successful, jump to critical section
    int ~SYSCALL_YIELD          ; Otherwise, yield the CPU
    jmp :_ssvr_retry_lock       ; And try again

    ; Lock acquired successfully
:_ssvr_lock_acquired
    ; Read the value from the heap address (B) into A
    ld I B                      ; I = heap_address
    ldx A $mem_start            ; A = Memory[I]

    ; Unlock the heap
    int ~SYSCALL_UNLOCK_HEAP    ; Release the heap lock

    ; Push the read value (A) onto the STACKS stack
    push A

    push L                      ; Restore return address
    ret

;-------------------------------------------------------------------------------
; @_is_shared_address
; Checks if the address in register A falls within the shared heap region.
; Input: A = address to check.
; Output: CPU status bit is set to 1 (true) if A is a shared heap address,
;         0 (false) otherwise.
; Clobbers: K
;-------------------------------------------------------------------------------
@_is_shared_address
    ; Check if A >= $SHARED_HEAP_START_ADDRESS
    ldi K ~$SHARED_HEAP_START_ADDRESS
    tstg K A                     ; Status = 1 if K (START_ADDRESS) > A.
                                 ; This means A < START_ADDRESS.
    jmpt :_is_shared_addr_false  ; If A < START_ADDRESS, it's not shared.

    ; Check if A <= $SHARED_HEAP_END_ADDRESS
    ldi K ~$SHARED_HEAP_END_ADDRESS
    tstg A K                     ; Status = 1 if A > K (END_ADDRESS).
    jmpt :_is_shared_addr_false  ; If A > END_ADDRESS, it's not shared.

    ; If both checks passed, address A is within the shared heap.
    tste A A                     ; Set status bit to 1 (true, A == A)
    ret

:_is_shared_addr_false
    tstg A A                     ; Set status bit to 0 (false, A is not > A)
    ret



# --- STACKS Array Operations ---

@_array_length_logic
    ; Internal helper. Assumes interrupts are already disabled or heap is locked.
    ; Expects: C=base_address
    ; Returns: B=length
    ; Clobbers: I
    ; Does NOT handle di/ei or lock/unlock.
    sto C $_array_base_pntr_temp
    ldi I 0
    ldx B $_array_base_pntr_temp ; B = length
    ret

@stacks_array_length
    # Expects: base address of the array on top of the STACKS data stack.
    #          The parser is responsible for pushing the direct address of the
    #          array variable (e.g., 'my_array') onto the stack.
    # Action:
    #   1. Pops the array base address.
    #   2. Reads the length of the array (assumed to be stored at offset 0
    #      from the array's base address).
    #   3. Pushes this length value back onto the STACKS data stack.
    #
    # Array Memory Structure (assumed):
    #   array_base_address + 0: current length of the array
    #   array_base_address + 1: total allocated words for array structure
    #                           (element_capacity + 2)
    #   array_base_address + 2 onwards: array data elements
    #
    # Registers Used: A, B, C, K, I, M
    # Temporary Vars Used: $_array_base_pntr_temp

    pop L ; Save return address
    pop C ; C gets array_base_address from stack

    ; Check if the address is in the shared heap.
    ; Preserve C on the stack as @_is_shared_address clobbers registers.
    push C ; save base_address

    ld A C ; Move base address to A for the check
    call @_is_shared_address
    ; Status bit is now set if shared. A is clobbered.

    pop C ; restore base_address

    jmpt :_sal_is_shared ; If status is true, it's a shared array

; --- Local Array Path ---
:_sal_is_local
    di
    call @_array_length_logic ; C is set up. Result in B.
    ei
    jmp :_sal_done

; --- Shared Array Path ---
:_sal_is_shared
:_sal_retry_lock
    int ~SYSCALL_LOCK_HEAP
    ; Check syscall return value from PTE
    ldm K $CURRENT_PROCESS_ID
    ldm M $PROCESS_TABLE_BASE
    ld I K
    muli I ~PTE_SIZE
    add M I
    addi M ~PTE_SYSCALL_RETVAL
    ld I M
    ldx K $mem_start ; K = syscall_retval
    tst K 0
    jmpt :_sal_lock_acquired    ; If successful, jump to critical section
    int ~SYSCALL_YIELD          ; Otherwise, yield the CPU
    jmp :_sal_retry_lock        ; And try again

    ; --- Lock Acquired ---
    :_sal_lock_acquired
    di
    call @_array_length_logic ; C is set up. Result in B.
    ;ei
    ; --- End of critical section ---

    int ~SYSCALL_UNLOCK_HEAP

:_sal_done
    push B ; Push the length onto the STACKS data stack
    push L ; Restore return address
ret

@_array_write_logic
    ; Internal helper. Assumes interrupts are already disabled or heap is locked.
    ; Expects: A=value, B=index, C=base_address
    ; Clobbers: K, I, C (C is reused)
    ; Does NOT handle di/ei or lock/unlock.
    sto C $_array_base_pntr_temp
    ; --- Bounds Check ---
    ldi I 1
    ldx K $_array_base_pntr_temp
    subi K 2 ; K = element_capacity
    tstg K B
    jmpt :_awl_index_valid
    call @fatal_error ; Index out of bounds
:_awl_index_valid
    ; --- Write Value ---
    ldi I 2
    add I B
    stx A $_array_base_pntr_temp
    ; --- Update Length ---
    ldi I 0
    ldx K $_array_base_pntr_temp ; K = current_length
    ld C B ; C = index
    addi C 1 ; C = new_potential_length
    tstg C K
    jmpf :_awl_length_no_update
    stx C $_array_base_pntr_temp
:_awl_length_no_update
    ret


@stacks_array_write
    # Expects on STACKS data stack (top to bottom):
    #   array_base_address
    #   index
    #   value
    # Action:
    #   1. Pops array_base_address, index, and value.
    #   2. Calculates element capacity: M[array_base_address + 1] - 2.
    #      (Assumes parser stores total allocated words at M[array_base_address + 1]).
    #   3. Checks if index is within bounds [0, element_capacity-1].
    #      If out of bounds, calls @fatal_error.
    #   4. Writes value to M[array_base_address + 2 + index].
    #   5. Updates current_length at M[array_base_address + 0] if (index + 1) > current_length.
    #
    # Array Memory Structure (assumed by this routine, based on current parser):
    #   array_base_address + 0: current length of the array
    #   array_base_address + 1: total allocated words for array structure (capacity_for_elements + 2)
    #   array_base_address + 2 onwards: array data elements
    #
    # Registers Used: A (value), B (index), C (array_base_address, then new_potential_length),
    #                 K, I, M (for checks and logic)
    # Temporary Vars Used: $_array_base_pntr_temp

    pop L ; Save return address
    pop C ; C gets array_base_address from stack
    pop B ; B gets index from stack
    pop A ; A gets value from stack

    ; Check if the address is in the shared heap.
    ; Preserve A, B, C on the stack as @_is_shared_address clobbers registers.
    push A ; save value
    push B ; save index
    push C ; save base_address

    ld A C ; Move base address to A for the check
    call @_is_shared_address
    ; Status bit is now set if shared. A is clobbered.

    pop C ; restore base_address
    pop B ; restore index
    pop A ; restore value

    jmpt :_saw_is_shared ; If status is true, it's a shared array

; --- Local Array Path ---
:_saw_is_local
    di    ; Disable interrupts for atomic operation on local array
    call @_array_write_logic ; A, B, C are already set up
    ei    ; Re-enable interrupts
    jmp :_saw_done

; --- Shared Array Path ---
:_saw_is_shared
:_saw_retry_lock
    int ~SYSCALL_LOCK_HEAP
    ; Check syscall return value from PTE
    ldm K $CURRENT_PROCESS_ID
    ldm M $PROCESS_TABLE_BASE
    ld I K
    muli I ~PTE_SIZE
    add M I
    addi M ~PTE_SYSCALL_RETVAL
    ld I M
    ldx K $mem_start ; K = syscall_retval
    tst K 0
    jmpt :_saw_lock_acquired    ; If successful, jump to critical section
    int ~SYSCALL_YIELD          ; Otherwise, yield the CPU
    jmp :_saw_retry_lock        ; And try again

    ; --- Lock Acquired ---
    :_saw_lock_acquired
    di
    call @_array_write_logic ; A, B, C are already set up
    ;ei
    ; --- End of critical section ---

    int ~SYSCALL_UNLOCK_HEAP

:_saw_done
    push L ; Restore return address
ret




@_array_append_logic
    ; Internal helper. Assumes interrupts are already disabled or heap is locked.
    ; Expects: A=value, C=base_address
    ; Clobbers: K, L, I
    ; Does NOT handle di/ei or lock/unlock.
    sto C $_array_base_pntr_temp
    ; --- Read current_length (K) and calculate element_capacity (L) ---
    ldi I 0
    ldx K $_array_base_pntr_temp ; K = current_length
    ldi I 1
    ldx L $_array_base_pntr_temp
    subi L 2 ; L = element_capacity
    ; --- Bounds Check: Is current_length (K) < element_capacity (L)? ---
    tstg L K
    jmpt :_aal_has_space
    call @fatal_error ; Array full
:_aal_has_space
    ; --- Write Value to Array ---
    ldi I 2
    add I K ; I = 2 + current_length
    stx A $_array_base_pntr_temp
    ; --- Update Length ---
    addi K 1 ; K = new_length
    ldi I 0
    stx K $_array_base_pntr_temp
    ret

@stacks_array_append
    # Expects on STACKS data stack (top to bottom):
    #   array_base_address
    #   value
    # Action:
    #   1. Pops array_base_address and value.
    #   2. Reads current_length from M[array_base_address + 0].
    #   3. Calculates element_capacity: M[array_base_address + 1] - 2.
    #   4. Checks if current_length < element_capacity.
    #      If not (array is full), calls @fatal_error.
    #   5. Writes value to M[array_base_address + 2 + current_length].
    #   6. Increments and stores the new current_length at M[array_base_address + 0].
    #
    # Array Memory Structure (assumed):
    #   array_base_address + 0: current length of the array
    #   array_base_address + 1: total allocated words for array structure (capacity_for_elements + 2)
    #   array_base_address + 2 onwards: array data elements
    #
    # Registers Used: A (value), C (array_base_address),
    #                 K, I, M (for checks and logic), X (for return address)
    # Temporary Vars Used: $_array_base_pntr_temp

    pop X ; Save return address, using X since L is in use 
    pop C ; C gets array_base_address from stack
    pop A ; A gets value from stack

    ; Check if the address is in the shared heap.
    ; Preserve A, C on the stack as @_is_shared_address clobbers registers.
    push A ; save value
    push C ; save base_address

    ld A C ; Move base address to A for the check
    call @_is_shared_address
    ; Status bit is now set if shared. A is clobbered.

    pop C ; restore base_address
    pop A ; restore value

    jmpt :_saa_is_shared ; If status is true, it's a shared array

; --- Local Array Path ---
:_saa_is_local
    di
    call @_array_append_logic ; A, C are already set up
    ei
    jmp :_saa_done

; --- Shared Array Path ---
:_saa_is_shared
:_saa_retry_lock
    int ~SYSCALL_LOCK_HEAP
    ; Check syscall return value from PTE
    ldm K $CURRENT_PROCESS_ID
    ldm M $PROCESS_TABLE_BASE
    ld I K
    muli I ~PTE_SIZE
    add M I
    addi M ~PTE_SYSCALL_RETVAL
    ld I M
    ldx K $mem_start ; K = syscall_retval
    tst K 0
    jmpt :_saa_lock_acquired    ; If successful, jump to critical section
    int ~SYSCALL_YIELD          ; Otherwise, yield the CPU
    jmp :_saa_retry_lock        ; And try again

    ; --- Lock Acquired ---
    :_saa_lock_acquired
    di
    call @_array_append_logic ; A, C are already set up
    ;ei
    ; --- End of critical section ---

    int ~SYSCALL_UNLOCK_HEAP

:_saa_done
    push X ; Restore return address, using X since L is in use
ret


@_array_read_logic
    ; Internal helper. Assumes interrupts are already disabled or heap is locked.
    ; Expects: A=index, C=base_address
    ; Returns: B=value_read
    ; Clobbers: K, I
    ; Does NOT handle di/ei or lock/unlock.
    sto C $_array_base_pntr_temp
    ; --- Bounds Check ---
    ldi I 1
    ldx K $_array_base_pntr_temp
    subi K 2 ; K = element_capacity
    tstg K A
    jmpt :_arl_index_valid
    call @fatal_error ; Index out of bounds
:_arl_index_valid
    ; --- Read Value ---
    ldi I 2
    add I A
    ldx B $_array_base_pntr_temp ; B = value read
    ret




@stacks_array_read
    # Expects on STACKS data stack (top to bottom):
    #   array_base_address
    #   index
    # Action:
    #   1. Pops array_base_address and index.
    #   2. Calculates element_capacity: M[array_base_address + 1] - 2.
    #   3. Checks if index is within bounds [0, element_capacity-1].
    #      If out of bounds, calls @fatal_error.
    #   4. Reads value from M[array_base_address + 2 + index].
    #   5. Pushes the read value onto the STACKS data stack.
    #
    # Array Memory Structure (assumed):
    #   array_base_address + 0: current length of the array
    #   array_base_address + 1: total allocated words for array structure (capacity_for_elements + 2)
    #   array_base_address + 2 onwards: array data elements
    #
    # Registers Used: A (index), B (value_read), C (array_base_address),
    #                 K, I, M (for checks and logic)
    # Temporary Vars Used: $_array_base_pntr_temp

    pop L ; Save return address
    pop C ; C gets array_base_address from stack
    pop A ; A gets index from stack

    ; Check if the address is in the shared heap.
    ; Preserve A, C on the stack as @_is_shared_address clobbers registers.
    push A ; save index
    push C ; save base_address

    ld A C ; Move base address to A for the check
    call @_is_shared_address
    ; Status bit is now set if shared. A is clobbered.

    pop C ; restore base_address
    pop A ; restore index

    jmpt :_sar_is_shared ; If status is true, it's a shared array

; --- Local Array Path ---
:_sar_is_local
    di    ; Disable interrupts for atomic operation on local array
    call @_array_read_logic ; A, C are already set up. Result in B.
    ei    ; Re-enable interrupts
    jmp :_sar_done

; --- Shared Array Path ---
:_sar_is_shared
:_sar_retry_lock
    int ~SYSCALL_LOCK_HEAP
    ; Check syscall return value from PTE
    ldm K $CURRENT_PROCESS_ID
    ldm M $PROCESS_TABLE_BASE
    ld I K
    muli I ~PTE_SIZE
    add M I
    addi M ~PTE_SYSCALL_RETVAL
    ld I M
    ldx K $mem_start ; K = syscall_retval
    tst K 0
    jmpt :_sar_lock_acquired    ; If successful, jump to critical section
    int ~SYSCALL_YIELD          ; Otherwise, yield the CPU
    jmp :_sar_retry_lock        ; And try again

    ; --- Lock Acquired ---
    :_sar_lock_acquired
    di
    call @_array_read_logic ; A, C are set up. Result in B.
    ;ei
    ; --- End of critical section ---

    int ~SYSCALL_UNLOCK_HEAP

:_sar_done
    push B ; Push the read value (B) onto the STACKS data stack
    push L ; Restore return address
ret

; ==============================================================================
; Network Extension Runtime Helpers
; ==============================================================================

@stacks_network_write
    ; Called by parser-generated stubs for STACKS 'CONNECTION WRITE'.
    ; STACKS language construct: ident CONNECTION WRITE dst-addr serviceID
    ; The calling stub (from parseV3.py) will have set up registers as follows:
    ;   - Register A: dst-addr (destination NIC ID)
    ;   - Register B: Value to send (popped from STACKS stack)
    ;   - Register C: service_id_out
    ;   - Register K: reply_pid (the PID of the process on the sender host expecting the reply)


    # temp memory registers
    . $reg_A_cp 1
    . $reg_B_cp 1
    . $reg_C_cp 1

    ; Encode the payload: (value * 10) + reply_pid
    ; Value is in B, reply_pid is in K. Result should go back into B.
    muli B 10   ; B = B * 10
    add B K     ; B = B + K (encoded payload)

    ; @send_data_packet_sub (from networkR4.asm) expects:
    ;   A: dst_addr
    ;   B: data_to_send
    ;   C: service_id_out

    ; from networkR4.asm
    ; call @send_data_packet_sub    ; OLD code
    # save register values, for resend purpose
    sto A $reg_A_cp
    sto B $reg_B_cp
    sto C $reg_C_cp

    :stacks_network_write_loop

        call @send_nic_message      ; Call the new routine
        # check the result in A=0 at succes, A=1 when fails 
        tst A 0                            ; test for succes
        jmpt :stacks_network_write_done
        int ~SYSCALL_YIELD                 ; Yield and ...
        # Restore the registers, before ..
        ldm A $reg_A_cp
        ldm B $reg_B_cp
        ldm C $reg_C_cp
        jmp :stacks_network_write_loop    ; retry after failing

    :stacks_network_write_done
    
ret

# a simple name, for better use in the Stacks language
@readService0
    ; Helper routine for STACKS 'CONNECTION READ'.
    ; STACKS language construct: ident CONNECTION READ @user_service_routine
    ; This helper is intended to be called by the @user_service_routine.
    ; It reads from the network service 0 buffer using @read_service0_data.
    ; It expects the calling process's PID in Register A.
    ; It then pushes two items onto the STACKS stack:
    ;   1. The value read (or a dummy value like 0 if no data).
    ;   2. A status code: 0 for success, 1 for failure (no data).

    pop L ; Save the original return address from the stack

    ; from networkdispatcher.asm
    call @read_service0_data 
    ; @read_service0_data returns:
    ;   - In Register A: data byte if status bit is 1. (Content of A is undefined if status bit is 0)
    ;   - CPU Status bit: 1 if data was read successfully.
    ;                     0 if buffer was empty.

    ; Jump if CPU status bit was 1 (data read)
    jmpt :_srs0bps_data_read_success 

    ; --- Failure Case (Buffer Empty) ---
    ; CPU status bit was 0, indicating @read_service0_data found no data.
    ; No dummy data value needed when no data available, just return status.
    ; Push 1 as the status_code (failure/no data)
    ldi A 1         
    push A
    jmp :_srs0bps_done

:_srs0bps_data_read_success
    ; --- Success Case (Data Read) ---
    ; CPU status bit was 1, data from @read_service0_data is in Register A.
    ; Register A already contains the data byte.
    push A ; Push the actual data byte onto STACKS stack   
    ; Push 0 as the status_code (success) 
    ldi A 0         
    push A

:_srs0bps_done
    push L ; Restore the original return address to the stack
ret