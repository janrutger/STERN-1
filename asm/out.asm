@main
call @stacks_runtime_init
ldi A 42
call @push_A
call @print
call @stacks_raw_input_string
call @print
call @stacks_raw_input_string
call @print
call @stacks_raw_input_string
call @print
ret
INCLUDE  stacks_runtime
