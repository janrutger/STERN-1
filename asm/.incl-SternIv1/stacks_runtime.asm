# STACKS Runtime library
#
# Implements an "Empty Ascending Stack" for STACKS operations.
# - $sr_stack_ptr: Base address of the STACKS runtime's data stack memory area.
# - $sr_stack_idx: A memory variable storing the index of the NEXT FREE SLOT on the STACKS runtime data stack.
#                     Initialized to 0. Stack grows upwards.
#
# Assumed behavior of specific STERN-1 instructions:
# inc I <addr>:
#   1. I = M[addr] (Register I gets current value from memory)
#   2. M[addr] = M[addr] + 1 (Value in memory is incremented)
#
# dec I <addr>:
#   1. I = M[addr] (Register I gets current value from memory)
#   2. I = I - 1   (Register I is decremented)
#   3. M[addr] = I (Decremented value from I is stored back to memory)

# --- STACKS Runtime Data Stack Definition ---
; Memory area for the STACKS runtime data stack (e.g., 64 words)
; Pointer to the base address of $sr_stack_mem
; Index for the next free slot in $sr_stack_mem
; Initialize $sr_stack_ptr to point to $sr_stack_mem
; Initialize $sr_stack_idx to 0 (empty stack)
. $sr_stack_mem 64          
. $sr_stack_ptr 1           
. $sr_stack_idx 1           
% $sr_stack_ptr $sr_stack_mem 
% $sr_stack_idx 0            




# --- Temporary variables for string operations (if any remain needed) ---

# Used by CHAR_AT to temporarily store the index value for loading into I
# Used by STRLEN to store calculated length
# These are kept for now, assuming CHARAT and STRLEN might be implemented later
# based on stack strings or might be removed if not needed.
. $_str_op_idx_val 1    
. $_str_op_len_val 1    

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
@stacks_runtime_init
    # when the lib must be initalized

    # Initialize timer epochs.
    call @stacks_timer_init
    
ret

#################################
@push_A
    inc I $sr_stack_idx   
    ; I_reg = M[$sr_stack_idx], then M[$sr_stack_idx]++
    stx A $sr_stack_ptr     
    ; M[M[$sr_stack_ptr] + I_reg] = A_reg
ret

@push_B
    inc I $sr_stack_idx     
    ; I_reg = M[$sr_stack_idx], then M[$sr_stack_idx]++
    stx B $sr_stack_ptr     
    ; M[M[$sr_stack_ptr] + I_reg] = B_reg
ret


@pop_A
    dec I $sr_stack_idx     
    ; temp = M[$sr_stack_idx]-1, I_reg = temp, M[$sr_stack_idx] = temp
    ldx A $sr_stack_ptr     
    ; A_reg = M[M[$sr_stack_ptr] + I_reg]
ret

@pop_B
    dec I $sr_stack_idx     
    ; temp = M[$sr_stack_idx]-1, I_reg = temp, M[$sr_stack_idx] = temp
    ldx B $sr_stack_ptr     
    ; B_reg = M[M[$sr_stack_ptr] + I_reg]
ret

#################################
@dup 
    call @pop_A
    call @push_A
    call @push_A
ret

@swap
    call @pop_A
    call @pop_B
    call @push_A
    call @push_B
ret

@drop
    call @pop_A
ret

@over
    # ( x1 x2 -- x1 x2 x1 )
    # Duplicates the second item on the stack to the top.
    call @pop_A  
    call @pop_B  
    call @push_B 
    call @push_A 
    call @push_B 
ret

#################################
@plus
    call @pop_B
    call @pop_A
    add A B
    call @push_A
ret

@minus
    call @pop_B
    call @pop_A
    sub A B
    call @push_A
ret

@multiply
    call @pop_B
    call @pop_A
    mul A B
    call @push_A
ret

@divide
    call @pop_B
    call @pop_A
    div A B
    call @push_A
ret

@mod
    call @pop_B
    call @pop_A
    dmod A B
    call @push_B
ret

