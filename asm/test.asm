@main
call @stacks_runtime_init
; --- String Literal 'printen en slapen' pushed to stack ---
ldi A 0
call @push_A
ldi A \n
call @push_A
ldi A \e
call @push_A
ldi A \p
call @push_A
ldi A \a
call @push_A
ldi A \l
call @push_A
ldi A \s
call @push_A
ldi A \space
call @push_A
ldi A \n
call @push_A
ldi A \e
call @push_A
ldi A \space
call @push_A
ldi A \n
call @push_A
ldi A \e
call @push_A
ldi A \t
call @push_A
ldi A \n
call @push_A
ldi A \i
call @push_A
ldi A \r
call @push_A
ldi A \p
call @push_A
; --- End String Literal 'printen en slapen' on stack ---
call @stacks_show_from_stack
ldi A 5
call @push_A
call @stacks_sleep
; --- String Literal 'printen..' pushed to stack ---
ldi A 0
call @push_A
ldi A \.
call @push_A
ldi A \.
call @push_A
ldi A \n
call @push_A
ldi A \e
call @push_A
ldi A \t
call @push_A
ldi A \n
call @push_A
ldi A \i
call @push_A
ldi A \r
call @push_A
ldi A \p
call @push_A
; --- End String Literal 'printen..' on stack ---
call @stacks_show_from_stack
ldi A 0
call @push_A
call @print
ldi A 10
call @push_A
ldi A 42
call @push_A
call @mod
call @print
ldi A 42
call @push_A
ldi A 10
call @push_A
call @mod
call @print
ret
INCLUDE  stacks_runtime
