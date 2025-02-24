@fatal_error
    ldi X 5
    ldi Y 30
    ld I Y 
    muli I 64
    add I X
    ldi A \f
    stx A $VIDEO_MEM
halt