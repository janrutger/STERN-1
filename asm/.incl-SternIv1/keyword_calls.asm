@exit_kw
    int 2
    halt
ret

@print_kw
    call @datastack_pop
    call @print_to_BCD
ret


@main_kw
    ;call @print_cls
    ldm I $prog_start
    callx $mem_start 
ret


@as_kw
    # expects next token is a string
    call @read_token
    jmpt :as_kw_error
    tst B \2
    jmpf :as_kw_error

    call @write_var
    jmp :as_kw_end

:as_kw_error
    call @fatal_error

:as_kw_end    
ret

@open_kw
    # expect next token is a string (filename)
    call @read_token
    jmpt :open_kw_error
    tst B \2
    jmpf :open_kw_error

    ld A C
    int 6
    jmp :open_kw_end
    
:open_kw_error
    call @fatal_error
    
:open_kw_end
ret

@enable_kw
    call @datastack_pop
    call @open_channel
ret

@disable_kw
    call @datastack_pop
    call @close_channel
ret

@plot_kw
    call @datastack_pop
    ld B A 
    ldi A 0
    call @write_channel
ret

@point_kw
    ; set open_channel (1) > A
    ; set X value, from datastack > B
    call @datastack_pop
    ld B A 
    ldi A 1
    call @write_channel
    ; set Y value
    call @datastack_pop
    ld B A 
    ldi A 1
    call @write_channel
ret

@gcd_kw
    call @datastack_pop
    ld B A
    call @datastack_pop

    tst B 0
    jmpt :gcd_kw_returnA

    tst A 0
    jmpt :returnB

    :loop_gcd
        tste A B 
        jmpt :gcd_kw_returnA

        tstg A B 
        jmpt :subAB
            sub B A
            jmp :loop_gcd

        :subAB
            sub A B 
            jmp :loop_gcd

    :returnB
        ld A B
    :gcd_kw_returnA
        call @datastack_push
ret

@now_kw
    ldm A $CURRENT_TIME
    addi A 5
    divi A 10
    call @datastack_push
ret

@rand_kw
    call @random
    call @datastack_push
ret



@stub
    # stub
ret


