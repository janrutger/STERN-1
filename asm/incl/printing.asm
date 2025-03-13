. $cursor_x 1
. $cursor_y 1
% $cursor_x 0
% $cursor_y 0

. $BCDstring 16
. $BCDstring_pntr 1
. $BCDstring_index 1
% $BCDstring_pntr $BCDstring


@prompt_system
    ldi A \-
    call @print_char
    inc X $cursor_x
    ldi A \-
    call @print_char
    inc X $cursor_x
    ldi A \>
    call @print_char
    inc X $cursor_x
ret

@prompt_command
    ldi A \space
    call @print_char
    inc X $cursor_x
    ldi A \$
    call @print_char
    inc X $cursor_x
    ldi A \>
    call @print_char
    inc X $cursor_x
ret

@prompt_program
    ldi A \space
    call @print_char
    inc X $cursor_x
    ldi A \space
    call @print_char
    inc X $cursor_x
    ldi A \>
    call @print_char
    inc X $cursor_x
ret


@cursor_on
    ldi A \_ 
    call @print_char
ret

@cursor_off
    ldi A \space
    call @print_char
ret

@print_char
# expexts $cursor_x and $cursor_y
# char to print in A 

    ldm X $cursor_x
    ldm Y $cursor_y

    # calc memory position, input_string_index
    ld I Y 
    muli I 64
    add I X

    # print on screen
    stx A $VIDEO_MEM
ret   

@print_nl
    inc Y $cursor_y
    sto Z $cursor_x

    tst Y 31
    jmpf :end
    sto Z $cursor_y
:end
ret

@print_cls
    sto Z $cursor_y
    sto Z $cursor_x

    int 1
ret


@print_to_BCD
    ldi M 0
    sto M $BCDstring_index

    # expects the number value to print in A 
    # + signed numbers is the default M=1
    # Check is A has - sign, M=0
    # Multiply A * -1, to change sign
    ldi M 1
    tstg A Z
    jmpt :get_bcd_string_val
    ldi M 0
    muli A -1

    :get_bcd_string_val
        ldi K 10
        dmod A K

        addi K 20
        inc I $BCDstring_index
        stx K $BCDstring_pntr

        tst A 0 
        jmpf :get_bcd_string_val
        
        # Check sign M, when negative M=0
        # add sign (-) in front 
        tst M 1
        jmpt :print_values_reverse
        ldi A \-
        inc I $BCDstring_index
        stx A $BCDstring_pntr


    # print in reverse order
    :print_values_reverse
        dec I $BCDstring_index
        ldx A $BCDstring_pntr

        ld M I
        call @print_char
        inc X $cursor_x
        ld I M

        tst I 0
        jmpf :print_values_reverse
    
    ldi A \space
    call @print_char
    inc X $cursor_x

ret
