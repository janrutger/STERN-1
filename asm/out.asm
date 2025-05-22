@main
call @stacks_runtime_init
. $test 1
:start
ldi A 30
call @push_A
ldi A 12
call @push_A
call @plus
call @pop_A
sto A $test
ldm A $test
call @push_A
call @print
jmp :start
ret
INCLUDE  stacks_runtime