@stacks_gcd
    # Pops two numbers from the STACKS data stack,
    # calculates their Greatest Common Divisor (GCD) using the Euclidean algorithm by subtraction,
    # and pushes the result back onto the STACKS data stack.
    # Assumes non-negative inputs for simplicity.
    # GCD(x, 0) = |x|, GCD(0, y) = |y|, GCD(0,0) = 0 (conventionally).
    call @pop_B
    # B gets the second operand (num2)
    call @pop_A
    # A gets the first operand (num1)

    # Handle cases where one or both operands are zero.
    tst B 0
    # Is B zero?
    jmpt :_gcd_A_is_result
    # If B is 0, GCD is A.
    tst A 0
    # Is A zero?
    jmpt :_gcd_B_is_result
    # If A is 0, GCD is B.

:_gcd_loop
    tste A B
    # Is A equal to B?
    jmpt :_gcd_A_is_result
    # If A == B, then GCD is A (or B).

    tstg A B
    # Is A > B?
    jmpt :_gcd_A_greater_B
    # If A > B, jump to subtract B from A.
    # Else (A < B, since A != B), so B = B - A.
    sub B A
    jmp :_gcd_loop
:_gcd_A_greater_B
    # A > B, so A = A - B.
    sub A B
    jmp :_gcd_loop

:_gcd_B_is_result
    ld A B
    # Result was B, move to A for pushing.
:_gcd_A_is_result
    call @push_A
    # Push the result (which is in A).
ret

# --- SIO Channel Control ---
# These STACKS runtime routines will call the SIO handling routines
# (e.g., @open_channel, @close_channel) which are provided by the
# STERN-1 kernel (from serialIO.asm).

@sio_channel_on
    # Pops channel number from the STACKS stack.
    # Calls @open_channel, which expects the channel number in register A.
    call @pop_A
    # A now holds the channel number.
    call @open_channel
ret

@sio_channel_off
    # Pops channel number from the STACKS stack.
    # Calls @close_channel, which expects the channel number in register A.
    call @pop_A
    # A now holds the channel number.
    call @close_channel
ret

# --- Timer Operations ---

@stacks_sleep
    call @pop_B
    ldm A $CURRENT_TIME
    add B A
    :sleep_loop
        ldm A $CURRENT_TIME
        tstg A B
        jmpf :sleep_loop
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
    # Validates if 0 <= A <= ~MAX_TIMER_IDX.
    # If valid, Register I is set to the timer instance value (for indexed access),
    # and Register A contains the timer instance.
    # If invalid, calls @fatal_error and does not return.
    # Clobbers: K

    call @pop_A
    # A now has the timer instance.

    # Check if A > ~MAX_TIMER_IDX
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
    # If invalid, @fatal_error is called by @_validate_and_get_timer_address.
    call @_validate_and_get_timer_address
    # If @_validate_and_get_timer_address returns, the index is valid.
    # No need to check status flag here.

    # Instance is valid, I_reg is set to instance, A_reg holds instance.
    ldm K $CURRENT_TIME
    # K_reg = current time.
    stx K $TIMER_EPOCHS
    # M[$TIMER_EPOCHS + I_reg] = K_reg.
:_timer_set_end
    # This label is no longer strictly needed if there's only one path to ret,
    # but kept for clarity or future conditional logic if any.
ret

@stacks_timer_get
    # Expects: timer_instance on top of stack.
    # Pops timer_instance.
    # If valid, calculates elapsed time ($CURRENT_TIME - epoch) and pushes it.
    # If invalid, calls @fatal_error.
    # The @fatal_error call is now handled by @_validate_and_get_timer_address.
    call @_validate_and_get_timer_address
    # If @_validate_and_get_timer_address returns, the index is valid.

    # Instance is valid, I_reg is set to instance, A_reg holds instance.
    ldx K $TIMER_EPOCHS
    # K_reg = stored epoch M[$TIMER_EPOCHS + I_reg].
    ldm A $CURRENT_TIME
    # A_reg = current time.
    sub A K
    # A_reg = current_time - epoch.
    call @push_A
ret

