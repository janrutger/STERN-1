# MAIN program
# runs after init

call @init_stern
call @init_kernel

@program
    
    :endless
        call @cursor
        call @get_token
        # Get_token, value in A, token type in B 
        # 0=operator, 1=number, 2=string

        # test token types, 
        # check for a number
        tst B 1
        jmpf :check_for_operator
            call @handle_number_token
            jmp :end_token
        
        :check_for_operator
        # test for Operator Token
        tst B 0
        jmpf :check_for_string
            call @handle_operator_token
            jmp :end_token


        :check_for_string

    :end_token
        ;nop
        tst A \!
        jmpt :done

    jmp :endless

:done 
    int 2
    halt


###############
@handle_number_token
    call @pushDataStack
ret

@handle_operator_token
# supports / * + - ! \Return tokens   

    # check for + operator
    tst A \+
    jmpf :tst_!_operator
        call @popDataStack
        ld M A
        call @popDataStack
        add A M 
        call @pushDataStack
        call @printBCD
        jmp :end_handle_operator

    :tst_!_operator
    tst A \!
    jmpf :tst_next_operator
        jmp :end_handle_operator


    :tst_next_operator
:end_handle_operator
;nop
ret

###############
@printBCD
. $BCDstring 16
. $BCDstring_pntr 1
. $BCDstring_index 1
nop
ldi M $BCDstring
sto M $BCDstring_pntr
ldi M 0
sto M $BCDstring_index

# expects the number value to print in A 
    :get_bcd_string_val
        ldi K 10
        dmod A K

        addi K 20
        inc I $BCDstring_index
        stx K $BCDstring_pntr

        tst A 0
        jmpf :get_bcd_string_val

    # print in reverse order
    :print_values_reverse
        dec I $BCDstring_index
        ldx A $BCDstring_pntr

        call @draw_char_on_screen

        tst I 0
        jmpf :print_values_reverse

ret

###############
@pushDataStack
    inc I $datastack_index
    stx A $datastack_pntr
ret


@popDataStack
    dec I $datastack_index
    ldx A $datastack_pntr
ret