call @init_stern

. $mem_start 1
% $mem_start 0

. $input_buffer 64
. $input_buffer_pntr 1
. $input_buffer_indx 1
% $input_buffer_pntr $input_buffer
% $input_buffer_indx 0

. $cursor_x 1
. $cursor_y 1
% $cursor_x 0
% $cursor_y 0

. $BCDstring 16
. $BCDstring_pntr 1
. $BCDstring_index 1
% $BCDstring_pntr $BCDstring

. $datastack 16
. $datastack_pntr 1
. $datastack_index 1
% $datastack_pntr $datastack
% $datastack_index 0

@program
    call @get_input_line
    call @tokennice_line
    call @execute_tokens
    jmp @program
halt


@execute_tokens
    sto Z $token_buffer_indx
    :loop_execute_tokens
        # load token type  in B 
        # load token value in A  
        # \null is end of token_buffer
        # token types \0=mumber, \1=operator, \2=string

        # load token type B
        inc I $token_buffer_indx
        ldx B $token_buffer_pntr

        # load token value A
        inc I $token_buffer_indx
        ldx A $token_buffer_pntr

        tst B \null
        jmpt :execution_done

        # check if token is a number
        tst B \0
        jmpf :check_for_operator_token
            # handle number token
            call @datastack_push 
        jmp :loop_execute_tokens


        # check if token is a operator
        :check_for_operator_token
        tst B \1
        jmpf :no_valid_token
            # handle operator token 
            ld I A 
            callx $mem_start
        jmp :loop_execute_tokens

    :no_valid_token
        call @fatal_error
    jmp :loop_execute_tokens


:execution_done
    tst Z $cursor_x
    jmpt :execute_tokens_done
        call @cursor_off
        call @print_nl
    :execute_tokens_done
ret



## INCLUDE helpers


INCLUDE read_char
INCLUDE get_input_line
INCLUDE tokennice_line
INCLUDE check_char_type
INCLUDE get_number_token
INCLUDE get_operator_token
INCLUDE printing
INCLUDE math
INCLUDE errors