@stacks_timer_print
    # Expects: timer_instance on top of stack.
    # Pops timer_instance.
    # If valid, prints "Timer [N]: [elapsed_time]\n".
    # Assumes @print_char does not advance cursor; @print_to_BCD does.
    # If invalid, @fatal_error is called by @_validate_and_get_timer_address.
    call @_validate_and_get_timer_address
    # A_reg holds the timer instance if valid.
    # If @_validate_and_get_timer_address returns, the index is valid.


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
    call @print_char
    inc X $cursor_x
    ldi A \i
    call @print_char
    inc X $cursor_x
    ldi A \m
    call @print_char
    inc X $cursor_x
    ldi A \e
    call @print_char
    inc X $cursor_x
    ldi A \r
    call @print_char
    inc X $cursor_x
    ldi A \space
    call @print_char
    inc X $cursor_x

    # Print timer instance number (from $_timer_instance_temp)
    ldm A $_timer_instance_temp
    call @print_to_BCD
    # Assumes @print_to_BCD handles its own cursor advancement.

    # Print ": "
    ldi A \:
    call @print_char
    inc X $cursor_x
    ldi A \space
    call @print_char
    inc X $cursor_x

    # Print elapsed time (which is in B_reg)
    ld A B
    # Move elapsed time to A_reg for @print_to_BCD.
    call @print_to_BCD

    # Print newline
    call @print_nl
    jmp :_timer_print_end 
    # Successfully printed, go to the end.

:_timer_print_end
ret

#################################
@print
    call @pop_A
    call @print_to_BCD
    call @print_nl

ret

equ ~plotter 0
@plot
    call @pop_B
    ldi A ~plotter
    call @write_channel
ret


#################################
@eq
    call @pop_B
    call @pop_A
    tste A B
    call @set_true_false
ret

@ne
    call @pop_B
    call @pop_A
    tste A B
    jmpf :ne_true
        ; set FALSE
        ldi A 1
        call @push_A
    jmp :ne_end
    :ne_true
        ldi A 0
        call @push_A
:ne_end
ret


@gt 
    call @pop_B
    call @pop_A
    tstg A B
    call @set_true_false
ret

@lt
    call @pop_A
    call @pop_B
    tstg A B
    call @set_true_false
ret

@set_true_false
    # Helper for comparison ops, assumes comparison instruction just ran.
    # Pushes 0 onto the stack if the preceding comparison was TRUE.
    # Pushes 1 (non-zero) onto the stack if the preceding comparison was FALSE.
    jmpf :set_false
        ldi A 0
        call @push_A
    jmp :set_end
    :set_false
        ldi A 1
        call @push_A
:set_end    
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
call @prompt_stacks
:_input_start_over
# This label is a loop point to re-prompt the user if the input is completely invalid.
    
    call @cursor_on

    # Get the user's input. This populates $stacks_buffer.
    # After this call, M[$stacks_buffer_indx] holds the count of characters
    # entered, including the terminating \Return character.
    call @stacks_read_input
    call @print_nl

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
    
    call @prompt_stacks_err
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
    call @prompt_stacks_err
    jmp :_input_start_over

    :_found_valid_digits
    # Apply the determined sign to the parsed number.
    ldm A $_parsed_number
    ldm K $_number_sign
    mul A K
    # A = parsed_number * sign.
    call @push_A
    # Push the final integer result onto the STACKS data stack.
ret


#################################
@stacks_raw_input_string
# Implements the RAWIN functionality for STACKS. (Modified for on-stack strings)
# 1. Prompts the user for input.
# 2. Reads a line of raw characters using @stacks_read_input (into $stacks_buffer).
# 3. Pushes the characters from $stacks_buffer onto the data stack in correct order:
#    char1, char2, ..., charN, null_terminator (0) (top to bottom on stack).

    call @prompt_stacks
:_rawin_start_over
    # Loop point for re-prompting if input is empty.
    call @cursor_on
    # print \_ as cursor, will be overwritten by the value
    call @stacks_read_input

    # $stacks_buffer is now filled with user input.
    # M[$stacks_buffer_indx] contains the length, including the trailing \Return.
    
    call @print_nl
    # Print a newline after the user presses Enter.


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
        call @prompt_stacks_err 
        jmp :_rawin_start_over

