# MAIN program
# runs after init

call @init_stern

@program
    
    :endless
        call @cursor
        call @KBD_READ
        tst A \null
        jmpt :no_input
            call @draw_char_on_screen
            tst A \q
            jmpt :done
    :no_input
    jmp :endless

:done 
    int 2
    halt


@cursor
    ldm X $DSP_X_POS
    ldm Y $DSP_Y_POS
    ldi C \_ 
    int 3
ret