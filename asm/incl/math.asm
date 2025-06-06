. $datastack 64
. $datastack_pntr 1
. $datastack_index 1
% $datastack_pntr $datastack
% $datastack_index 0


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

@do_gt
    call @datastack_pop
    ld B A 
    call @datastack_pop
    tstg A B 
    jmpf :gt_false
        ldi A 0
    jmp :gt_end
    :gt_false
        ldi A 1
    :gt_end
        call @datastack_push 
ret


@do_eq
    call @datastack_pop
    ld B A 
    call @datastack_pop
    tste A B 
    jmpf :eq_false
        ldi A 0
    jmp :eq_end
    :eq_false
        ldi A 1
    :eq_end
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



