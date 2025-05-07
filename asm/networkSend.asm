@main
    # --- Send a message ---
    # Destination address (e.g., instance 1)
    ldi A 1

    # Data to send (e.g., ASCII 'H')
    ldi B \h
    # Call the write routine (A=dest, B=data)
    int ~networkSend

    ldi B \e
    # Call the write routine (A=dest, B=data)
    int ~networkSend

    ldi B \l
    # Call the write routine (A=dest, B=data)
    int ~networkSend

    ldi B \l
    # Call the write routine (A=dest, B=data)
    int ~networkSend

    ldi B \o
    # Call the write routine (A=dest, B=data)
    int ~networkSend

    ldi B \w
    # Call the write routine (A=dest, B=data)
    int ~networkSend

    ldi B \o 
    # Call the write routine (A=dest, B=data)
    int ~networkSend

    ldi B \r
    # Call the write routine (A=dest, B=data)
    int ~networkSend

    ldi B \d
    # Call the write routine (A=dest, B=data)
    int ~networkSend

    ldi B \!
    # Call the write routine (A=dest, B=data)
    int ~networkSend    

    ldi B \space
    call @print_char
    call @print_nl




    # Optional: Print confirmation to screen
    ldi A \s
    call @print_char
    ldi A \e
    call @print_char
    ldi A \n
    call @print_char
    ldi A \t
    call @print_char
    ldi A \!
    call @print_char
    call @print_nl

ret
    # Loop forever (or halt)
#:loop
#    jmp :loop
#ret