:_rawin_len_ok
    # K holds the content length.

    # --- Push string onto data stack ---
    # Push null terminator first (will be deepest element of string on stack)
    ldi A 0
    call @push_A

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

    ldm I $_input_read_offset 
        # I = index of char to read from buffer

    ldx A $stacks_buffer_pntr
    # A = M[M[$stacks_buffer_pntr] + I] (get char from $stacks_buffer).
    call @push_A 
        # Push the character

    ldm K $_input_read_offset 
        # K still holds current index, which is also remaining count before this iteration
    jmp :_rawin_push_char_loop

:_rawin_push_done
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

        tst A \BackSpace
        jmpf :store_in_buffer
            ldm X $cursor_x
            tst X 0
            jmpt :read_input

            dec X $cursor_x
            dec I $stacks_buffer_indx

            ldi A \space              
            call @print_char          
            ;dec X $cursor_x 

        jmp :read_input


        :store_in_buffer
        # Buffer overflow check:
        # Check if buffer is full of data characters before adding a new one.
            inc I $stacks_buffer_indx
            tst I ~STACKS_BUFFER_MAX_DATA
            jmpt :read_input

            stx A $stacks_buffer_pntr
            call @print_char

            inc X $cursor_x
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
:_sshow_loop
    # Get character from data stack (A = char)
    call @pop_A             

    tst A 0
    # Is character in A the null terminator (0)?
    jmpt :_sshow_done
    # Yes, end of string

    # Print character in A
    # Advance cursor (assuming @print_char doesn't)
    call @print_char        
    inc X $cursor_x         
    jmp :_sshow_loop

:_sshow_done
    # String fully printed. Optionally print a newline or space.
    # For example, to print a newline:
    # call @print_nl
    # Or just ensure cursor is advanced if not done by print_char:
    # inc X $cursor_x (already done in loop, maybe one final one if needed)
ret
    
@stacks_hash_from_stack
# Pops a null-terminated string from the data stack.
# Calculates a hash of the string.
# Pushes the final hash value onto the data stack.
# Consumes the string from the stack.
# Uses: $_hash_accumulator
    # Initialize hash accumulator (assuming Z is 0)
    sto Z $_hash_accumulator  

:_shfs_loop
    # Get character (A = char)
    # Null terminator? Yes, finalize hash
    call @pop_A             
    tst A 0                 
    jmpt :_shfs_finalize    

    # Simple hash: hash = (hash * 31) + char_code
    # This is just an example; choose a suitable algorithm.
    ldm K $_hash_accumulator
    muli K 31               
        # K = hash * 31
    add K A                 
        # K = (hash * 31) + char_code
    sto K $_hash_accumulator  
        # Store updated hash

    jmp :_shfs_loop

:_shfs_finalize
    ldm A $_hash_accumulator 
        # Load final hash into A
    call @push_A             
        # Push it onto the data stack
ret

# --- STACKS Array Operations ---

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
    # Registers Used: A, B, I
    # Temporary Vars Used: $_array_base_pntr_temp

    call @pop_A                     
    # A gets array_base_address from stack
    sto A $_array_base_pntr_temp    
    # M[$_array_base_pntr_temp] = array_base_address
    ldi I 0                         
    # I = 0 (offset for length field)
    ldx B $_array_base_pntr_temp    
    # B = M[M[$_array_base_pntr_temp] + I] => B = M[array_base_address + 0] = length
    call @push_B                     
    # Push the length onto the STACKS data stack
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
    #                 K (capacity, then current_length), I (offset for ldx/stx)
    # Temporary Vars Used: $_array_base_pntr_temp

    ;call @pop_C                     
        ; C gets array_base_address from stack
    call @pop_A
    ld C A
    call @pop_B                     
        ; B gets index from stack
    call @pop_A                    
        ; A gets value from stack

    sto C $_array_base_pntr_temp    
        ; M[$_array_base_pntr_temp] = array_base_address (from C)

    ; --- Bounds Check ---
    ; K will hold element_capacity. B holds index.
    ; Valid indices are 0 to element_capacity-1.
    ; Error if index (B) >= element_capacity (K).
    ldi I 1                         
        ; I = 1 (offset for total_allocated_words field)
    ldx K $_array_base_pntr_temp    
        ; K = M[M[$_array_base_pntr_temp] + 1] => K = total_allocated_words
    subi K 2                        
        ; K = total_allocated_words - 2 = element_capacity
        ; K now holds element_capacity.
    
    ; Check if index (B) is less than element_capacity (K).
    ; If B < K (i.e., K > B), then index is valid.
    tstg K B                        
    ; Set status if K > B (element_capacity > index)
    jmpt :_array_write_index_valid  
    ; If status is true (K > B), index is valid. Jump to write.
    ; Else (K <= B, i.e., index >= element_capacity), then it's an error. Fall through.
