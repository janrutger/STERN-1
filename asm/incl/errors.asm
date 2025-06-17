@fatal_error_old
    ldi X 5
    ldi Y 30
    ld I Y 
    muli I 64
    add I X
    ldi A \f
    stx A $VIDEO_MEM
halt


@fatal_error
    ldi X 56
    ldi Y 25
    ldi C \f 
    #int 3
halt