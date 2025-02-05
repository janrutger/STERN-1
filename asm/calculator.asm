# MAIN program
# runs after init

call @init_stern
call @init_kernel


@program
    
    :endless
        call @get_token
        # Get_token, value in A, token type in B 
        # 0=operator, 1=number, 2=string

        # test token types, 
        # first, check for a number
        tst B 1
        jmpf :check_for_operator
            call @handle_number_token
            jmp :end_token
        
        :check_for_operator
        # test for Operator Token
        tst B 0
        jmpf :check_for_string
            call @handle_operator_token
            jmp :check_for_done


        :check_for_string

    :check_for_done
        tst A \null
        jmpt :done

    :end_token
    jmp :endless

:done 
    int 2
    halt


###############
@handle_number_token
    call @pushDataStack
ret

@handle_operator_token
# supports (/ * + - ! ? \Return)  tokens   

    # check for + operator

    :tst_add_operation
    tst A \+
    jmpf :tst_mull_operator
        call @popDataStack
        ld M A
        call @popDataStack
        add A M 
        call @pushDataStack
        jmp :end_handle_operator

    :tst_mull_operator
    tst A \*
    jmpf :tst_minus_operator
        call @popDataStack
        ld M A
        call @popDataStack
        mul A M 
        call @pushDataStack
        jmp :end_handle_operator

    :tst_minus_operator
    tst A \-
    jmpf :tst_div_operator
        call @popDataStack
        ld M A
        call @popDataStack
        sub A M 
        call @pushDataStack
        jmp :end_handle_operator

    :tst_div_operator
    tst A \/
    jmpf :tst_!_operator
        call @popDataStack
        ld M A
        call @popDataStack
        div A M 
        call @pushDataStack
        jmp :end_handle_operator

    :tst_!_operator
    tst A \!
    jmpf :tst_dot_operator
        ldi A \null
        jmp :end_handle_operator

    :tst_dot_operator
    tst A \.
    jmpf :tst_?_operator
        call @popDataStack
        call @pushDataStack
        call @printBCD
        jmp :end_handle_operator

    :tst_?_operator
    tst A \?
    jmpf :tst_Return_operator
        ldm A $datastack_index
        call @printBCD
        jmp :end_handle_operator

    :tst_Return_operator
    tst A \Return
    jmpf :tst_next_operator
        ldi A \Return
        call @draw_char_on_screen
        jmp :end_handle_operator
    

    :tst_next_operator
:end_handle_operator
;nop
ret




###### helpers ######
