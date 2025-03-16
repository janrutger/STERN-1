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



@stub
    # stub
ret


