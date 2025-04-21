@open_channel
    # Expects channelnumber to open in A 

    # set channelnumber in register (0)
    ldi I 0
    stx A $SIO_baseadres
    
    # set command in register (1)
    # 0 = open channel
    ldi M 0
    ldi I 1
    stx M $SIO_baseadres

    # set status in register (3)
    # 1 = data ready
    ldi M 1
    ldi I 3
    stx M $SIO_baseadres
ret


@write_channel
    # Expects channelnumber to write in A 
    # Expects data to write in B

    # set channelnumber in register (0)
    ldi I 0
    stx A $SIO_baseadres
    
    # set command in register (1)
    # 1 = write to channel
    ldi M 1
    ldi I 1
    stx M $SIO_baseadres

    # set data in register (2)
    ldi I 2
    stx B $SIO_baseadres

    # set status in register (3)
    # 1 = data ready
    ldi M 1
    ldi I 3
    stx M $SIO_baseadres
ret


@close_channel
    # Expects channelnumber to close in A 

    # set channelnumber in register (0)
    ldi I 0
    stx A $SIO_baseadres
    
    # set command in register (1)
    # 3 = close channel
    ldi M 3
    ldi I 1
    stx M $SIO_baseadres

    # set status in register (3)
    # 1 = data ready
    ldi M 1
    ldi I 3
    stx M $SIO_baseadres
ret

