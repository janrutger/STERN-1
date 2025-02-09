# MAIN program
# runs after init

call @init_stern
call @init_kernel


@program
# print a sprite
# Reg A = sprite widht (X)
# Reg B = sprite height (Y)
# Reg C = pointer to sprite array
# Reg X = X pos of the first pixel
# Reg Y = Y pos of the first pixel

    . $sprite 9
    % $sprite 1 1 1 1 0 1 1 1 1

    . $sprite1 64
    % $sprite1 0	1	0	1	1	0	1	0 0	1	0	0	0	0	1	0 1	0	0	0	0	0	0	1 1	0	1	0	0	1	0	1 1	0	0	0	0	0	0	1 1	1	0	1	1	0	1	1 0	1	0	0	0	0	1	0 0	0	1	1	1	1	0	0    
    
    ldi A 8
    ldi B 8
    ldi C $sprite1

    ldi X 33
    ldi Y 16

    ; ldi C \b 
    ; muli C 20
    ; ldm M $FONTS
    ; add C M
    ; ldi A 4
    ; ldi B 5
        
    :loop
        int 5

        call @wait
        int 5

        addi X 1
        addi Y 1
    jmp :loop

        


:return   
halt


# helper routines
@wait
    ldi L 3000
    :lus
        subi L 1
        nop
        tst L 0
        jmpf :lus
ret







