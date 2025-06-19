    @get_string_token
    # expects first char in A 
    # returns tokentype and value in token_buffer
    # statusbit is 1 when \Return (end of line)

        # K = token type \0=mumber, \1=operator, \2=string
        ldi K \2

        # K = token type
        inc I $token_buffer_indx
        stx K $token_buffer_pntr

        :loop_string_token

            # A = value
            inc I $token_buffer_indx
            stx A $token_buffer_pntr

            call @read_char
            jmpt :end_of_string_token
            tst A \space
            jmpt :end_of_string_token

            # First char of string [a..z]
            # Seceond and more can be any printeble char
            ;call @is_char
            ;jmpt :loop_string_token
            ;call @fatal_error
            jmp :loop_string_token



        :end_of_string_token
            tst A \Return
            ldi A \null 
            inc I $token_buffer_indx
            stx A $token_buffer_pntr
    ret      
   