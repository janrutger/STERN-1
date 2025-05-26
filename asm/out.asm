@main
call @stacks_runtime_init
; --- String Literal 'jan rutger' (len: 10) ---
ldm K $_stacks_string_heap_pntr
; K = current heap pointer
addi K 11
; K = K + (len + 1) = potential new heap top
ldi M $_stacks_string_heap
addi M ~STACKS_STRING_HEAP_SIZE
; M = heap end address (exclusive)
tstg K M
; Is (potential new heap top K) > (heap end address M)?
jmpt :_string_literal_overflow_1
ldm A $_stacks_string_heap_pntr
; A = pointer to start of this string in heap
call @push_A
; Push this pointer onto STACKS data stack
; Copy characters to heap
ldi K \j
; K = MYascci for 'j' (via assembler \j)
ldi I 0
; Ensure I=0 for stx (M[M[ptr_var]+I])
stx K $_stacks_string_heap_pntr
; Store char K to M[M[$_stacks_string_heap_pntr]+I]
ldm X $_stacks_string_heap_pntr
addi X 1
sto X $_stacks_string_heap_pntr
; Advance heap pointer M[$_stacks_string_heap_pntr]++
ldi K \a
; K = MYascci for 'a' (via assembler \a)
ldi I 0
; Ensure I=0 for stx (M[M[ptr_var]+I])
stx K $_stacks_string_heap_pntr
; Store char K to M[M[$_stacks_string_heap_pntr]+I]
ldm X $_stacks_string_heap_pntr
addi X 1
sto X $_stacks_string_heap_pntr
; Advance heap pointer M[$_stacks_string_heap_pntr]++
ldi K \n
; K = MYascci for 'n' (via assembler \n)
ldi I 0
; Ensure I=0 for stx (M[M[ptr_var]+I])
stx K $_stacks_string_heap_pntr
; Store char K to M[M[$_stacks_string_heap_pntr]+I]
ldm X $_stacks_string_heap_pntr
addi X 1
sto X $_stacks_string_heap_pntr
; Advance heap pointer M[$_stacks_string_heap_pntr]++
ldi K \space
; K = MYascci for ' ' (via assembler \space)
ldi I 0
; Ensure I=0 for stx (M[M[ptr_var]+I])
stx K $_stacks_string_heap_pntr
; Store char K to M[M[$_stacks_string_heap_pntr]+I]
ldm X $_stacks_string_heap_pntr
addi X 1
sto X $_stacks_string_heap_pntr
; Advance heap pointer M[$_stacks_string_heap_pntr]++
ldi K \r
; K = MYascci for 'r' (via assembler \r)
ldi I 0
; Ensure I=0 for stx (M[M[ptr_var]+I])
stx K $_stacks_string_heap_pntr
; Store char K to M[M[$_stacks_string_heap_pntr]+I]
ldm X $_stacks_string_heap_pntr
addi X 1
sto X $_stacks_string_heap_pntr
; Advance heap pointer M[$_stacks_string_heap_pntr]++
ldi K \u
; K = MYascci for 'u' (via assembler \u)
ldi I 0
; Ensure I=0 for stx (M[M[ptr_var]+I])
stx K $_stacks_string_heap_pntr
; Store char K to M[M[$_stacks_string_heap_pntr]+I]
ldm X $_stacks_string_heap_pntr
addi X 1
sto X $_stacks_string_heap_pntr
; Advance heap pointer M[$_stacks_string_heap_pntr]++
ldi K \t
; K = MYascci for 't' (via assembler \t)
ldi I 0
; Ensure I=0 for stx (M[M[ptr_var]+I])
stx K $_stacks_string_heap_pntr
; Store char K to M[M[$_stacks_string_heap_pntr]+I]
ldm X $_stacks_string_heap_pntr
addi X 1
sto X $_stacks_string_heap_pntr
; Advance heap pointer M[$_stacks_string_heap_pntr]++
ldi K \g
; K = MYascci for 'g' (via assembler \g)
ldi I 0
; Ensure I=0 for stx (M[M[ptr_var]+I])
stx K $_stacks_string_heap_pntr
; Store char K to M[M[$_stacks_string_heap_pntr]+I]
ldm X $_stacks_string_heap_pntr
addi X 1
sto X $_stacks_string_heap_pntr
; Advance heap pointer M[$_stacks_string_heap_pntr]++
ldi K \e
; K = MYascci for 'e' (via assembler \e)
ldi I 0
; Ensure I=0 for stx (M[M[ptr_var]+I])
stx K $_stacks_string_heap_pntr
; Store char K to M[M[$_stacks_string_heap_pntr]+I]
ldm X $_stacks_string_heap_pntr
addi X 1
sto X $_stacks_string_heap_pntr
; Advance heap pointer M[$_stacks_string_heap_pntr]++
ldi K \r
; K = MYascci for 'r' (via assembler \r)
ldi I 0
; Ensure I=0 for stx (M[M[ptr_var]+I])
stx K $_stacks_string_heap_pntr
; Store char K to M[M[$_stacks_string_heap_pntr]+I]
ldm X $_stacks_string_heap_pntr
addi X 1
sto X $_stacks_string_heap_pntr
; Advance heap pointer M[$_stacks_string_heap_pntr]++
; Add null terminator (0) to the heap
ldi K \null
; K = null terminator (via assembler \null)
ldi I 0
stx K $_stacks_string_heap_pntr
ldm X $_stacks_string_heap_pntr
addi X 1
sto X $_stacks_string_heap_pntr
; Advance heap pointer for null terminator
jmp :_string_literal_continue_1
:_string_literal_overflow_1
; Heap overflow case
ldi A 0
; Load 0 (null pointer) into A
call @push_A
; Push null pointer onto STACKS data stack
:_string_literal_continue_1
; --- End String Literal 'jan rutger' ---
call @stacks_show_string
ldi A 42
call @push_A
call @print
ret
INCLUDE  stacks_runtime
