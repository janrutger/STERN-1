.PROCES 1 64
:~proc_entry_1 ; Default entry point for process 1
ldi A 0
push A
ldi A &counter
push A
call @stacks_shared_var_write
; --- String Literal 'controller starting test processes... ' pushed to stack ---
ldi A 0
push A
ldi A \space
push A
ldi A \.
push A
ldi A \.
push A
ldi A \.
push A
ldi A \s
push A
ldi A \e
push A
ldi A \s
push A
ldi A \s
push A
ldi A \e
push A
ldi A \c
push A
ldi A \o
push A
ldi A \r
push A
ldi A \p
push A
ldi A \space
push A
ldi A \t
push A
ldi A \s
push A
ldi A \e
push A
ldi A \t
push A
ldi A \space
push A
ldi A \g
push A
ldi A \n
push A
ldi A \i
push A
ldi A \t
push A
ldi A \r
push A
ldi A \a
push A
ldi A \t
push A
ldi A \s
push A
ldi A \space
push A
ldi A \r
push A
ldi A \e
push A
ldi A \l
push A
ldi A \l
push A
ldi A \o
push A
ldi A \r
push A
ldi A \t
push A
ldi A \n
push A
ldi A \o
push A
ldi A \c
push A
; --- End String Literal 'controller starting test processes... ' on stack ---
call @stacks_show_from_stack
ldm A &counter
push A
pop A
int ~SYSCALL_PRINT_NUMBER
int ~SYSCALL_PRINT_NL
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
ldi A 4
push A
pop A
int ~SYSCALL_START_PROCESS
push A
ldi A 300
push A
call @stacks_sleep
ldi A 1 ; PID of the current process ending
int ~SYSCALL_STOP_PROCESS ; Implicit stop at end of process block
.PROCES 2 64
:~proc_entry_2 ; Default entry point for process 2
:writerLoop
ldm A &counter
push A
ldi A 1
push A
call @plus
call @dup
ldi A &counter
push A
call @stacks_shared_var_write
ldi A &sharedArray
push A
call @stacks_array_append
; --- String Literal 'writer wrote: ' pushed to stack ---
ldi A 0
push A
ldi A \space
push A
ldi A \:
push A
ldi A \e
push A
ldi A \t
push A
ldi A \o
push A
ldi A \r
push A
ldi A \w
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
ldi A \r
push A
ldi A \w
push A
; --- End String Literal 'writer wrote: ' on stack ---
call @stacks_show_from_stack
ldm A &counter
push A
pop A
int ~SYSCALL_PRINT_NUMBER
int ~SYSCALL_PRINT_NL
ldi A 1
push A
call @stacks_sleep
ldi A 1
push A
call @stacks_sleep
ldm A &counter
push A
ldi A 5
push A
call @lt
pop A
tste A Z
jmpf :_0_goto_end
jmp :writerLoop
:_0_goto_end
; --- String Literal 'writer finished.' pushed to stack ---
ldi A 0
push A
ldi A \.
push A
ldi A \d
push A
ldi A \e
push A
ldi A \h
push A
ldi A \s
push A
ldi A \i
push A
ldi A \n
push A
ldi A \i
push A
ldi A \f
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
ldi A \r
push A
ldi A \w
push A
; --- End String Literal 'writer finished.' on stack ---
call @stacks_show_from_stack
ldi A 2 ; PID of the current process ending
int ~SYSCALL_STOP_PROCESS ; Implicit stop at end of process block
.PROCES 3 64
:~proc_entry_3 ; Default entry point for process 3
:readerLoop
; --- String Literal 'reader sees counter: ' pushed to stack ---
ldi A 0
push A
ldi A \space
push A
ldi A \:
push A
ldi A \r
push A
ldi A \e
push A
ldi A \t
push A
ldi A \n
push A
ldi A \u
push A
ldi A \o
push A
ldi A \c
push A
ldi A \space
push A
ldi A \s
push A
ldi A \e
push A
ldi A \e
push A
ldi A \s
push A
ldi A \space
push A
ldi A \r
push A
ldi A \e
push A
ldi A \d
push A
ldi A \a
push A
ldi A \e
push A
ldi A \r
push A
; --- End String Literal 'reader sees counter: ' on stack ---
call @stacks_show_from_stack
ldm A &counter
push A
pop A
int ~SYSCALL_PRINT_NUMBER
int ~SYSCALL_PRINT_NL
; --- String Literal 'reader sees array len: ' pushed to stack ---
ldi A 0
push A
ldi A \space
push A
ldi A \:
push A
ldi A \n
push A
ldi A \e
push A
ldi A \l
push A
ldi A \space
push A
ldi A \y
push A
ldi A \a
push A
ldi A \r
push A
ldi A \r
push A
ldi A \a
push A
ldi A \space
push A
ldi A \s
push A
ldi A \e
push A
ldi A \e
push A
ldi A \s
push A
ldi A \space
push A
ldi A \r
push A
ldi A \e
push A
ldi A \d
push A
ldi A \a
push A
ldi A \e
push A
ldi A \r
push A
; --- End String Literal 'reader sees array len: ' on stack ---
call @stacks_show_from_stack
ldi A &sharedArray
push A
call @stacks_array_length
pop A
int ~SYSCALL_PRINT_NUMBER
int ~SYSCALL_PRINT_NL
ldi A 1
push A
call @stacks_sleep
ldi A 1
push A
call @stacks_sleep
ldm A &counter
push A
ldi A 5
push A
call @lt
pop A
tste A Z
jmpf :_1_goto_end
jmp :readerLoop
:_1_goto_end
; --- String Literal 'reader finished.' pushed to stack ---
ldi A 0
push A
ldi A \.
push A
ldi A \d
push A
ldi A \e
push A
ldi A \h
push A
ldi A \s
push A
ldi A \i
push A
ldi A \n
push A
ldi A \i
push A
ldi A \f
push A
ldi A \space
push A
ldi A \r
push A
ldi A \e
push A
ldi A \d
push A
ldi A \a
push A
ldi A \e
push A
ldi A \r
push A
; --- End String Literal 'reader finished.' on stack ---
call @stacks_show_from_stack
ldi A 3 ; PID of the current process ending
int ~SYSCALL_STOP_PROCESS ; Implicit stop at end of process block
.PROCES 4 64
:~proc_entry_4 ; Default entry point for process 4
ldi A 0
push A
. $localVar 1
pop A
sto A $localVar
. $localArray 7
% $localArray 0 7
; --- String Literal 'local tester starting.' pushed to stack ---
ldi A 0
push A
ldi A \.
push A
ldi A \g
push A
ldi A \n
push A
ldi A \i
push A
ldi A \t
push A
ldi A \r
push A
ldi A \a
push A
ldi A \t
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
ldi A \s
push A
ldi A \e
push A
ldi A \t
push A
ldi A \space
push A
ldi A \l
push A
ldi A \a
push A
ldi A \c
push A
ldi A \o
push A
ldi A \l
push A
; --- End String Literal 'local tester starting.' on stack ---
call @stacks_show_from_stack
ldi A 100
push A
pop A
sto A $localVar
ldm A $localVar
push A
ldi A 1
push A
call @plus
pop A
sto A $localVar
; --- String Literal 'local var is: ' pushed to stack ---
ldi A 0
push A
ldi A \space
push A
ldi A \:
push A
ldi A \s
push A
ldi A \i
push A
ldi A \space
push A
ldi A \r
push A
ldi A \a
push A
ldi A \v
push A
ldi A \space
push A
ldi A \l
push A
ldi A \a
push A
ldi A \c
push A
ldi A \o
push A
ldi A \l
push A
; --- End String Literal 'local var is: ' on stack ---
call @stacks_show_from_stack
ldm A $localVar
push A
pop A
int ~SYSCALL_PRINT_NUMBER
int ~SYSCALL_PRINT_NL
ldi A 11
push A
ldi A $localArray
push A
call @stacks_array_append
ldi A 22
push A
ldi A $localArray
push A
call @stacks_array_append
ldi A 33
push A
ldi A $localArray
push A
call @stacks_array_append
; --- String Literal 'local array length is 3 : ' pushed to stack ---
ldi A 0
push A
ldi A \space
push A
ldi A \:
push A
ldi A \space
push A
ldi A \3
push A
ldi A \space
push A
ldi A \s
push A
ldi A \i
push A
ldi A \space
push A
ldi A \h
push A
ldi A \t
push A
ldi A \g
push A
ldi A \n
push A
ldi A \e
push A
ldi A \l
push A
ldi A \space
push A
ldi A \y
push A
ldi A \a
push A
ldi A \r
push A
ldi A \r
push A
ldi A \a
push A
ldi A \space
push A
ldi A \l
push A
ldi A \a
push A
ldi A \c
push A
ldi A \o
push A
ldi A \l
push A
; --- End String Literal 'local array length is 3 : ' on stack ---
call @stacks_show_from_stack
ldi A $localArray
push A
call @stacks_array_length
pop A
int ~SYSCALL_PRINT_NUMBER
int ~SYSCALL_PRINT_NL
; --- String Literal 'local array -1- is 22 : ' pushed to stack ---
ldi A 0
push A
ldi A \space
push A
ldi A \:
push A
ldi A \space
push A
ldi A \2
push A
ldi A \2
push A
ldi A \space
push A
ldi A \s
push A
ldi A \i
push A
ldi A \space
push A
ldi A \-
push A
ldi A \1
push A
ldi A \-
push A
ldi A \space
push A
ldi A \y
push A
ldi A \a
push A
ldi A \r
push A
ldi A \r
push A
ldi A \a
push A
ldi A \space
push A
ldi A \l
push A
ldi A \a
push A
ldi A \c
push A
ldi A \o
push A
ldi A \l
push A
; --- End String Literal 'local array -1- is 22 : ' on stack ---
call @stacks_show_from_stack
ldi A 1
push A
ldi A $localArray
push A
call @stacks_array_read
pop A
int ~SYSCALL_PRINT_NUMBER
int ~SYSCALL_PRINT_NL
; --- String Literal 'local tester finished.' pushed to stack ---
ldi A 0
push A
ldi A \.
push A
ldi A \d
push A
ldi A \e
push A
ldi A \h
push A
ldi A \s
push A
ldi A \i
push A
ldi A \n
push A
ldi A \i
push A
ldi A \f
push A
ldi A \space
push A
ldi A \r
push A
ldi A \e
push A
ldi A \t
push A
ldi A \s
push A
ldi A \e
push A
ldi A \t
push A
ldi A \space
push A
ldi A \l
push A
ldi A \a
push A
ldi A \c
push A
ldi A \o
push A
ldi A \l
push A
; --- End String Literal 'local tester finished.' on stack ---
call @stacks_show_from_stack
ldi A 4 ; PID of the current process ending
int ~SYSCALL_STOP_PROCESS ; Implicit stop at end of process block
. &counter 1
. &sharedArray 12
% &sharedArray 0 12
