@main
call @stacks_runtime_init
ldi A 31
call @push_A
ldi A 30
call @push_A
call @lt
call @pop_A
tste A Z
jmpf :_0_do_end
ldi A 42
call @push_A
call @print
:_0_do_end
ret
INCLUDE  stacks_runtime
