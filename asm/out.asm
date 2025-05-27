@main
call @stacks_runtime_init
; --- String Literal 'a' pushed to stack ---
ldi A 0
call @push_A
ldi A \a
call @push_A
; --- End String Literal 'a' on stack ---
call @stacks_hash_from_stack
call @print
; --- String Literal 'ab' pushed to stack ---
ldi A 0
call @push_A
ldi A \b
call @push_A
ldi A \a
call @push_A
; --- End String Literal 'ab' on stack ---
call @stacks_hash_from_stack
call @print
call @stacks_raw_input_string
call @stacks_hash_from_stack
call @print
; --- String Literal 'xyz' pushed to stack ---
ldi A 0
call @push_A
ldi A \z
call @push_A
ldi A \y
call @push_A
ldi A \x
call @push_A
; --- End String Literal 'xyz' on stack ---
ret
INCLUDE  stacks_runtime
