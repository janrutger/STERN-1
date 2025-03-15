@parse_tokens
    ;sto Z $token_buffer_indx
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




# helpers

. $token_last_string_value 16
. $token_last_string_value_pntr 1
. $token_last_string_value_indx 1
. $token_last_string_value_hash 1
% $token_last_string_value_pntr $token_last_string_value
% $token_last_string_value_indx 0

@read_token
    # returns token type  in B 
    # returns token value in A  
    # returns token hash  in C when type = stringtype
    # \null is end of token_buffer
    # returns true when last token is read
    # token types \0=mumber, \1=operator, \2=string

    # reset hash
    sto Z $token_last_string_value_hash

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
        ;ldi A $token_last_string_value

        :read_string_token_loop
            inc I $token_buffer_indx
            ldx M $token_buffer_pntr

            # store value
            inc I $token_last_string_value_indx
            stx M $token_last_string_value_pntr
       
            # check for end of stringtoken \null
            tst M \null
            jmpt :check_for_keyword

            # calc the  hash of the value
            ldm K $token_last_string_value_hash
            muli K 7
            add K M 
            sto K $token_last_string_value_hash

        jmp :read_string_token_loop

        :check_for_keyword
            call @find_keyword
            # returns string type, when keyword not found
            jmpf :end_read_token
            # else returns index of found keyword in A 

            # token types   \0=mumber, \1=operator, \2=string
            #               \3=keyword
            ldi B \3
        jmp :end_read_token

    
    :end_read_token
    # return hash in C
    # make sure the exit status is correct

    ldm C $token_last_string_value_hash 
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
        jmpf :check_for_keyword_token
            # handele string token
            call @read_var
        ret

    # check if token is a keyword
    :check_for_keyword_token
        tst B \3
        jmpf :no_valid_token
            # handele string token
            ld I A 
            ldx A $keyword_call_dict_pntr
            ld I A 
            callx $mem_start
        ret

    :no_valid_token
        call @fatal_error
ret