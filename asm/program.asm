call @init_stern

. $input_buffer 64
. $input_buffer_pntr 1
. $input_buffer_indx 1
% $input_buffer_pntr $input_buffer
% $input_buffer_indx 0

. $cursor_x 1
. $cursor_y 1
% $cursor_x 0
% $cursor_y 0

@program
    call @get_input_line
    call @tokennice_line
    ;call @execute_tokens

    ldi A 4
    call @INT_to_BCD

    nop
halt


@INT_to_BCD


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
;nop
        call @print_char

        tst I 0
        jmpf :print_values_reverse
    
        ldi A \space
    call @print_char

ret

    



@do_addition
ret

@do_substraction
ret

@do_dot
ret

@do_bang
ret


## INCLUDE helpers

INCLUDE read_char
INCLUDE get_input_line
INCLUDE tokennice_line
INCLUDE check_char_type
INCLUDE get_number_token
INCLUDE get_operator_token
INCLUDE printing
INCLUDE errors



