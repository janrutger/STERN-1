call @init_stern

. $input_buffer 64
. $input_buffer_pntr 1
. $input_buffer_indx 1
% $input_buffer_pntr $input_buffer
% $input_buffer_indx 0

. $cursor_x 1
. $cursor_y 1
% $cursor_x 0
% $cursor_y 0

@program
    call @get_input_line

    call @tokennice_line
    nop
halt


@tokennice_line
    . $token_buffer 64
    . $token_buffer_pntr 1
    . $token_buffer_indx 1
    % $token_buffer_pntr $token_buffer
    % $token_buffer_indx 0

    sto Z $input_buffer_indx  

    :tokennice
        call @read_char
        jmpt :end_tokens
        tst A \space
        jmpt :tokennice

        call @is_digit
        jmpf :check_neg
            ldi C 1
            call @get_number_token
            jmpf :tokennice
            jmp :end_tokens

        :check_neg
        call @is_neg
        jmpf :check_operator
            ldi C -1
            call @read_char
            call @get_number_token
            jmpf :tokennice
            jmp :end_tokens
            
        :check_operator

    jmp :tokennice


    :end_tokens
        inc I $token_buffer_indx
        stx Z $token_buffer_pntr
        inc I $token_buffer_indx
        stx Z $token_buffer_pntr
ret
    

@get_number_token
    # expects first digit in A 
    # expects sign in C
    # returns tokentype and value in token_buffer
    # statusbit is 1 when \Return (end of line)

    # First digit
    ld L A
    subi L 20

    # Next digit
    :next_digit_token_loop
        call @read_char
        jmpt :end_of_number_token
        tst A \space
        jmpt :end_of_number_token

        call @is_digit
        jmpt :proces_digit
        call @fatal_error

        :proces_digit
            muli L 10
            subi A 20
            add L A
    jmp :next_digit_token_loop

    :end_of_number_token
    ldi K 0
    inc I $token_buffer_indx
    stx K $token_buffer_pntr

    mul L C
    inc I $token_buffer_indx
    stx L $token_buffer_pntr

    tst A \Return
ret

## INCLUDE helpers

INCLUDE read_char
INCLUDE get_input_line
INCLUDE check_char_type
INCLUDE errors
INCLUDE printing


