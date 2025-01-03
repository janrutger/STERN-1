;jmp @program
# this an be ingord

. $loc 1
. $jrk 1



@program
    ldi A 12
    ldi B 30
    add A B

    sto A $loc

    ldm C $loc

    jmp @program

    ldi I 8
    stx A $loc

    jmpx Z
    halt

@do
    sto B $jrk
