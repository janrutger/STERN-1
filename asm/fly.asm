.PROCES 1 64
:~proc_entry_1 ; Default entry point for process 1
ldi A 0
push A
call @sio_channel_on
ldi A 0
push A
call @stacks_timer_set
ldi A 1
push A
pop B
int ~SYSCALL_PLOT_Y_POINT
ldi A 1
push A
pop B
int ~SYSCALL_PLOT_Y_POINT
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
pop B
int ~SYSCALL_PLOT_Y_POINT
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
ldi A 0
push A
call @stacks_timer_print
ldi A 1 ; PID of the current process ending
int ~SYSCALL_STOP_PROCESS ; Implicit stop at end of process block
