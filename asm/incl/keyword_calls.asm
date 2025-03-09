@exit_kw
    int 2
    halt
ret

@print_kw
    call @datastack_pop
    call @print_to_BCD
ret


@run_kw
    ;call @print_cls
    ldm I $prog_start
    callx $mem_start 
ret