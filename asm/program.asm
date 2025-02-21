call @init_stern

. $input_buffer 64
. $input_buffer_pntr 1
. $input_buffer_indx 1
% $input_buffer_pntr $input_buffer
% $input_buffer_indx 0

. $screen_x 1
. $screen_y 1
% $screen_x 0
% $screen_y 0

@program
    call @get_input_line

    :tokennice_line
        sto Z $input_buffer_indx
        


halt



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
        inc X $screen_x
        ldm X $screen_x
        ldi M 63
        tstg M X 
        jmpt :get_input
        call @fatal_error

    :end_of_input
        # increase Y position, fatal after max line lenght 32-1
        # must scroll 
        ldi A \space
        call @print_char
        inc Y $screen_y
        sto Z $screen_x

        tst Y 31
        jmpf :end
        call @fatal_error
    :end
        call @print_cursor
        # Store termination in buffer
        ldi A \null
        inc I $input_buffer_indx
        stx A $input_buffer_pntr
ret




@print_cursor
    ldi A \_ 
    call @print_char
ret


@print_char
# expexts $screen_x and $screen_y
# char to print in A 

    ldm X $screen_x
    ldm Y $screen_y

    # calc memory position, input_string_index
    ld I Y 
    muli I 64
    add I X

    # print on screen
    stx A $VIDEO_MEM
ret   

@fatal_error
    ldi X 5
    ldi Y 30
    ld I Y 
    muli I 64
    add I X
    ldi A \f
    stx A $VIDEO_MEM
halt
