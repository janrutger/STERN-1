

call @init_stern
call @init_kernel

@program
    ldi X 0
    ldi Y 0
    ldi C \a 

    int 3
    call @wait
    int 3
halt


@wait
    ldi L 1500

    :lus
        subi L 1
        tst L 0
        jmpf :lus

ret
