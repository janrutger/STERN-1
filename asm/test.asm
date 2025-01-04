;jmp @program
# this an be ingord

. $loc 1
. $jrk 1



@program
    ldi A 12
    ldi B 30
    add A B

    sto A $loc
:label
    ldm C $loc

    jmp @program

    ldi I \a
    stx A $loc

    jmp :label
    halt

@do
    sto B $jrk
