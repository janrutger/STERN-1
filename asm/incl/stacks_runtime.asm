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



#################################
@stacks_runtime_init
    # when the lib must be initalized
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
    jmpf :ne_false
        ldi A 1
        call @push_A
    jmp :ne_end
    :ne_false
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
#################################
. $stacks_buffer 16
. $stacks_buffer_pntr 1
. $stacks_buffer_indx 1
% $stacks_buffer_pntr $stacks_buffer
% $stacks_buffer_indx 0

 
equ ~STACKS_BUFFER_MAX_DATA 15

@stacks_read_input
    :redo_at_fatal_processing
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
            dec X $cursor_x 

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
        
        ldi A \Return
        inc I $stacks_buffer_indx
        stx A $stacks_buffer_pntr



    :proces_input    
        sto Z $stacks_buffer_indx

        inc I $stacks_buffer_index
        ldx A $stacks_buffer_pntr

        tst A \-
        jmpt :its_a_number

        tst A \+
        jmpt :its_a_number

        ldi M \z
        tstg A M 
        jmpt :do_controls

        ldi M \9
        tstg A M 
        jmpt :do_chars

        ldi M \:
        tstg A M 
        jmpt :do_number

        ldi M \null
        tstg A M 
        jmpt :do_specials










ret
