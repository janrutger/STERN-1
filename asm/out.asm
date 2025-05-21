@main
INCLUDE  stacks_runtime
call @stacks_runtime_init
ldi A 10
call @push_A
ldi A 12
call @push_A
ldi A 12
call @push_A
call @plus
call @minus
ret
