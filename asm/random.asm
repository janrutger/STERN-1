.PROCES 1 512
:~proc_entry_1 ; Default entry point for process 1
ldi A 0
push A
call @stacks_timer_set
. $totals 102
% $totals 0 102
ldi A 0
push A
. $start 1
pop A
sto A $start
ldi A 1000
push A
. $end 1
pop A
sto A $end
; --- String Literal 'init lists ' pushed to stack ---
ldi A 0
push A
ldi A \space
push A
ldi A \s
push A
ldi A \t
push A
ldi A \s
push A
ldi A \i
push A
ldi A \l
push A
ldi A \space
push A
ldi A \t
push A
ldi A \i
push A
ldi A \n
push A
ldi A \i
push A
; --- End String Literal 'init lists ' on stack ---
call @stacks_show_from_stack
:_0_while_condition
ldm A $start
push A
ldm A $end
push A
call @lt
pop A
tste A Z
jmpf :_0_while_end
ldi A 0
push A
ldi A &list
push A
call @stacks_array_append
ldm A $start
push A
ldi A 1
push A
call @plus
pop A
sto A $start
jmp :_0_while_condition
:_0_while_end
ldi A 0
push A
pop A
sto A $start
ldi A 100
push A
pop A
sto A $end
:_1_while_condition
ldm A $start
push A
ldm A $end
push A
call @lt
pop A
tste A Z
jmpf :_1_while_end
ldi A 0
push A
ldi A $totals
push A
call @stacks_array_append
ldm A $start
push A
ldi A 1
push A
call @plus
pop A
sto A $start
jmp :_1_while_condition
:_1_while_end
ldi A 0
push A
call @stacks_timer_print
ldi A 0
push A
pop A
sto A $start
ldi A 50000
push A
pop A
sto A $end
; --- String Literal 'generate randoms ' pushed to stack ---
ldi A 0
push A
ldi A \space
push A
ldi A \s
push A
ldi A \m
push A
ldi A \o
push A
ldi A \d
push A
ldi A \n
push A
ldi A \a
push A
ldi A \r
push A
ldi A \space
push A
ldi A \e
push A
ldi A \t
push A
ldi A \a
push A
ldi A \r
push A
ldi A \e
push A
ldi A \n
push A
ldi A \e
push A
ldi A \g
push A
; --- End String Literal 'generate randoms ' on stack ---
call @stacks_show_from_stack
:_2_while_condition
ldm A $start
push A
ldm A $end
push A
call @lt
pop A
tste A Z
jmpf :_2_while_end
call @rand
. $number 1
pop A
sto A $number
ldm A $number
push A
ldi A &list
push A
call @stacks_array_read
ldi A 1
push A
call @plus
ldm A $number
push A
ldi A &list
push A
call @stacks_array_write
ldm A $start
push A
ldi A 1
push A
call @plus
pop A
sto A $start
jmp :_2_while_condition
:_2_while_end
ldi A 0
push A
call @stacks_timer_print
ldi A 0
push A
. $counter 1
pop A
sto A $counter
; --- String Literal 'calc totals ' pushed to stack ---
ldi A 0
push A
ldi A \space
push A
ldi A \s
push A
ldi A \l
push A
ldi A \a
push A
ldi A \t
push A
ldi A \o
push A
ldi A \t
push A
ldi A \space
push A
ldi A \c
push A
ldi A \l
push A
ldi A \a
push A
ldi A \c
push A
; --- End String Literal 'calc totals ' on stack ---
call @stacks_show_from_stack
:_3_while_condition
ldm A $counter
push A
ldi A &list
push A
call @stacks_array_length
call @lt
pop A
tste A Z
jmpf :_3_while_end
ldm A $counter
push A
ldi A &list
push A
call @stacks_array_read
ldi A $totals
push A
call @stacks_array_read
ldi A 1
push A
call @plus
ldm A $counter
push A
ldi A &list
push A
call @stacks_array_read
ldi A $totals
push A
call @stacks_array_write
ldm A $counter
push A
ldi A 1
push A
call @plus
pop A
sto A $counter
jmp :_3_while_condition
:_3_while_end
ldi A 0
push A
call @stacks_timer_print
ldi A 0
push A
call @sio_channel_on
ldi A 0
push A
pop A
sto A $counter
:_4_while_condition
ldm A $counter
push A
ldi A $totals
push A
call @stacks_array_length
call @lt
pop A
tste A Z
jmpf :_4_while_end
ldm A $counter
push A
ldi A $totals
push A
call @stacks_array_read
pop B
int ~SYSCALL_PLOT_Y_POINT
ldm A $counter
push A
ldi A 1
push A
call @plus
pop A
sto A $counter
jmp :_4_while_condition
:_4_while_end
; --- String Literal 'plot done..... ' pushed to stack ---
ldi A 0
push A
ldi A \space
push A
ldi A \.
push A
ldi A \.
push A
ldi A \.
push A
ldi A \.
push A
ldi A \.
push A
ldi A \e
push A
ldi A \n
push A
ldi A \o
push A
ldi A \d
push A
ldi A \space
push A
ldi A \t
push A
ldi A \o
push A
ldi A \l
push A
ldi A \p
push A
; --- End String Literal 'plot done..... ' on stack ---
call @stacks_show_from_stack
ldi A 0
push A
call @stacks_timer_print
ldi A 0
push A
pop A
sto A $counter
ldi A 0
push A
. $sum 1
pop A
sto A $sum
:_5_while_condition
ldm A $counter
push A
ldi A $totals
push A
call @stacks_array_length
call @lt
pop A
tste A Z
jmpf :_5_while_end
ldm A $sum
push A
ldm A $counter
push A
ldi A $totals
push A
call @stacks_array_read
call @plus
pop A
sto A $sum
ldm A $counter
push A
ldi A 1
push A
call @plus
pop A
sto A $counter
jmp :_5_while_condition
:_5_while_end
; --- String Literal 'total counted points : ' pushed to stack ---
ldi A 0
push A
ldi A \space
push A
ldi A \:
push A
ldi A \space
push A
ldi A \s
push A
ldi A \t
push A
ldi A \n
push A
ldi A \i
push A
ldi A \o
push A
ldi A \p
push A
ldi A \space
push A
ldi A \d
push A
ldi A \e
push A
ldi A \t
push A
ldi A \n
push A
ldi A \u
push A
ldi A \o
push A
ldi A \c
push A
ldi A \space
push A
ldi A \l
push A
ldi A \a
push A
ldi A \t
push A
ldi A \o
push A
ldi A \t
push A
; --- End String Literal 'total counted points : ' on stack ---
call @stacks_show_from_stack
ldm A $sum
push A
pop A
int ~SYSCALL_PRINT_NUMBER
int ~SYSCALL_PRINT_NL
call @stacks_raw_input_string
call @drop
ldi A 1 ; PID of the current process ending
int ~SYSCALL_STOP_PROCESS ; Implicit stop at end of process block
. &list 1002
% &list 0 1002
