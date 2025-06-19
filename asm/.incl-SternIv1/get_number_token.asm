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
    # K = token type \0=mumber, \1=operator, \2=string
    ldi K \0
    inc I $token_buffer_indx
    stx K $token_buffer_pntr

    mul L C
    inc I $token_buffer_indx
    stx L $token_buffer_pntr

    tst A \Return
ret