@read_char
    # returns Current token in A 
    # returns Next token in B 
    # status bit is one when A is \Return
    :read_char_loop
        inc I $input_buffer_indx
        ldx A $input_buffer_pntr
        addi I 1
        ldx B $input_buffer_pntr

    tst A \space
    jmpt :read_char_loop
    tst A \Return
ret