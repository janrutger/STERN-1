.PROCES 1 64
:~proc_entry_1 ; Default entry point for process 1
:_0_while_condition
ldi A 1
push A
ldi A 1
push A
call @eq
pop A
tste A Z
jmpf :_0_while_end
; --- String Literal 'stern 1 waiter ' pushed to stack ---
ldi A 0
push A
ldi A \space
push A
ldi A \r
push A
ldi A \e
push A
ldi A \t
push A
ldi A \i
push A
ldi A \a
push A
ldi A \w
push A
ldi A \space
push A
ldi A \1
push A
ldi A \space
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
; --- End String Literal 'stern 1 waiter ' on stack ---
call @stacks_show_from_stack
jmp :_0_while_condition
:_0_while_end
ldi A 1 ; PID of the current process ending
int ~SYSCALL_STOP_PROCESS ; Implicit stop at end of process block
