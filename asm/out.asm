@main
call @stacks_runtime_init
. $a 1
ldi A 0
call @push_A
call @stacks_timer_set
ldi A 1
call @push_A
call @pop_A
sto A $a
:_0_while_condition
ldi A 100
call @push_A
ldm A $a
call @push_A
call @gt
call @pop_A
tste A Z
jmpf :_0_while_end
call @~test
ldm A $a
call @push_A
ldi A 95
call @push_A
call @gt
call @pop_A
tste A Z
jmpf :_1_goto_end
jmp :klaar
:_1_goto_end
jmp :_0_while_condition
:_0_while_end
:klaar
; --- String Literal 'klaar ' pushed to stack ---
ldi A 0
call @push_A
ldi A \space
call @push_A
ldi A \r
call @push_A
ldi A \a
call @push_A
ldi A \a
call @push_A
ldi A \l
call @push_A
ldi A \k
call @push_A
; --- End String Literal 'klaar ' on stack ---
call @stacks_show_from_stack
ldi A 0
call @push_A
call @stacks_timer_print
ret
INCLUDE  stacks_runtime
@~test
; --- String Literal 'test ' pushed to stack ---
ldi A 0
call @push_A
ldi A \space
call @push_A
ldi A \t
call @push_A
ldi A \s
call @push_A
ldi A \e
call @push_A
ldi A \t
call @push_A
; --- End String Literal 'test ' on stack ---
call @stacks_show_from_stack
ldm A $a
call @push_A
ldi A 1
call @push_A
call @plus
call @pop_A
sto A $a
ldi A 0
call @push_A
call @stacks_timer_get
call @print
ret
