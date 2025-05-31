@main
    
    # init data
    ldi B 20


    :send_for_echo
        # dst
        ldi A 1
        # Service ID
        ldi C 1
        

        int ~networkSend

        
        :echo_loop
            call @read_service0_data
            jmpf :echo_loop

        call @print_char
        call @print_nl

        addi B 1
        tst B \z
        jmpt :end_echo
    jmp :send_for_echo



:end_echo
ret