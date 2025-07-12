.PROCES 1 32
:~proc_entry_1 ; Default entry point for process 1
ldi A 0
push A
call @stacks_timer_set
ldi A 0
push A
ldi A &P2index
push A
call @stacks_shared_var_write
ldi A 2
push A
pop A
int ~SYSCALL_START_PROCESS
push A
ldi A 0
push A
ldi A &P3index
push A
call @stacks_shared_var_write
ldi A 3
push A
pop A
int ~SYSCALL_START_PROCESS
push A
ldi A 0
push A
ldi A &P4index
push A
call @stacks_shared_var_write
ldi A 4
push A
pop A
int ~SYSCALL_START_PROCESS
push A
ldi A 2
push A
. $start 1
pop A
sto A $start
ldi A 2048
push A
ldm A $start
push A
call @plus
. $max 1
pop A
sto A $max
:_0_while_condition
ldm A $start
push A
ldm A $max
push A
call @lt
pop A
tste A Z
jmpf :_0_while_end
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
jmp :_0_while_condition
:_0_while_end
ldi A 0
push A
. $index 1
pop A
sto A $index
:_1_while_condition
ldm A $index
push A
ldi A &workingList
push A
call @stacks_array_read
call @dup
call @multiply
ldm A $max
push A
call @lt
pop A
tste A Z
jmpf :_1_while_end
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
jmpf :_2_do_end
:try
ldm A &P4index
push A
ldi A 0
push A
call @eq
pop A
tste A Z
jmpf :_3_do_end
ldm A $index
push A
ldi A 1
push A
call @plus
ldi A &P4index
push A
call @stacks_shared_var_write
ldi A 4
push A
pop A
int ~SYSCALL_PRINT_NUMBER
int ~SYSCALL_PRINT_NL
jmp :done
:_3_do_end
ldm A &P3index
push A
ldi A 0
push A
call @eq
pop A
tste A Z
jmpf :_4_do_end
ldm A $index
push A
ldi A 1
push A
call @plus
ldi A &P3index
push A
call @stacks_shared_var_write
ldi A 3
push A
pop A
int ~SYSCALL_PRINT_NUMBER
int ~SYSCALL_PRINT_NL
jmp :done
:_4_do_end
ldm A &P2index
push A
ldi A 0
push A
call @eq
pop A
tste A Z
jmpf :_5_do_end
ldm A $index
push A
ldi A 1
push A
call @plus
ldi A &P2index
push A
call @stacks_shared_var_write
ldi A 2
push A
pop A
int ~SYSCALL_PRINT_NUMBER
int ~SYSCALL_PRINT_NL
jmp :done
:_5_do_end
ldi A 1
push A
call @stacks_sleep
jmp :try
:_2_do_end
:done
ldm A $index
push A
ldi A 1
push A
call @plus
pop A
sto A $index
jmp :_1_while_condition
:_1_while_end
:_6_while_condition
ldm A &P2index
push A
ldi A 0
push A
call @ne
pop A
tste A Z
jmpf :_6_while_end
ldi A 1
push A
call @stacks_sleep
jmp :_6_while_condition
:_6_while_end
ldi A 2
push A
pop A
int ~SYSCALL_STOP_PROCESS
push A
call @drop
:_7_while_condition
ldm A &P3index
push A
ldi A 0
push A
call @ne
pop A
tste A Z
jmpf :_7_while_end
ldi A 1
push A
call @stacks_sleep
jmp :_7_while_condition
:_7_while_end
ldi A 3
push A
pop A
int ~SYSCALL_STOP_PROCESS
push A
call @drop
:_8_while_condition
ldm A &P4index
push A
ldi A 0
push A
call @ne
pop A
tste A Z
jmpf :_8_while_end
ldi A 1
push A
call @stacks_sleep
jmp :_8_while_condition
:_8_while_end
ldi A 4
push A
pop A
int ~SYSCALL_STOP_PROCESS
push A
call @drop
ldi A 0
push A
. $counter 1
pop A
sto A $counter
:_9_while_condition
ldm A $counter
push A
ldi A &workingList
push A
call @stacks_array_length
call @lt
pop A
tste A Z
jmpf :_9_while_end
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
jmpf :_10_do_end
ldm A $counter
push A
ldi A &workingList
push A
call @stacks_array_read
pop A
int ~SYSCALL_PRINT_NUMBER
int ~SYSCALL_PRINT_NL
:_10_do_end
ldm A $counter
push A
ldi A 1
push A
call @plus
pop A
sto A $counter
jmp :_9_while_condition
:_9_while_end
ldi A 0
push A
call @stacks_timer_print
ldi A 1 ; PID of the current process ending
int ~SYSCALL_STOP_PROCESS ; Implicit stop at end of process block
.PROCES 2 32
:~proc_entry_2 ; Default entry point for process 2
:lus
:_11_while_condition
ldm A &P2index
push A
ldi A 0
push A
call @eq
pop A
tste A Z
jmpf :_11_while_end
ldi A 1
push A
call @stacks_sleep
jmp :_11_while_condition
:_11_while_end
ldm A &P2index
push A
ldi A 1
push A
call @minus
ldi A &workingList
push A
call @stacks_array_read
. $value 1
pop A
sto A $value
ldm A &P2index
push A
. $nextIndex 1
pop A
sto A $nextIndex
:_12_while_condition
ldm A $nextIndex
push A
ldi A &workingList
push A
call @stacks_array_length
call @ne
pop A
tste A Z
jmpf :_12_while_end
ldm A $nextIndex
push A
ldi A &workingList
push A
call @stacks_array_read
. $nextValue 1
pop A
sto A $nextValue
ldm A $nextValue
push A
ldi A 0
push A
call @ne
pop A
tste A Z
jmpf :_13_do_end
ldm A $nextValue
push A
ldm A $value
push A
call @mod
ldi A 0
push A
call @eq
pop A
tste A Z
jmpf :_14_do_end
ldi A 0
push A
ldm A $nextIndex
push A
ldi A &workingList
push A
call @stacks_array_write
:_14_do_end
:_13_do_end
ldm A $nextIndex
push A
ldi A 1
push A
call @plus
pop A
sto A $nextIndex
jmp :_12_while_condition
:_12_while_end
ldi A 0
push A
ldi A &P2index
push A
call @stacks_shared_var_write
jmp :lus
ldi A 2 ; PID of the current process ending
int ~SYSCALL_STOP_PROCESS ; Implicit stop at end of process block
.PROCES 3 32
:~proc_entry_3 ; Default entry point for process 3
:lus
:_15_while_condition
ldm A &P3index
push A
ldi A 0
push A
call @eq
pop A
tste A Z
jmpf :_15_while_end
ldi A 1
push A
call @stacks_sleep
jmp :_15_while_condition
:_15_while_end
ldm A &P3index
push A
ldi A 1
push A
call @minus
ldi A &workingList
push A
call @stacks_array_read
. $value 1
pop A
sto A $value
ldm A &P3index
push A
. $nextIndex 1
pop A
sto A $nextIndex
:_16_while_condition
ldm A $nextIndex
push A
ldi A &workingList
push A
call @stacks_array_length
call @ne
pop A
tste A Z
jmpf :_16_while_end
ldm A $nextIndex
push A
ldi A &workingList
push A
call @stacks_array_read
. $nextValue 1
pop A
sto A $nextValue
ldm A $nextValue
push A
ldi A 0
push A
call @ne
pop A
tste A Z
jmpf :_17_do_end
ldm A $nextValue
push A
ldm A $value
push A
call @mod
ldi A 0
push A
call @eq
pop A
tste A Z
jmpf :_18_do_end
ldi A 0
push A
ldm A $nextIndex
push A
ldi A &workingList
push A
call @stacks_array_write
:_18_do_end
:_17_do_end
ldm A $nextIndex
push A
ldi A 1
push A
call @plus
pop A
sto A $nextIndex
jmp :_16_while_condition
:_16_while_end
ldi A 0
push A
ldi A &P3index
push A
call @stacks_shared_var_write
jmp :lus
ldi A 3 ; PID of the current process ending
int ~SYSCALL_STOP_PROCESS ; Implicit stop at end of process block
.PROCES 4 32
:~proc_entry_4 ; Default entry point for process 4
:lus
:_19_while_condition
ldm A &P4index
push A
ldi A 0
push A
call @eq
pop A
tste A Z
jmpf :_19_while_end
ldi A 1
push A
call @stacks_sleep
jmp :_19_while_condition
:_19_while_end
ldm A &P4index
push A
ldi A 1
push A
call @minus
ldi A &workingList
push A
call @stacks_array_read
. $value 1
pop A
sto A $value
ldm A &P4index
push A
. $nextIndex 1
pop A
sto A $nextIndex
:_20_while_condition
ldm A $nextIndex
push A
ldi A &workingList
push A
call @stacks_array_length
call @ne
pop A
tste A Z
jmpf :_20_while_end
ldm A $nextIndex
push A
ldi A &workingList
push A
call @stacks_array_read
. $nextValue 1
pop A
sto A $nextValue
ldm A $nextValue
push A
ldi A 0
push A
call @ne
pop A
tste A Z
jmpf :_21_do_end
ldm A $nextValue
push A
ldm A $value
push A
call @mod
ldi A 0
push A
call @eq
pop A
tste A Z
jmpf :_22_do_end
ldi A 0
push A
ldm A $nextIndex
push A
ldi A &workingList
push A
call @stacks_array_write
:_22_do_end
:_21_do_end
ldm A $nextIndex
push A
ldi A 1
push A
call @plus
pop A
sto A $nextIndex
jmp :_20_while_condition
:_20_while_end
ldi A 0
push A
ldi A &P4index
push A
call @stacks_shared_var_write
jmp :lus
ldi A 4 ; PID of the current process ending
int ~SYSCALL_STOP_PROCESS ; Implicit stop at end of process block
. &workingList 2050
% &workingList 0 2050
. &P2index 1
. &P3index 1
. &P4index 1
