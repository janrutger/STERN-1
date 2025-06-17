.PROCES 1 64
:~proc_entry_1 ; Default entry point for process 1
ldi A 0
push A
call @stacks_timer_set
ldi A 42
push A
pop A
int ~SYSCALL_PRINT_NUMBER
. $myArray 7
% $myArray 0 7
ldi A 51
push A
ldi A 0
push A
ldi A $myArray
push A
call @stacks_array_write
ldi A 52
push A
ldi A 1
push A
ldi A $myArray
push A
call @stacks_array_write
ldi A 0
push A
ldi A $myArray
push A
call @stacks_array_read
pop A
int ~SYSCALL_PRINT_NUMBER
ldi A 1
push A
ldi A $myArray
push A
call @stacks_array_read
pop A
int ~SYSCALL_PRINT_NUMBER
ldi A $myArray
push A
call @stacks_array_length
pop A
int ~SYSCALL_PRINT_NUMBER
ldi A 53
push A
ldi A $myArray
push A
call @stacks_array_append
ldi A $myArray
push A
call @stacks_array_length
pop A
int ~SYSCALL_PRINT_NUMBER
call @stacks_input
pop A
int ~SYSCALL_PRINT_NUMBER
call @stacks_raw_input_string
call @stacks_show_from_stack
; --- String Literal 'hello world ' pushed to stack ---
ldi A 0
push A
ldi A \space
push A
ldi A \d
push A
ldi A \l
push A
ldi A \r
push A
ldi A \o
push A
ldi A \w
push A
ldi A \space
push A
ldi A \o
push A
ldi A \l
push A
ldi A \l
push A
ldi A \e
push A
ldi A \h
push A
; --- End String Literal 'hello world ' on stack ---
call @stacks_show_from_stack
; --- String Literal 'a' pushed to stack ---
ldi A 0
push A
ldi A \a
push A
; --- End String Literal 'a' on stack ---
call @stacks_hash_from_stack
pop A
int ~SYSCALL_PRINT_NUMBER
; --- String Literal 'hb' pushed to stack ---
ldi A 0
push A
ldi A \b
push A
ldi A \h
push A
; --- End String Literal 'hb' on stack ---
call @stacks_hash_from_stack
pop A
int ~SYSCALL_PRINT_NUMBER
; --- String Literal 'hello world ' pushed to stack ---
ldi A 0
push A
ldi A \space
push A
ldi A \d
push A
ldi A \l
push A
ldi A \r
push A
ldi A \o
push A
ldi A \w
push A
ldi A \space
push A
ldi A \o
push A
ldi A \l
push A
ldi A \l
push A
ldi A \e
push A
ldi A \h
push A
; --- End String Literal 'hello world ' on stack ---
call @stacks_hash_from_stack
pop A
int ~SYSCALL_PRINT_NUMBER
call @~dothis
ldi A 2
push A
pop A
int ~SYSCALL_START_PROCESS
push A
ldi A 800
push A
call @stacks_sleep
ldi A 2
push A
pop A
int ~SYSCALL_STOP_PROCESS
push A
call @~dothis
ldi A 0
push A
call @stacks_timer_print
ldi A 1 ; PID of the current process ending
int ~SYSCALL_STOP_PROCESS ; Implicit stop at end of process block
@~dothis
ldi A 12
push A
ldi A 30
push A
call @plus
pop A
int ~SYSCALL_PRINT_NUMBER
ret
.PROCES 2 64
:~proc_entry_2 ; Default entry point for process 2
ldi A 0
push A
call @sio_channel_on
ldi A 1
push A
call @plot
ldi A 1
push A
call @plot
ldi A 1
push A
. $previous 1
pop A
sto A $previous
ldi A 2
push A
. $next 1
pop A
sto A $next
:_0_while_condition
ldm A $next
push A
ldi A 700
push A
call @ne
pop A
tste A Z
jmpf :_0_while_end
ldm A $previous
push A
ldm A $next
push A
call @stacks_gcd
. $cfactor 1
pop A
sto A $cfactor
ldi A 1
push A
ldm A $cfactor
push A
call @eq
pop A
tste A Z
jmpf :_1_do_end
ldm A $previous
push A
ldm A $next
push A
ldi A 1
push A
call @plus
call @plus
. $r 1
pop A
sto A $r
jmp :nextnumber
:_1_do_end
ldm A $previous
push A
ldm A $cfactor
push A
call @divide
pop A
sto A $r
:nextnumber
ldm A $r
push A
call @plot
ldm A $r
push A
pop A
sto A $previous
ldm A $next
push A
ldi A 1
push A
call @plus
pop A
sto A $next
jmp :_0_while_condition
:_0_while_end
:endless
jmp :endless
ldi A 2 ; PID of the current process ending
int ~SYSCALL_STOP_PROCESS ; Implicit stop at end of process block
