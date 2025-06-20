.PROCES 1 64
:~proc_entry_1 ; Default entry point for process 1
. $myArr1 10
% $myArr1 0 10
ldi A 12
push A
ldi A &myVar
push A
call @stacks_shared_var_write
ldi A 42
push A
ldi A 1
push A
ldi A &myArr
push A
call @stacks_array_write
ldi A 43
push A
ldi A &myArr
push A
call @stacks_array_append
ldi A 67
push A
ldi A $myArr1
push A
call @stacks_array_append
ldi A 1
push A
ldi A &myArr
push A
call @stacks_array_read
pop A
int ~SYSCALL_PRINT_NUMBER
int ~SYSCALL_PRINT_NL
ldi A $myArr1
push A
call @stacks_array_length
pop A
int ~SYSCALL_PRINT_NUMBER
int ~SYSCALL_PRINT_NL
ldm A &myVar
push A
pop A
int ~SYSCALL_PRINT_NUMBER
int ~SYSCALL_PRINT_NL
ldi A &myArr
push A
call @stacks_array_length
pop A
int ~SYSCALL_PRINT_NUMBER
int ~SYSCALL_PRINT_NL
ldi A 1 ; PID of the current process ending
int ~SYSCALL_STOP_PROCESS ; Implicit stop at end of process block
. &myVar 1
. &myArr 18
% &myArr 0 18
