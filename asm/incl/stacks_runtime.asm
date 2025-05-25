# STACKS Runtime library
#
# Implements an "Empty Ascending Stack" using $datastack_pntr and $datastack_index
# from ./incl/math.asm.
# - $datastack_pntr: Base address of the stack memory area.
# - $datastack_index: A memory variable storing the index of the NEXT FREE SLOT.
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


# --- String Heap for RAWIN ---
# Define the total size of the string heap (e.g., 256 bytes).
# Reserve memory for the string heap.
# Initialize the string heap pointer to the start of the string heap.
equ ~STACKS_STRING_HEAP_SIZE 16
. $_stacks_string_heap 16
. $_stacks_string_heap_pntr 1
% $_stacks_string_heap_pntr $_stacks_string_heap

#################################
@stacks_runtime_init
    # when the lib must be initalized
    ldi M $_stacks_string_heap
    sto M $_stacks_string_heap_pntr

ret

#################################
@push_A
    inc I $datastack_index
    stx A $datastack_pntr
ret


@pop_A
    dec I $datastack_index
    ldx A $datastack_pntr
ret

@pop_B
    dec I $datastack_index
    ldx B $datastack_pntr
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

#################################
@print
    call @pop_A
    call @print_to_BCD
    call @print_nl

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



@input
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
# Implements the RAWIN functionality for STACKS.
# 1. Prompts the user for input.
# 2. Reads a line of raw characters using @stacks_read_input (into $stacks_buffer).
# 3. Copies the string from $stacks_buffer to the string heap ($_stacks_string_heap).
# 4. Null-terminates the string in the heap (with character code 0).
# 5. Pushes a pointer (address) to this string in the heap onto the STACKS data stack.
# 6. If the string heap is full (overflow), it pushes 0 (a null pointer) instead.

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
    tst K 0
    jmpf :_rawin_len_ok
        # Content length is 0, input was empty. Re-prompt.
        call @prompt_stacks_err 
        jmp :_rawin_start_over
    

:_rawin_len_ok
    # Label to acknowledge length calculation is done.

    # --- Check for string heap overflow ---
    # Required space = string length (K) + 1 (for the null terminator).
    ldm A $_stacks_string_heap_pntr
    # A = current heap pointer value (address of next free spot).
    add A K
    # A = address after string content would be copied.
    addi A 1
    # A = address after string content AND null terminator (new heap top).

    ldi M $_stacks_string_heap
    # M = base address of the string heap.
    addi M ~STACKS_STRING_HEAP_SIZE
    # M = end address of the string heap (exclusive, i.e., address of byte *after* the heap).

    tstg A M
    # Is (new heap top) > (heap end address)?
    # If A is greater than M, it's an overflow. tstg sets status if A > M.
    jmpt :_rawin_heap_overflow

    # --- No overflow, proceed with copying the string to the heap ---
    # Register B will store the starting address of the string in the heap.
    # This address will be pushed onto the STACKS stack.
    ldm B $_stacks_string_heap_pntr
    # B = M[$_stacks_string_heap_pntr] (current heap pointer value, start of new string).

    # Use $_input_read_offset as a temporary read offset for $stacks_buffer.
    sto Z $_input_read_offset
    # Initialize read offset for $stacks_buffer to 0 (assuming Z register holds 0).

    # Loop K times to copy characters (K holds the string content length).
:_rawin_copy_loop
    tst K 0
    jmpt :_rawin_copy_chars_done
    # If K (length counter) is 0, all characters have been copied.

    # Read character from $stacks_buffer
    ldm I $_input_read_offset
    # I = M[$_input_read_offset] (current read offset for $stacks_buffer).
    ldx A $stacks_buffer_pntr
    # A = M[M[$stacks_buffer_pntr] + I] (get char from $stacks_buffer).
    inc I $_input_read_offset
    # Advance M[$_input_read_offset] for the next read from $stacks_buffer.

    # Write character A to the current heap location.
    # M[$_stacks_string_heap_pntr] holds the absolute address to write to.
    # For stx A $_stacks_string_heap_pntr, we need I=0 if stx adds I to M[ptr_var].
    ldi I 0
    stx A $_stacks_string_heap_pntr
    # Writes character in A to M[ M[$_stacks_string_heap_pntr] + 0 ].

    # Advance the address stored in $_stacks_string_heap_pntr to the next slot.
    ldm X $_stacks_string_heap_pntr
    # X = current heap address.
    addi X 1
    # X = next heap address.
    sto X $_stacks_string_heap_pntr
    # Update the heap pointer variable M[$_stacks_string_heap_pntr].

    subi K 1
    # Decrement string length counter (K was loaded with content length).
    jmp :_rawin_copy_loop

:_rawin_copy_chars_done
    # Add the null terminator (character code 0) to the end of the string in the heap.
    ldi A 0
    # A = null character.
    ldi I 0
    # Ensure I=0 for stx.
    stx A $_stacks_string_heap_pntr
    # Write null terminator to M[ M[$_stacks_string_heap_pntr] + 0 ].

    # Advance the heap pointer past the null terminator for the next string allocation.
    ldm X $_stacks_string_heap_pntr
    addi X 1
    sto X $_stacks_string_heap_pntr

    # String successfully copied and null-terminated.
    # The starting address of this string in the heap is in register B.
    ld A B
    jmp :_rawin_push_and_exit

:_rawin_heap_overflow
    # String heap is full. Prepare to push 0 (null pointer).
    ldi A 0

:_rawin_push_and_exit
    call @push_A
    # Push either the string pointer (from B, loaded into A) or 0 (for overflow)
    # onto the STACKS data stack.
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

    