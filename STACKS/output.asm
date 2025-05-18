; --- Data Segment ---
STACK_BOTTOM: .word 0 ; Label for bottom of stack memory (for reference)
            .block 100 ; Reserve 100 words for the data stack
STACK_TOP_ADDR_PLUS_1: ; Address *after* the top of the stack block
SP:         .word STACK_BOTTOM ; Stack Pointer, initialized to the start of stack memory
x: .word 100  ; VALUE x
myArr: .block 20     ; ARRAY myArr[20]
S_1: .string "in another func"

; --- Code Segment ---
_start: ; Program entry point
    ldi STACK_BOTTOM  ; Initialize Stack Pointer variable
    sto SP

; Processing DEFINE block (declarations handled in data segment)

main: ; FUNCTION main
    lod A x        ; Load value of variable 'x' into A
    call @runtime_push_A   ; Push value onto stack
    call @runtime_print_tos_and_nl
    call anotherFunc     ; Explicit call to function 'anotherFunc'
    ret                 ; End of FUNCTION main

anotherFunc: ; FUNCTION anotherFunc
    ldi S_1      ; Load address of string "in another func"
    call @runtime_push_A ; Push string address onto stack
    call @runtime_print_tos_and_nl
    ret                 ; End of FUNCTION anotherFunc
:myLabel ; LABEL myLabel
    jmp :myLabel         ; GOTO myLabel
    halt        ; End of program
