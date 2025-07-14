.PROCES 1 64
:~proc_entry_1 ; Default entry point for process 1
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
ldi A 0
push A
. $a 1
pop A
sto A $a
ldi A 0
push A
. $b 1
pop A
sto A $b
ldi A 0
push A
. $c 1
pop A
sto A $c
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
call @multiply
ldi A 999
push A
call @divide
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
ldm A $a
push A
ldi A 1
push A
call @plus
pop A
sto A $a
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
ldm A $b
push A
ldi A 1
push A
call @plus
pop A
sto A $b
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
ldm A $c
push A
ldi A 1
push A
call @plus
pop A
sto A $c
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
; --- String Literal '.' pushed to stack ---
ldi A 0
push A
ldi A \.
push A
; --- End String Literal '.' on stack ---
call @stacks_show_from_stack
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
; --- String Literal 'a is : ' pushed to stack ---
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
ldi A \i
push A
ldi A \space
push A
ldi A \a
push A
; --- End String Literal 'a is : ' on stack ---
call @stacks_show_from_stack
ldm A $a
push A
pop A
int ~SYSCALL_PRINT_NUMBER
int ~SYSCALL_PRINT_NL
; --- String Literal 'b is : ' pushed to stack ---
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
ldi A \i
push A
ldi A \space
push A
ldi A \b
push A
; --- End String Literal 'b is : ' on stack ---
call @stacks_show_from_stack
ldm A $b
push A
pop A
int ~SYSCALL_PRINT_NUMBER
int ~SYSCALL_PRINT_NL
; --- String Literal 'c is : ' pushed to stack ---
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
ldi A \i
push A
ldi A \space
push A
ldi A \c
push A
; --- End String Literal 'c is : ' on stack ---
call @stacks_show_from_stack
ldm A $c
push A
pop A
int ~SYSCALL_PRINT_NUMBER
int ~SYSCALL_PRINT_NL
ldi A 300
push A
call @stacks_sleep
ldi A 1 ; PID of the current process ending
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
