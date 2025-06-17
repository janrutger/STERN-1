.PROCES 1 64
:~proc_entry_1 ; Default entry point for process 1
ldi A 0
push A
call @stacks_timer_set
; --- String Literal 'welkom at stern-' pushed to stack ---
ldi A 0
push A
ldi A \-
push A
ldi A \n
push A
ldi A \r
push A
ldi A \e
push A
ldi A \t
push A
ldi A \s
push A
ldi A \space
push A
ldi A \t
push A
ldi A \a
push A
ldi A \space
push A
ldi A \m
push A
ldi A \o
push A
ldi A \k
push A
ldi A \l
push A
ldi A \e
push A
ldi A \w
push A
; --- End String Literal 'welkom at stern-' on stack ---
call @stacks_show_from_stack
ldi A 1
push A
pop A
int ~SYSCALL_PRINT_NUMBER
int ~SYSCALL_PRINT_NL
:loop
; --- String Literal 'give an instruction ' pushed to stack ---
ldi A 0
push A
ldi A \space
push A
ldi A \n
push A
ldi A \o
push A
ldi A \i
push A
ldi A \t
push A
ldi A \c
push A
ldi A \u
push A
ldi A \r
push A
ldi A \t
push A
ldi A \s
push A
ldi A \n
push A
ldi A \i
push A
ldi A \space
push A
ldi A \n
push A
ldi A \a
push A
ldi A \space
push A
ldi A \e
push A
ldi A \v
push A
ldi A \i
push A
ldi A \g
push A
; --- End String Literal 'give an instruction ' on stack ---
call @stacks_show_from_stack
call @stacks_raw_input_string
call @stacks_hash_from_stack
. $instruction 1
pop A
sto A $instruction
; --- String Literal 'start' pushed to stack ---
ldi A 0
push A
ldi A \t
push A
ldi A \r
push A
ldi A \a
push A
ldi A \t
push A
ldi A \s
push A
; --- End String Literal 'start' on stack ---
call @stacks_hash_from_stack
ldm A $instruction
push A
call @eq
pop A
tste A Z
jmpf :_0_do_end
; --- String Literal 'enter proces id     ' pushed to stack ---
ldi A 0
push A
ldi A \space
push A
ldi A \space
push A
ldi A \space
push A
ldi A \space
push A
ldi A \space
push A
ldi A \d
push A
ldi A \i
push A
ldi A \space
push A
ldi A \s
push A
ldi A \e
push A
ldi A \c
push A
ldi A \o
push A
ldi A \r
push A
ldi A \p
push A
ldi A \space
push A
ldi A \r
push A
ldi A \e
push A
ldi A \t
push A
ldi A \n
push A
ldi A \e
push A
; --- End String Literal 'enter proces id     ' on stack ---
call @stacks_show_from_stack
call @stacks_input
. $pid 1
pop A
sto A $pid
ldm A $pid
push A
pop A
int ~SYSCALL_START_PROCESS
push A
jmp :loop
:_0_do_end
; --- String Literal 'stop' pushed to stack ---
ldi A 0
push A
ldi A \p
push A
ldi A \o
push A
ldi A \t
push A
ldi A \s
push A
; --- End String Literal 'stop' on stack ---
call @stacks_hash_from_stack
ldm A $instruction
push A
call @eq
pop A
tste A Z
jmpf :_1_do_end
; --- String Literal 'enter proces id     ' pushed to stack ---
ldi A 0
push A
ldi A \space
push A
ldi A \space
push A
ldi A \space
push A
ldi A \space
push A
ldi A \space
push A
ldi A \d
push A
ldi A \i
push A
ldi A \space
push A
ldi A \s
push A
ldi A \e
push A
ldi A \c
push A
ldi A \o
push A
ldi A \r
push A
ldi A \p
push A
ldi A \space
push A
ldi A \r
push A
ldi A \e
push A
ldi A \t
push A
ldi A \n
push A
ldi A \e
push A
; --- End String Literal 'enter proces id     ' on stack ---
call @stacks_show_from_stack
call @stacks_input
pop A
sto A $pid
ldm A $pid
push A
pop A
int ~SYSCALL_STOP_PROCESS
push A
jmp :loop
:_1_do_end
; --- String Literal 'exit' pushed to stack ---
ldi A 0
push A
ldi A \t
push A
ldi A \i
push A
ldi A \x
push A
ldi A \e
push A
; --- End String Literal 'exit' on stack ---
call @stacks_hash_from_stack
ldm A $instruction
push A
call @eq
pop A
tste A Z
jmpf :_2_do_end
jmp :endShell
:_2_do_end
; --- String Literal 'unkown instruction - ' pushed to stack ---
ldi A 0
push A
ldi A \space
push A
ldi A \-
push A
ldi A \space
push A
ldi A \n
push A
ldi A \o
push A
ldi A \i
push A
ldi A \t
push A
ldi A \c
push A
ldi A \u
push A
ldi A \r
push A
ldi A \t
push A
ldi A \s
push A
ldi A \n
push A
ldi A \i
push A
ldi A \space
push A
ldi A \n
push A
ldi A \w
push A
ldi A \o
push A
ldi A \k
push A
ldi A \n
push A
ldi A \u
push A
; --- End String Literal 'unkown instruction - ' on stack ---
call @stacks_show_from_stack
jmp :loop
:endShell
ldi A 0
push A
call @stacks_timer_print
ldi A 100
push A
call @stacks_sleep
ldi A 1 ; PID of the current process ending
int ~SYSCALL_STOP_PROCESS ; Implicit stop at end of process block
.PROCES 2 64
:~proc_entry_2 ; Default entry point for process 2
ldi A 0
push A
call @sio_channel_on
ldi A 2
push A
call @stacks_timer_set
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
:_3_while_condition
ldm A $next
push A
ldi A 700
push A
call @ne
pop A
tste A Z
jmpf :_3_while_end
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
jmpf :_4_do_end
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
:_4_do_end
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
jmp :_3_while_condition
:_3_while_end
ldi A 2
push A
call @stacks_timer_print
:endless
jmp :endless
ldi A 2 ; PID of the current process ending
int ~SYSCALL_STOP_PROCESS ; Implicit stop at end of process block
.PROCES 3 64
:~proc_entry_3 ; Default entry point for process 3
ldi A 0
push A
call @sio_channel_on
ldi A 3
push A
call @stacks_timer_set
ldi A 0
push A
. $n 1
pop A
sto A $n
:_5_while_condition
ldm A $n
push A
ldi A 75
push A
call @lt
pop A
tste A Z
jmpf :_5_while_end
ldm A $n
push A
call @plot
ldm A $n
push A
ldi A 1
push A
call @plus
pop A
sto A $n
jmp :_5_while_condition
:_5_while_end
ldi A 3
push A
call @stacks_timer_print
:endless
jmp :endless
ldi A 3 ; PID of the current process ending
int ~SYSCALL_STOP_PROCESS ; Implicit stop at end of process block
