# MAIN program
# runs after init

call @init_stern

@program
    
    :endless
        call @cursor
        call @get_token
        nop
        tst A \*
        jmpt :done

    jmp :endless

:done 
    int 2
    halt

# returns token value in A 
# returns token type in B 
#   0=operator, 1=number, 2=string
# returns the value of type 0 and 1
# returns a pointer to the string type 2 
@get_token
    :get_input
        call @KBD_READ
        tst A \null
        jmpt :get_input

    # check for string type
    ldi M \9
    tstg A M 
    jmpt :string_type

    # first number char (0) is number 20
    # check for a number, 19 = last operator
    ldi M 19
    tstg A M 
    jmpt :number_type

    # its not a string nor a number
    # jump always to operator type
    jmp :operator_type

    :number_type    
        # first diget
        call @draw_char_on_screen
        subi A 20
        ld B A 
        
        # check for next diget
        :next_diget_loop
            call @KBD_READ
            # check for non numbers
            # if so, ask for new input
            tst A \Return
            jmpt :handle_number_input
            ldi M \space
            tstg A M 
            jmpt :next_diget_loop
            ldi M 19
            tstg A M 
            jmpf :next_diget_loop

            :handle_number_input
                call @draw_char_on_screen

                #check for seperator \space
                tst A \space
                jmpt :end_number_token

                #check for seperator \Return
                tst A \Return
                jmpt :end_number_token

                muli B 10
                subi A 20
                add B A 
                jmp :next_diget_loop

        :end_number_token    
        # return value in A and type in B 
        ld A B 
        ldi B 1

        jmp :get_token_done


    :string_type
        # not yet implemented
        ldi M \z
        tstg A M 
        jmpt :operator_type

        # ignore string input, so startover
        ;jmp :get_token_done
        jmp :get_input


    :operator_type
        # like + = / -  space return

        ld B A
        call @draw_char_on_screen

        tst A \Return
        jmpt :end_operator_token
        tst A \space
        jmpt :end_operator_token

        #next input must be an seperator \space
        :check_for_seperator
            call @KBD_READ
            tst A \space
            jmpt :check_for_seperator_end
            tst A \Return
            jmpt :check_for_seperator_end
            jmp :check_for_seperator

        :check_for_seperator_end
            call @draw_char_on_screen        

        :end_operator_token
        ld A B 
        ldi B 0
        jmp :get_token_done



:get_token_done
ret




@cursor
    ldm X $DSP_X_POS
    ldm Y $DSP_Y_POS
    ldi C \_ 
    int 3
ret

@no_cursor
    ldm X $DSP_X_POS
    ldm Y $DSP_Y_POS
    ldi C \space 
    int 3
ret