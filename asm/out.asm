@main
call @stacks_runtime_init
. $a 1
. $b 1
call @input
call @pop_A
sto A $a
call @input
call @pop_A
sto A $b
ldm A $a
call @push_A
ldm A $b
call @push_A
call @plus
call @print
ret
INCLUDE  stacks_runtime
