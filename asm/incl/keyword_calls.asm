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

@stacks_kw  
    ldi I @stacks
    callx $mem_start
ret

@begin_kw
    # stub
ret

@end_kw
    # stub
ret