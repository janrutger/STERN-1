@parse_tokens
    sto Z $token_buffer_indx
    :loop_parse_tokens
        call @read_token
        jmpt :end_of_tokens

        # Parse and execute tokens here 
        call @execute_token
        jmp :loop_parse_tokens

    :end_of_tokens
        ldm M $cursor_x
        tste Z M 
        jmpt :no_newline
            call @cursor_off
            call @print_nl
    :no_newline
ret

@read_token
    # returns token type  in B 
    # returns token value in A  
    # \null is end of token_buffer
    # returns true when last token is read
    # token types \0=mumber, \1=operator, \2=string

    # load token type in B
    inc I $token_buffer_indx
    ldx B $token_buffer_pntr

    # test for last token
    tst B \null
    jmpt :end_read_token

    # test for String type token
    # if not a string type,
    # handle as number and operator type
    tst B \2
    jmpt :read_string_token
        # load token value in A
        inc I $token_buffer_indx
        ldx A $token_buffer_pntr
    jmp :end_read_token

    # handle string type token
    :read_string_token
        sto Z $token_last_string_value_indx
        ldi A $token_last_string_value

        :read_string_token_loop
            inc I $token_buffer_indx
            ldx M $token_buffer_pntr

            inc I $token_last_string_value_indx
            stx M $token_last_string_value_pntr
       
            tst M \null
        jmpt :end_read_token
        jmp :read_string_token_loop

    # make sure the exit status is correct
    :end_read_token
    tst B \null
ret



@execute_token
    # check if token is a number
    :check_for_number_token
        tst B \0
        jmpf :check_for_operator_token
            # handle number token
            call @datastack_push 
        ret


    # check if token is a operator
    :check_for_operator_token
        tst B \1
        jmpf :check_for_string_token
            # handle operator token 
            ld I A 
            callx $mem_start
        ret
    
    # check if token is a string
    :check_for_string_token
        tst B \2
        jmpf :no_valid_token
            # handele string token
        ret

    :no_valid_token
        call @fatal_error
ret