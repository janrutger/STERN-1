@read_char
    # returns Current token in A 
    # returns Next token in B 
    # status bit to 1 when A is \Return else 0
    :read_char_loop
        inc I $input_buffer_indx
        ldx A $input_buffer_pntr
        addi I 1
        ldx B $input_buffer_pntr

    ;tst A \space
    ;jmpt :read_char_loop
    tst A \Return
ret