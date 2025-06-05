@main
call @stacks_runtime_init
. $arr1 12
% $arr1 0 12
; --- String Literal '--- array test suite start ---' pushed to stack ---
ldi A 0
call @push_A
ldi A \-
call @push_A
ldi A \-
call @push_A
ldi A \-
call @push_A
ldi A \space
call @push_A
ldi A \t
call @push_A
ldi A \r
call @push_A
ldi A \a
call @push_A
ldi A \t
call @push_A
ldi A \s
call @push_A
ldi A \space
call @push_A
ldi A \e
call @push_A
ldi A \t
call @push_A
ldi A \i
call @push_A
ldi A \u
call @push_A
ldi A \s
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
ldi A \space
call @push_A
ldi A \y
call @push_A
ldi A \a
call @push_A
ldi A \r
call @push_A
ldi A \r
call @push_A
ldi A \a
call @push_A
ldi A \space
call @push_A
ldi A \-
call @push_A
ldi A \-
call @push_A
ldi A \-
call @push_A
; --- End String Literal '--- array test suite start ---' on stack ---
call @stacks_show_from_stack
ldi A 0
call @push_A
call @print
; --- String Literal 'initial length of arr1 (expected: 0): ' pushed to stack ---
ldi A 0
call @push_A
ldi A \space
call @push_A
ldi A \:
call @push_A
ldi A \)
call @push_A
ldi A \0
call @push_A
ldi A \space
call @push_A
ldi A \:
call @push_A
ldi A \d
call @push_A
ldi A \e
call @push_A
ldi A \t
call @push_A
ldi A \c
call @push_A
ldi A \e
call @push_A
ldi A \p
call @push_A
ldi A \x
call @push_A
ldi A \e
call @push_A
ldi A \(
call @push_A
ldi A \space
call @push_A
ldi A \1
call @push_A
ldi A \r
call @push_A
ldi A \r
call @push_A
ldi A \a
call @push_A
ldi A \space
call @push_A
ldi A \f
call @push_A
ldi A \o
call @push_A
ldi A \space
call @push_A
ldi A \h
call @push_A
ldi A \t
call @push_A
ldi A \g
call @push_A
ldi A \n
call @push_A
ldi A \e
call @push_A
ldi A \l
call @push_A
ldi A \space
call @push_A
ldi A \l
call @push_A
ldi A \a
call @push_A
ldi A \i
call @push_A
ldi A \t
call @push_A
ldi A \i
call @push_A
ldi A \n
call @push_A
ldi A \i
call @push_A
; --- End String Literal 'initial length of arr1 (expected: 0): ' on stack ---
call @stacks_show_from_stack
ldi A $arr1
call @push_A
call @stacks_array_length
call @print
; --- String Literal 'write 3 values to array' pushed to stack ---
ldi A 0
call @push_A
ldi A \y
call @push_A
ldi A \a
call @push_A
ldi A \r
call @push_A
ldi A \r
call @push_A
ldi A \a
call @push_A
ldi A \space
call @push_A
ldi A \o
call @push_A
ldi A \t
call @push_A
ldi A \space
call @push_A
ldi A \s
call @push_A
ldi A \e
call @push_A
ldi A \u
call @push_A
ldi A \l
call @push_A
ldi A \a
call @push_A
ldi A \v
call @push_A
ldi A \space
call @push_A
ldi A \3
call @push_A
ldi A \space
call @push_A
ldi A \e
call @push_A
ldi A \t
call @push_A
ldi A \i
call @push_A
ldi A \r
call @push_A
ldi A \w
call @push_A
; --- End String Literal 'write 3 values to array' on stack ---
call @stacks_show_from_stack
ldi A 1
call @push_A
call @print
ldi A 1
call @push_A
ldi A $arr1
call @push_A
call @stacks_array_append
ldi A 2
call @push_A
ldi A $arr1
call @push_A
call @stacks_array_append
ldi A 3
call @push_A
ldi A $arr1
call @push_A
call @stacks_array_append
; --- String Literal 'length of arr1 (expected: 3): ' pushed to stack ---
ldi A 0
call @push_A
ldi A \space
call @push_A
ldi A \:
call @push_A
ldi A \)
call @push_A
ldi A \3
call @push_A
ldi A \space
call @push_A
ldi A \:
call @push_A
ldi A \d
call @push_A
ldi A \e
call @push_A
ldi A \t
call @push_A
ldi A \c
call @push_A
ldi A \e
call @push_A
ldi A \p
call @push_A
ldi A \x
call @push_A
ldi A \e
call @push_A
ldi A \(
call @push_A
ldi A \space
call @push_A
ldi A \1
call @push_A
ldi A \r
call @push_A
ldi A \r
call @push_A
ldi A \a
call @push_A
ldi A \space
call @push_A
ldi A \f
call @push_A
ldi A \o
call @push_A
ldi A \space
call @push_A
ldi A \h
call @push_A
ldi A \t
call @push_A
ldi A \g
call @push_A
ldi A \n
call @push_A
ldi A \e
call @push_A
ldi A \l
call @push_A
; --- End String Literal 'length of arr1 (expected: 3): ' on stack ---
call @stacks_show_from_stack
ldi A $arr1
call @push_A
call @stacks_array_length
call @print
; --- String Literal 'read index 2 ' pushed to stack ---
ldi A 0
call @push_A
ldi A \space
call @push_A
ldi A \2
call @push_A
ldi A \space
call @push_A
ldi A \x
call @push_A
ldi A \e
call @push_A
ldi A \d
call @push_A
ldi A \n
call @push_A
ldi A \i
call @push_A
ldi A \space
call @push_A
ldi A \d
call @push_A
ldi A \a
call @push_A
ldi A \e
call @push_A
ldi A \r
call @push_A
; --- End String Literal 'read index 2 ' on stack ---
call @stacks_show_from_stack
ldi A 11
call @push_A
call @print
; --- String Literal 'value of index 2 (expected: 3): ' pushed to stack ---
ldi A 0
call @push_A
ldi A \space
call @push_A
ldi A \:
call @push_A
ldi A \)
call @push_A
ldi A \3
call @push_A
ldi A \space
call @push_A
ldi A \:
call @push_A
ldi A \d
call @push_A
ldi A \e
call @push_A
ldi A \t
call @push_A
ldi A \c
call @push_A
ldi A \e
call @push_A
ldi A \p
call @push_A
ldi A \x
call @push_A
ldi A \e
call @push_A
ldi A \(
call @push_A
ldi A \space
call @push_A
ldi A \2
call @push_A
ldi A \space
call @push_A
ldi A \x
call @push_A
ldi A \e
call @push_A
ldi A \d
call @push_A
ldi A \n
call @push_A
ldi A \i
call @push_A
ldi A \space
call @push_A
ldi A \f
call @push_A
ldi A \o
call @push_A
ldi A \space
call @push_A
ldi A \e
call @push_A
ldi A \u
call @push_A
ldi A \l
call @push_A
ldi A \a
call @push_A
ldi A \v
call @push_A
; --- End String Literal 'value of index 2 (expected: 3): ' on stack ---
call @stacks_show_from_stack
ldi A 2
call @push_A
ldi A $arr1
call @push_A
call @stacks_array_read
call @print
; --- String Literal 'write index 1 and readback ' pushed to stack ---
ldi A 0
call @push_A
ldi A \space
call @push_A
ldi A \k
call @push_A
ldi A \c
call @push_A
ldi A \a
call @push_A
ldi A \b
call @push_A
ldi A \d
call @push_A
ldi A \a
call @push_A
ldi A \e
call @push_A
ldi A \r
call @push_A
ldi A \space
call @push_A
ldi A \d
call @push_A
ldi A \n
call @push_A
ldi A \a
call @push_A
ldi A \space
call @push_A
ldi A \1
call @push_A
ldi A \space
call @push_A
ldi A \x
call @push_A
ldi A \e
call @push_A
ldi A \d
call @push_A
ldi A \n
call @push_A
ldi A \i
call @push_A
ldi A \space
call @push_A
ldi A \e
call @push_A
ldi A \t
call @push_A
ldi A \i
call @push_A
ldi A \r
call @push_A
ldi A \w
call @push_A
; --- End String Literal 'write index 1 and readback ' on stack ---
call @stacks_show_from_stack
ldi A 12
call @push_A
call @print
ldi A 99
call @push_A
ldi A 1
call @push_A
ldi A $arr1
call @push_A
call @stacks_array_write
; --- String Literal 'value of index 1 (expected: 99): ' pushed to stack ---
ldi A 0
call @push_A
ldi A \space
call @push_A
ldi A \:
call @push_A
ldi A \)
call @push_A
ldi A \9
call @push_A
ldi A \9
call @push_A
ldi A \space
call @push_A
ldi A \:
call @push_A
ldi A \d
call @push_A
ldi A \e
call @push_A
ldi A \t
call @push_A
ldi A \c
call @push_A
ldi A \e
call @push_A
ldi A \p
call @push_A
ldi A \x
call @push_A
ldi A \e
call @push_A
ldi A \(
call @push_A
ldi A \space
call @push_A
ldi A \1
call @push_A
ldi A \space
call @push_A
ldi A \x
call @push_A
ldi A \e
call @push_A
ldi A \d
call @push_A
ldi A \n
call @push_A
ldi A \i
call @push_A
ldi A \space
call @push_A
ldi A \f
call @push_A
ldi A \o
call @push_A
ldi A \space
call @push_A
ldi A \e
call @push_A
ldi A \u
call @push_A
ldi A \l
call @push_A
ldi A \a
call @push_A
ldi A \v
call @push_A
; --- End String Literal 'value of index 1 (expected: 99): ' on stack ---
call @stacks_show_from_stack
ldi A 1
call @push_A
ldi A $arr1
call @push_A
call @stacks_array_read
call @print
ldi A 42
call @push_A
ldi A 7
call @push_A
ldi A $arr1
call @push_A
call @stacks_array_write
; --- String Literal 'value of index 5 (expected: 42): ' pushed to stack ---
ldi A 0
call @push_A
ldi A \space
call @push_A
ldi A \:
call @push_A
ldi A \)
call @push_A
ldi A \2
call @push_A
ldi A \4
call @push_A
ldi A \space
call @push_A
ldi A \:
call @push_A
ldi A \d
call @push_A
ldi A \e
call @push_A
ldi A \t
call @push_A
ldi A \c
call @push_A
ldi A \e
call @push_A
ldi A \p
call @push_A
ldi A \x
call @push_A
ldi A \e
call @push_A
ldi A \(
call @push_A
ldi A \space
call @push_A
ldi A \5
call @push_A
ldi A \space
call @push_A
ldi A \x
call @push_A
ldi A \e
call @push_A
ldi A \d
call @push_A
ldi A \n
call @push_A
ldi A \i
call @push_A
ldi A \space
call @push_A
ldi A \f
call @push_A
ldi A \o
call @push_A
ldi A \space
call @push_A
ldi A \e
call @push_A
ldi A \u
call @push_A
ldi A \l
call @push_A
ldi A \a
call @push_A
ldi A \v
call @push_A
; --- End String Literal 'value of index 5 (expected: 42): ' on stack ---
call @stacks_show_from_stack
ldi A 7
call @push_A
ldi A $arr1
call @push_A
call @stacks_array_read
call @print
; --- String Literal 'length of array  (expected: 5): ' pushed to stack ---
ldi A 0
call @push_A
ldi A \space
call @push_A
ldi A \:
call @push_A
ldi A \)
call @push_A
ldi A \5
call @push_A
ldi A \space
call @push_A
ldi A \:
call @push_A
ldi A \d
call @push_A
ldi A \e
call @push_A
ldi A \t
call @push_A
ldi A \c
call @push_A
ldi A \e
call @push_A
ldi A \p
call @push_A
ldi A \x
call @push_A
ldi A \e
call @push_A
ldi A \(
call @push_A
ldi A \space
call @push_A
ldi A \space
call @push_A
ldi A \y
call @push_A
ldi A \a
call @push_A
ldi A \r
call @push_A
ldi A \r
call @push_A
ldi A \a
call @push_A
ldi A \space
call @push_A
ldi A \f
call @push_A
ldi A \o
call @push_A
ldi A \space
call @push_A
ldi A \h
call @push_A
ldi A \t
call @push_A
ldi A \g
call @push_A
ldi A \n
call @push_A
ldi A \e
call @push_A
ldi A \l
call @push_A
; --- End String Literal 'length of array  (expected: 5): ' on stack ---
call @stacks_show_from_stack
ldi A $arr1
call @push_A
call @stacks_array_length
call @print
ldi A 42
call @push_A
ldi A 12
call @push_A
ldi A $arr1
call @push_A
call @stacks_array_write
; --- String Literal '--- array test suite end ---' pushed to stack ---
ldi A 0
call @push_A
ldi A \-
call @push_A
ldi A \-
call @push_A
ldi A \-
call @push_A
ldi A \space
call @push_A
ldi A \d
call @push_A
ldi A \n
call @push_A
ldi A \e
call @push_A
ldi A \space
call @push_A
ldi A \e
call @push_A
ldi A \t
call @push_A
ldi A \i
call @push_A
ldi A \u
call @push_A
ldi A \s
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
ldi A \space
call @push_A
ldi A \y
call @push_A
ldi A \a
call @push_A
ldi A \r
call @push_A
ldi A \r
call @push_A
ldi A \a
call @push_A
ldi A \space
call @push_A
ldi A \-
call @push_A
ldi A \-
call @push_A
ldi A \-
call @push_A
; --- End String Literal '--- array test suite end ---' on stack ---
call @stacks_show_from_stack
ldi A 0
call @push_A
call @print
ret
INCLUDE  stacks_runtime
