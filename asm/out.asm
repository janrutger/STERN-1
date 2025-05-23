@main
call @stacks_runtime_init
. $count 1
ldi A 5
call @push_A
call @pop_A
sto A $count
:_0_while_condition
ldm A $count
call @push_A
ldi A 0
call @push_A
call @gt
call @pop_A
tste A Z
jmpf :_0_while_end
ldm A $count
call @push_A
call @print
ldm A $count
call @push_A
ldi A 1
call @push_A
call @minus
call @pop_A
sto A $count
jmp :_0_while_condition
:_0_while_end
call @print
ret
INCLUDE  stacks_runtime
