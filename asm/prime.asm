.PROCES 1 32
:~proc_entry_1 ; Default entry point for process 1
ldi A 0
push A
call @stacks_timer_set
ldi A 0
push A
ldi A &klaar
push A
call @stacks_shared_var_write
ldi A 2
push A
pop A
int ~SYSCALL_START_PROCESS
push A
:_0_while_condition
ldm A &klaar
push A
ldi A 0
push A
call @eq
pop A
tste A Z
jmpf :_0_while_end
ldi A 1
push A
call @stacks_sleep
jmp :_0_while_condition
:_0_while_end
ldi A 0
push A
call @stacks_timer_print
ldi A 1 ; PID of the current process ending
int ~SYSCALL_STOP_PROCESS ; Implicit stop at end of process block
.PROCES 2 128
:~proc_entry_2 ; Default entry point for process 2
ldi A 2
push A
. $start 1
pop A
sto A $start
ldi A 128
push A
ldm A $start
push A
call @plus
. $max 1
pop A
sto A $max
:_1_while_condition
ldm A $start
push A
ldm A $max
push A
call @lt
pop A
tste A Z
jmpf :_1_while_end
ldm A $start
push A
ldi A &workingList
push A
call @stacks_array_append
ldm A $start
push A
ldi A 1
push A
call @plus
pop A
sto A $start
; --- String Literal '.' pushed to stack ---
ldi A 0
push A
ldi A \.
push A
; --- End String Literal '.' on stack ---
call @stacks_show_from_stack
jmp :_1_while_condition
:_1_while_end
ldi A 0
push A
. $index 1
pop A
sto A $index
:_2_while_condition
ldm A $index
push A
ldi A &workingList
push A
call @stacks_array_length
call @ne
pop A
tste A Z
jmpf :_2_while_end
ldm A $index
push A
ldi A 1
push A
call @plus
. $nextIndex 1
pop A
sto A $nextIndex
ldm A $index
push A
ldi A &workingList
push A
call @stacks_array_read
ldi A 0
push A
call @ne
pop A
tste A Z
jmpf :_3_do_end
:_4_while_condition
ldm A $nextIndex
push A
ldi A &workingList
push A
call @stacks_array_length
call @ne
pop A
tste A Z
jmpf :_4_while_end
ldm A $nextIndex
push A
ldi A &workingList
push A
call @stacks_array_read
ldi A 0
push A
call @ne
pop A
tste A Z
jmpf :_5_do_end
ldm A $nextIndex
push A
ldi A &workingList
push A
call @stacks_array_read
ldm A $index
push A
ldi A &workingList
push A
call @stacks_array_read
call @mod
ldi A 0
push A
call @eq
pop A
tste A Z
jmpf :_6_do_end
ldi A 0
push A
ldm A $nextIndex
push A
ldi A &workingList
push A
call @stacks_array_write
:_6_do_end
:_5_do_end
ldm A $nextIndex
push A
ldi A 1
push A
call @plus
pop A
sto A $nextIndex
jmp :_4_while_condition
:_4_while_end
:_3_do_end
ldm A $index
push A
pop A
int ~SYSCALL_PRINT_NUMBER
int ~SYSCALL_PRINT_NL
ldm A $index
push A
ldi A 1
push A
call @plus
pop A
sto A $index
jmp :_2_while_condition
:_2_while_end
ldi A 0
push A
. $counter 1
pop A
sto A $counter
:_7_while_condition
ldm A $counter
push A
ldi A &workingList
push A
call @stacks_array_length
call @lt
pop A
tste A Z
jmpf :_7_while_end
ldm A $counter
push A
ldi A &workingList
push A
call @stacks_array_read
ldi A 0
push A
call @ne
pop A
tste A Z
jmpf :_8_do_end
ldm A $counter
push A
ldi A &workingList
push A
call @stacks_array_read
pop A
int ~SYSCALL_PRINT_NUMBER
int ~SYSCALL_PRINT_NL
:_8_do_end
ldm A $counter
push A
ldi A 1
push A
call @plus
pop A
sto A $counter
jmp :_7_while_condition
:_7_while_end
ldi A 1
push A
ldi A &klaar
push A
call @stacks_shared_var_write
ldi A 2 ; PID of the current process ending
int ~SYSCALL_STOP_PROCESS ; Implicit stop at end of process block
. &workingList 130
% &workingList 0 130
. &klaar 1
