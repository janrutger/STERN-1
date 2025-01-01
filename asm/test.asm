
# this an be ingord

. $loc 1

@program
    ldi A 12
    ldi B 30
    add A B

    sto A $loc

    ldm C $loc

    halt