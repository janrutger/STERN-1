.PROCES 1 64
:~proc_entry_1 ; Default entry point for process 1
ldi A 16
push A
. $number 1
pop A
sto A $number
ldi A 1
push A
. $result 1
pop A
sto A $result
:_0_while_condition
ldm A $number
push A
ldi A 1
push A
call @ne
pop A
tste A Z
jmpf :_0_while_end
ldm A $result
push A
ldm A $number
push A
call @multiply
pop A
sto A $result
ldm A $number
push A
ldi A 1
push A
call @minus
pop A
sto A $number
jmp :_0_while_condition
:_0_while_end
ldm A $result
push A
pop A
int ~SYSCALL_PRINT_NUMBER
int ~SYSCALL_PRINT_NL
ldi A 1 ; PID of the current process ending
int ~SYSCALL_STOP_PROCESS ; Implicit stop at end of process block
