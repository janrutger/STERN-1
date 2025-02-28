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