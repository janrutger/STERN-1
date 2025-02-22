# Kernel init
@init_kernel
    # datastack operations
    # push / pop A to/from stack
    . $datastack 16
    . $datastack_pntr 1
    . $datastack_index 1
    ldi M $datastack
    sto M $datastack_pntr
    ;ldi M 0
    sto Z $datastack_index

    . $BCDstring 16
    . $BCDstring_pntr 1
    . $BCDstring_index 1
    ldi M $BCDstring
    sto M $BCDstring_pntr


    . $DSP_X_POS 1
    . $DSP_Y_POS 1
    . $DSP_CHAR_WIDTH 1
    . $DSP_LAST_CHAR 1
    . $DSP_CHAR_HEIGHT 1
    . $DSP_LAST_LINE 1
    # init display parameters
    # in total 12 chars on 1 line
    # 5 lines on the display
    ld M Z
    sto M $DSP_X_POS
    sto M $DSP_Y_POS
    ldi M 5
    sto M $DSP_CHAR_WIDTH
    ldi M 6
    sto M $DSP_CHAR_HEIGHT
    ldi M 24
    sto M $DSP_LAST_LINE
    ldi M 55
    sto M $DSP_LAST_CHAR


ret


# Function to get a token from input
# Returns:
#   - Token value in A, is an pointer in case of a string type
#   - Token type in B (0=operator, 1=number, 2=string)
@get_token
    call @toggle_cursor
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
        call @toggle_cursor
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
        . $input_string 16
        . $input_string_pntr 1
        . $input_string_index 1

        ldi M \z
        tstg A M 
        jmpt :operator_type
        tst A \space
        jmpt :operator_type

        # first char
        call @toggle_cursor
        call @draw_char_on_screen

        sto Z $input_string_index
        ldi M $input_string
        sto M $input_string_pntr
        
        inc I $input_string_index
        stx A $input_string_pntr
        :string_input_loop
            call @KBD_READ
            tst A \null
            jmpt :string_input_loop
            tst A \Up
            jmpt :string_input_loop
            tst A \Right
            jmpt :string_input_loop
            tst A \Down
            jmpt :string_input_loop
            tst A \Left
            jmpt :string_input_loop

            tst A \Return
            jmpt :end_string_token
            tst A \space
            jmpt :end_string_token

            inc I $input_string_index
            stx A $input_string_pntr

            call @draw_char_on_screen
            jmp :string_input_loop


        :end_string_token
            # terminate
            call @draw_char_on_screen
            ldi M \null
            inc I $input_string_index
            stx M $input_string_pntr


            ldi A $input_string_pntr
            ldi B 2
         
        jmp :get_token_done



    :operator_type
        # like + = / -  \space \Return 
        # \Up \Right \Down \Left

        ld B A
        call @toggle_cursor

        # Check for value \space, \Return \Up \Right \Down \Left
        tst A \Return
        jmpt :end_operator_token
        tst A \space
        jmpt :end_operator_token
        tst A \Up
        jmpt :end_operator_token
        tst A \Right
        jmpt :end_operator_token
        tst A \Down
        jmpt :end_operator_token
        tst A \Left
        jmpt :end_operator_token

        call @draw_char_on_screen

        #next input must be an seperators \space and \Return
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


## draw on screen calls
@draw_char_on_screen
    # expects new X- and Y- pos in memory
    # gets input value in A 
    tst A \Return
    jmpf :other_char
        ldm Y $DSP_Y_POS
        ldm M $DSP_CHAR_HEIGHT
        add Y M
        sto Y $DSP_Y_POS
        sto Z $DSP_X_POS
        jmp :draw_char_on_screen_check
    :other_char
        # draw the char
        ldm Y $DSP_Y_POS
        ldm X $DSP_X_POS
        ld C A 
        int 3

        # Update X pointer
        ldm M $DSP_CHAR_WIDTH
        add X M 
        sto X $DSP_X_POS


    :draw_char_on_screen_check
    # Check if next char fits on screen
        #check X > widht
        ldm M $DSP_LAST_CHAR
        tstg X M
        jmpf :check_height
            sto Z $DSP_X_POS 
            # Update Y pointer
            ldm M $DSP_CHAR_HEIGHT
            add Y M 
            sto Y $DSP_Y_POS
              
        # check Y > height 
        :check_height
        ldm M $DSP_LAST_LINE
        tstg Y M 
        jmpf :draw_char_on_screen_done
            sto M $DSP_Y_POS
            ;call @scroll_screen
            int 4

:draw_char_on_screen_done
ret


@toggle_cursor
    ldm X $DSP_X_POS
    ldm Y $DSP_Y_POS
    ldi C \_ 
    int 3
ret


###############
@printBCD

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

        call @draw_char_on_screen

        tst I 0
        jmpf :print_values_reverse
    
        ldi A \space
    call @draw_char_on_screen

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
