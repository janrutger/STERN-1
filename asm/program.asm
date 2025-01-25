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
# supports / * + - ! ?  tokens   

    # check for + operator
    tst A \+
    jmpf :tst_!_operator
        call @popDataStack
        ld M A
        call @popDataStack
        add A M 
        call @pushDataStack
        jmp :end_handle_operator

    :tst_!_operator
    tst A \!
    jmpf :tst_dot_operator
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
    jmpf :tst_next_operator
        ldm A $datastack_index
        call @printBCD
        jmp :end_handle_operator



    :tst_next_operator
:end_handle_operator
;nop
ret




###### helpers ######
