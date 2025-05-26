@main
call @stacks_runtime_init
call @stacks_raw_input_string
call @stacks_show_string
ldi A 42
call @push_A
call @print
ret
INCLUDE  stacks_runtime