:_array_write_index_out_of_bounds
    call @fatal_error             
    ; Index out of bounds. @fatal_error halts execution.

:_array_write_index_valid
    ; --- Write Value to Array ---
    ; Target address: M[array_base_address + 2 + index]
    ; M[$_array_base_pntr_temp] holds array_base_address.
    ; B holds index. A holds value.
    ldi I 2                         
    ; I = 2 (base offset for data elements)
    add I B                         
    ; I = 2 + index (B)
    stx A $_array_base_pntr_temp    
    ; M[M[$_array_base_pntr_temp] + I] = value (A)

    ; --- Update Length ---
    ; current_length is at M[array_base_address + 0]
    ; new_potential_length = index + 1
    ; if new_potential_length > current_length, update current_length.
    ldi I 0                         
    ; I = 0 (offset for length field)
    ldx K $_array_base_pntr_temp    
    ; K = M[M[$_array_base_pntr_temp] + 0] => K = current_length
    ld C B                          
    ; C = index (B)
    addi C 1                        
    ; C = index + 1 (this is the new potential length)
    tstg C K                        
    ; Set status if C > K (new_potential_length > current_length)
    jmpf :_array_write_length_no_update 
    ; If C is not > K, no length update needed.
    stx C $_array_base_pntr_temp    
    ; Store new length (C) into M[array_base_address + 0] (I is still 0)
:_array_write_length_no_update
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
    #                 K (current_length, then new_length), L (element_capacity),
    #                 I (offset for ldx/stx)
    # Temporary Vars Used: $_array_base_pntr_temp

    ;call @pop_C
    call @pop_A
    ld C A
    # C gets array_base_address from stack
    call @pop_A
    # A gets value from stack

    sto C $_array_base_pntr_temp
    # M[$_array_base_pntr_temp] = array_base_address (from C)

    # --- Read current_length (K) and calculate element_capacity (L) ---
    ldi I 0
    # I = 0 (offset for current_length field)
    ldx K $_array_base_pntr_temp
    # K = M[M[$_array_base_pntr_temp] + 0] => K = current_length

    ldi I 1
    # I = 1 (offset for total_allocated_words field)
    ldx L $_array_base_pntr_temp
    # L = M[M[$_array_base_pntr_temp] + 1] => L = total_allocated_words
    subi L 2
    # L = total_allocated_words - 2 = element_capacity

    # --- Bounds Check: Is current_length (K) < element_capacity (L)? ---
    # If K < L (i.e., L > K), there is space.
    tstg L K
    # Set status if L > K (element_capacity > current_length)
    jmpt :_array_append_has_space
    # If status is true (L > K), there's space. Jump to append.
    # Else (L <= K, i.e., current_length >= element_capacity), array is full. Fall through.
:_array_append_full
    call @fatal_error
    # Array full. @fatal_error halts execution.

