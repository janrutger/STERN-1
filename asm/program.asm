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
            jmpt :end_tokens
            jmp :tokennice
            
        :check_operator
        call @is_operator
        jmpf :check_string
            call @get_operator_token
            jmpt :end_tokens
            jmp :tokennice

        :check_string

    jmp :tokennice

    :end_tokens
        inc I $token_buffer_indx
        stx Z $token_buffer_pntr
        inc I $token_buffer_indx
        stx Z $token_buffer_pntr
ret
    

@get_operator_token
    # expects first [part /,*,+,-, !, ...]  operator in A 
    # expects second [part !=, >=, ...]
    # returns tokentype and value in token_buffer
    # statusbit is 1 when \Return (end of line)

    tst B \space
    jmpt :operator_token
    tst B \Return
    jmpt :operator_token

    call @fatal_error
    :operator_token
        # K = token type \0=mumber, \1=operator, \2=string
        ldi K \1

        tst A \+
        jmpf :tst_min
        ldi A @do_addition
        jmp :store_operator_token

        :tst_min
        tst A \-
        jmpf :last_token_check
        ldi A @do_substraction
        jmp :store_operator_token

        :last_token_check
            # K = token type \0=mumber, \1=operator, \2=string
            ldi K \2

    :store_operator_token
        # K = token type \0=mumber, \1=operator, \2=string
        inc I $token_buffer_indx
        stx K $token_buffer_pntr

        # A = value
        inc I $token_buffer_indx
        stx A $token_buffer_pntr

        # terminate string type
        tst K \2
        jmpf :end_operator_token
            ldi A \null 
            inc I $token_buffer_indx
            stx A $token_buffer_pntr
        
        :end_operator_token
            call @read_char
            tst A \Return
ret

@do_addition
ret

@do_substraction
ret


## INCLUDE helpers

INCLUDE read_char
INCLUDE get_input_line
INCLUDE get_number_token
INCLUDE check_char_type
INCLUDE errors
INCLUDE printing


