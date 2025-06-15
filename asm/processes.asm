.PROCES 1 64
:~proc_entry_1 ; Default entry point for process 1
ldi A 12
push A
. $a 1
pop A
sto A $a
ldi A 30
push A
. $b 1
pop A
sto A $b
:loop
ldm A $a
push A
ldm A $b
push A
call @plus
call @print
ldm A $a
push A
ldi A 1
push A
call @minus
pop A
sto A $a
ldi A 1
push A
ldi A 0
push A
call @lt
pop A
tste A Z
jmpf :_0_do_end
ldi A 12
push A
call @print
:_0_do_end
:done
ldi A 1 ; PID of the current process ending
int ~SYSCALL_STOP_PROCESS ; Implicit stop at end of process block
