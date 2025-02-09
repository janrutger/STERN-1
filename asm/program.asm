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

    ldi A 3
    ldi B 3
    ldi C $sprite

    ldi X 33
    ldi Y 16
        
    :loop
        int 5

        call @wait
        call @wait

        int 5
        


:return   
halt


# helper routines
@wait
    ldi L 1000
    :lus
        subi L 1
        tst L 0
        jmpf :lus
ret







