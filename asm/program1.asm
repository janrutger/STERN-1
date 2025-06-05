@main
call @stacks_runtime_init
. $result 1
ldi A 0
call @push_A
call @stacks_timer_set
; --- String Literal 'starts waiting' pushed to stack ---
ldi A 0
call @push_A
ldi A \g
call @push_A
ldi A \n
call @push_A
ldi A \i
call @push_A
ldi A \t
call @push_A
ldi A \i
call @push_A
ldi A \a
call @push_A
ldi A \w
call @push_A
ldi A \space
call @push_A
ldi A \s
call @push_A
ldi A \t
call @push_A
ldi A \r
call @push_A
ldi A \a
call @push_A
ldi A \t
call @push_A
ldi A \s
call @push_A
; --- End String Literal 'starts waiting' on stack ---
call @stacks_show_from_stack
ldi A 1
call @push_A
call @pop_A
sto A $result
:_1_while_condition
ldm A $result
call @push_A
ldi A 0
call @push_A
call @ne
call @pop_A
tste A Z
jmpf :_1_while_end
call @~rcv
jmp :_1_while_condition
:_1_while_end
ldi A 0
call @push_A
call @stacks_timer_print
ret
INCLUDE  stacks_runtime
@~rcv
:_0_while_condition
call @readService0
ldi A 1
call @push_A
call @eq
call @pop_A
tste A Z
jmpf :_0_while_end
jmp :_0_while_condition
:_0_while_end
call @dup
call @pop_A
sto A $result
call @plot
ret
