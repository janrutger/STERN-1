# MAIN program
# runs after init

call @init_stern
call @init_kernel

. $x_indx 1
% $x_indx 0

@program
    ldi Y 0
    :loop
        inc X $x_indx
        ldi C \null
        int 3

        call @wait

        ldm M $x_indx
        tst M 64
        jmpf :next
            ;sto Z $x_indx
            ;addi Y 1
        :next
            ;ldi C \space
            int 3
            ;int 1

        jmp :loop
halt


# helper routines
@wait
    ldi L 500

    :lus
        subi L 1
        tst L 0
        jmpf :lus
ret


