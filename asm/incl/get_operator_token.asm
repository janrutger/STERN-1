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
            jmpf :tst_mul
            ldi A @do_substraction
            jmp :store_operator_token

        :tst_mul
            tst A \*
            jmpf :tst_div
            ldi A @do_multiplication
            jmp :store_operator_token

        :tst_div
            tst A \/
            jmpf :tst_gt
            ldi A @do_division
            jmp :store_operator_token

        :tst_gt
            tst A \>
            jmpf :tst_dot
            ldi A @do_gt
            jmp :store_operator_token
            
        :tst_dot
            tst A \.
            jmpf :tst_bang
            ldi A @do_dot
            jmp :store_operator_token

        :tst_bang
            tst A \!
            jmpf :last_token_check
            ldi A @do_bang
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