:_array_append_has_space
    # --- Write Value to Array ---
    # Target address: M[array_base_address + 2 + current_length]
    # K holds current_length. A holds value.
    ldi I 2
    # I = 2 (base offset for data elements)
    add I K
    # I = 2 + current_length (K)
    stx A $_array_base_pntr_temp
    # M[M[$_array_base_pntr_temp] + I] = value (A)

    # --- Update Length ---
    # Increment current_length (K) and store it back.
    addi K 1
    # K = new_length (current_length + 1)
    ldi I 0
    # I = 0 (offset for length field)
    stx K $_array_base_pntr_temp
    # Store new_length (K) into M[array_base_address + 0]
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
    #                 K (element_capacity), I (offset for ldx/stx)
    # Temporary Vars Used: $_array_base_pntr_temp

    ;call @pop_C
    call @pop_A
    ld C A
    # C gets array_base_address from stack
    call @pop_A
    # A gets index from stack

    sto C $_array_base_pntr_temp
    # M[$_array_base_pntr_temp] = array_base_address (from C)

    # --- Bounds Check ---
    # K will hold element_capacity. A holds index.
    # Valid indices are 0 to element_capacity-1.
    # Error if index (A) >= element_capacity (K).
    ldi I 1
    # I = 1 (offset for total_allocated_words field)
    ldx K $_array_base_pntr_temp
    # K = M[M[$_array_base_pntr_temp] + 1] => K = total_allocated_words
    subi K 2
    # K = total_allocated_words - 2 = element_capacity

    tstg K A
    # Set status if K > A (element_capacity > index). This means index is < capacity.
    jmpt :_array_read_index_valid
    # If status is true (K > A), index is valid. Jump to read.
    # Else (K <= A, i.e., index >= element_capacity), it's an error. Fall through.
:_array_read_index_out_of_bounds
    call @fatal_error
    # Index out of bounds. @fatal_error halts execution.

:_array_read_index_valid
    # --- Read Value from Array ---
    # Target address: M[array_base_address + 2 + index]
    # M[$_array_base_pntr_temp] holds array_base_address.
    # A holds index. B will hold the value.
    ldi I 2
    # I = 2 (base offset for data elements)
    add I A
    # I = 2 + index (A)
    ldx B $_array_base_pntr_temp
    # B = M[M[$_array_base_pntr_temp] + I] (value_read)

    call @push_B
    # Push the read value (B) onto the STACKS data stack
ret

; ==============================================================================
; Network Extension Runtime Helpers
; ==============================================================================

@stacks_network_write
    ; Called by parser-generated stubs for STACKS 'CONNECTION WRITE'.
    ; STACKS language construct: ident CONNECTION WRITE dst-addr serviceID
    ; The calling stub (from parseV2.py) will have set up registers as follows:
    ;   - Register A: dst-addr (destination NIC ID)
    ;   - Register B: Value to send (popped from STACKS stack)
    ;   - Loaded serviceID into Register C.
    ; This routine then calls the low-level @send_data_packet_sub.

    ; @send_data_packet_sub (from networkdispatcher.asm) expects:
    ;   A: dst_addr
    ;   B: data_to_send
    ;   C: service_id_out
    ;
    ; Registers A, B, and C are already in the correct order as expected

    ; from networkdispatcher.asm
    call @send_data_packet_sub 
ret

# a simple name, for better use in the Stacks language
@readService0
    ; Helper routine for STACKS 'CONNECTION READ'.
    ; STACKS language construct: ident CONNECTION READ @user_service_routine
    ; This helper is intended to be called by the @user_service_routine.
    ; It reads from the network service 0 buffer using @read_service0_data.
    ; It then pushes two items onto the STACKS stack:
    ;   1. The value read (or a dummy value like 0 if no data).
    ;   2. A status code: 0 for success, 1 for failure (no data).

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
    ; ldi A 0         ; Push 0 as a dummy value for the data part
    ; call @push_A    ; Assumes @push_A is a STACKS runtime routine to push Reg A onto STACKS stack
    ; No dummy value neeeded when no data availible, just return status
    ; Push 1 as the status_code (failure/no data)
    ldi A 1         
    call @push_A
    jmp :_srs0bps_done

:_srs0bps_data_read_success
    ; --- Success Case (Data Read) ---
    ; CPU status bit was 1, data from @read_service0_data is in Register A.
    ; Register A already contains the data byte.
    ; Push the actual data byte onto STACKS stack
    call @push_A   
    ; Push 0 as the status_code (success) 
    ldi A 0         
    call @push_A

:_srs0bps_done
ret