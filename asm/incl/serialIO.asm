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

    :wait_for_ack_open_channel
        # read status register
        ldi I 3
        ldx M $SIO_baseadres
        # check for ack (0) from SIO
        tst M 0
    jmpf :wait_for_ack_open_channel
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

    :wait_for_ack_write_channel
        # read status register
        ldi I 3
        ldx M $SIO_baseadres

        # check for error (3) from SIO
        tst M 3
        jmpt :fatal_sio_error

        # check for ack (0) from SIO
        tst M 0
    jmpf :wait_for_ack_write_channel
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

    :wait_for_ack_close_channel
        # read status register
        ldi I 3
        ldx M $SIO_baseadres
        
        # check for error (3) from SIO
        tst M 3
        jmpt :fatal_sio_error
        
        # check for ack (0) from SIO
        tst M 0
    jmpf :wait_for_ack_close_channel
ret


:fatal_sio_error
    call @fatal_error

