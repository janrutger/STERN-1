@get_input_line 
    :get_input
        call @print_cursor
        call @KBD_READ
        tst A \null
        jmpt :get_input

        # check for Return as line terminator
        tst A \Return
        jmpt :end_of_input

        # check if A is printeble, ignore arrow-keys
        ldi M \z 
        tstg A M 
        jmpt :get_input

        # Store A in buffer
        inc I $input_buffer_indx
        stx A $input_buffer_pntr

        call @print_char

        # increase X position, fatal after max line lenght 64-1
        inc X $cursor_x
        ldm X $cursor_x
        ldi M 63
        tstg M X 
        jmpt :get_input
        call @fatal_error

    :end_of_input
        # increase Y position, fatal after max line lenght 32-1
        # must scroll 
        ldi A \space
        call @print_char
        inc Y $cursor_y
        sto Z $cursor_x

        tst Y 31
        jmpf :end
        call @fatal_error
    :end
        call @print_cursor
        # Store termination in buffer
        ldi A \Return
        inc I $input_buffer_indx
        stx A $input_buffer_pntr
ret

