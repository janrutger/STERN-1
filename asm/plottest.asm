.PROCES 1 32
:~proc_entry_1 ; Default entry point for process 1
ldi A 2
push A
pop A
int ~SYSCALL_START_PROCESS
push A
ldi A 3
push A
pop A
int ~SYSCALL_START_PROCESS
push A
:loop
ldi A 1
push A
call @stacks_sleep
jmp :loop
ldi A 1 ; PID of the current process ending
int ~SYSCALL_STOP_PROCESS ; Implicit stop at end of process block
.PROCES 2 64
:~proc_entry_2 ; Default entry point for process 2
ldi A 0
push A
call @stacks_timer_set
ldi A 10
push A
. $VertexAX 1
pop A
sto A $VertexAX
ldi A 10
push A
. $VertexAY 1
pop A
sto A $VertexAY
ldi A 630
push A
. $VertexBX 1
pop A
sto A $VertexBX
ldi A 10
push A
. $VertexBY 1
pop A
sto A $VertexBY
ldi A 320
push A
. $VertexCX 1
pop A
sto A $VertexCX
ldi A 470
push A
. $VertexCY 1
pop A
sto A $VertexCY
ldi A 10
push A
. $CurrentPX 1
pop A
sto A $CurrentPX
ldi A 10
push A
. $CurrentPY 1
pop A
sto A $CurrentPY
ldi A 5000
push A
. $steps 1
pop A
sto A $steps
ldi A 0
push A
. $step 1
pop A
sto A $step
ldi A 1
push A
call @sio_channel_on
:_0_while_condition
ldm A $step
push A
ldm A $steps
push A
call @lt
pop A
tste A Z
jmpf :_0_while_end
call @rand
ldi A 3
push A
call @mod
. $next 1
pop A
sto A $next
ldm A $next
push A
ldi A 0
push A
call @eq
pop A
tste A Z
jmpf :_1_do_end
call @~SelectVertexA
; --- String Literal 'a' pushed to stack ---
ldi A 0
push A
ldi A \a
push A
; --- End String Literal 'a' on stack ---
call @stacks_show_from_stack
:_1_do_end
ldm A $next
push A
ldi A 1
push A
call @eq
pop A
tste A Z
jmpf :_2_do_end
call @~SelectVertexB
; --- String Literal 'b' pushed to stack ---
ldi A 0
push A
ldi A \b
push A
; --- End String Literal 'b' on stack ---
call @stacks_show_from_stack
:_2_do_end
ldm A $next
push A
ldi A 2
push A
call @eq
pop A
tste A Z
jmpf :_3_do_end
call @~SelectVertexC
; --- String Literal 'c' pushed to stack ---
ldi A 0
push A
ldi A \c
push A
; --- End String Literal 'c' on stack ---
call @stacks_show_from_stack
:_3_do_end
ldm A $CurrentPX
push A
ldm A $TargetVX
push A
call @plus
ldi A 2
push A
call @divide
pop A
sto A $CurrentPX
ldm A $CurrentPY
push A
ldm A $TargetVY
push A
call @plus
ldi A 2
push A
call @divide
pop A
sto A $CurrentPY
ldm A $CurrentPX
push A
ldm A $CurrentPY
push A
pop B
pop A
int ~SYSCALL_DRAW_XY_POINT
ldm A $step
push A
ldi A 1
push A
call @plus
pop A
sto A $step
jmp :_0_while_condition
:_0_while_end
ldi A 0
push A
call @stacks_timer_print
ldi A 600
push A
call @stacks_sleep
ldi A 2 ; PID of the current process ending
int ~SYSCALL_STOP_PROCESS ; Implicit stop at end of process block
@~SelectVertexA
ldm A $VertexAX
push A
. $TargetVX 1
pop A
sto A $TargetVX
ldm A $VertexAY
push A
. $TargetVY 1
pop A
sto A $TargetVY
ret
@~SelectVertexB
ldm A $VertexBX
push A
pop A
sto A $TargetVX
ldm A $VertexBY
push A
pop A
sto A $TargetVY
ret
@~SelectVertexC
ldm A $VertexCX
push A
pop A
sto A $TargetVX
ldm A $VertexCY
push A
pop A
sto A $TargetVY
ret
.PROCES 3 64
:~proc_entry_3 ; Default entry point for process 3
ldi A 0
push A
call @sio_channel_on
ldi A 1
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
:_4_while_condition
ldm A $next
push A
ldi A 700
push A
call @ne
pop A
tste A Z
jmpf :_4_while_end
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
jmpf :_5_do_end
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
:_5_do_end
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
jmp :_4_while_condition
:_4_while_end
ldi A 1
push A
call @stacks_timer_print
ldi A 600
push A
call @stacks_sleep
ldi A 3 ; PID of the current process ending
int ~SYSCALL_STOP_PROCESS ; Implicit stop at end of process block
