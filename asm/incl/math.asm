@do_addition
    call @datastack_pop
    ld B A 
    call @datastack_pop
    add A B 
    call @datastack_push 
ret

@do_substraction
    call @datastack_pop
    ld B A 
    call @datastack_pop
    sub A B 
    call @datastack_push 
ret

@do_multiplication
    call @datastack_pop
    ld B A 
    call @datastack_pop
    mul A B 
    call @datastack_push 
ret

@do_division
    call @datastack_pop
    ld B A 
    call @datastack_pop
    div A B 
    call @datastack_push 
ret



@do_dot
    call @datastack_pop
    call @print_to_BCD
ret

@do_bang
    int 2
    halt
ret

@datastack_push
    inc I $datastack_index
    stx A $datastack_pntr
ret


@datastack_pop
    dec I $datastack_index
    ldx A $datastack_pntr
ret



