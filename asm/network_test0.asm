.PROCES 1 128
:~proc_entry_1 ; Default entry point for process 1
; --- String Literal 'stern 0 sleeping ' pushed to stack ---
ldi A 0
push A
ldi A \space
push A
ldi A \g
push A
ldi A \n
push A
ldi A \i
push A
ldi A \p
push A
ldi A \e
push A
ldi A \e
push A
ldi A \l
push A
ldi A \s
push A
ldi A \space
push A
ldi A \0
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
; --- End String Literal 'stern 0 sleeping ' on stack ---
call @stacks_show_from_stack
ldi A 100
push A
call @stacks_sleep
; --- String Literal 'after sleep ' pushed to stack ---
ldi A 0
push A
ldi A \space
push A
ldi A \p
push A
ldi A \e
push A
ldi A \e
push A
ldi A \l
push A
ldi A \s
push A
ldi A \space
push A
ldi A \r
push A
ldi A \e
push A
ldi A \t
push A
ldi A \f
push A
ldi A \a
push A
; --- End String Literal 'after sleep ' on stack ---
call @stacks_show_from_stack
; --- String Literal 'sending ' pushed to stack ---
ldi A 0
push A
ldi A \space
push A
ldi A \g
push A
ldi A \n
push A
ldi A \i
push A
ldi A \d
push A
ldi A \n
push A
ldi A \e
push A
ldi A \s
push A
; --- End String Literal 'sending ' on stack ---
call @stacks_show_from_stack
ldi A 22
push A
pop B
di
call @~conn_zender_write_0
ei 
; --- String Literal 'send ' pushed to stack ---
ldi A 0
push A
ldi A \space
push A
ldi A \d
push A
ldi A \n
push A
ldi A \e
push A
ldi A \s
push A
; --- End String Literal 'send ' on stack ---
call @stacks_show_from_stack
ldi A 100
push A
call @stacks_sleep
; --- String Literal 'received ' pushed to stack ---
ldi A 0
push A
ldi A \space
push A
ldi A \d
push A
ldi A \e
push A
ldi A \v
push A
ldi A \i
push A
ldi A \e
push A
ldi A \c
push A
ldi A \e
push A
ldi A \r
push A
; --- End String Literal 'received ' on stack ---
call @stacks_show_from_stack
:lusje
ldi A 1
push A
pop A
int ~SYSCALL_PRINT_NUMBER
int ~SYSCALL_PRINT_NL
jmp :lusje
ldi A 1 ; PID of the current process ending
int ~SYSCALL_STOP_PROCESS ; Implicit stop at end of process block
@~conn_zender_write_0
  ldi A 0
  ldi C 1
  ldi K 1
  nop
  call @stacks_network_write
  nop
  ret
