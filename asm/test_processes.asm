; procs.asm
; Test file for process management.
; Each process attempts to print its ID.

; Assumes the kernel provides a routine:


; User Process with Kernel PID 1
.PROCES 1 
    ; Load process ID (number 1)
    ; Call kernel print routine
:loop1
    ldi A 1      
    di   
        ; call @print_to_BCD 
        ; call @print_nl
    ei
    ; Infinite loop or halt
    jmp :loop1  


; User Process with Kernel PID 2
.PROCES 2 32 
    ; Load process ID (number 2)
    ; Call kernel print routine
:loop1
    ldi A 2      
    di   
        call @print_to_BCD 
        call @print_nl
    ei
    ; Infinite loop or halt
    jmp :loop1       


