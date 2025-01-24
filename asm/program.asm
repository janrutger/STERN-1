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

