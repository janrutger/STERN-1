@is_char
    ldi M \9
    tstg A M 
    jmpf :nochar

    ldi M 57
    tstg M A
    jmpf :nochar

    ret
:nochar
    ret 

@is_operator
    tst A \-
    jmpt :isoperator
    
    tst A \+
    jmpt :isoperator

    ret
:isoperator
    ret

@is_digit
    ldi M 19
    tstg A M 
    jmpf :nodigit

    ldi M 30
    tstg M A
    jmpf :nodigit

    ret
:nodigit
    ret 

@is_neg
    tst A \-
    jmpf :notneg
    ldi M 19
    tstg B M 
    jmpf :notneg

    ldi M 30
    tstg M B
    jmpf :notneg

    ret
:notneg
    ret 