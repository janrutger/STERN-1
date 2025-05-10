@main
    # --- Send a message ---
    # Destination address (e.g., instance 1)
    ldi A 1

    # Data to send (e.g., ASCII 'H')
    ldi B \0
    # Call the write routine (A=dest, B=data)
    int ~networkSend

    ldi B \1
    # Call the write routine (A=dest, B=data)
    int ~networkSend

    ldi B \2
    # Call the write routine (A=dest, B=data)
    int ~networkSend

    ldi B \3
    # Call the write routine (A=dest, B=data)
    int ~networkSend

    ldi B \4
    # Call the write routine (A=dest, B=data)
    int ~networkSend

    ldi B \5
    # Call the write routine (A=dest, B=data)
    int ~networkSend

    ldi B \6
    # Call the write routine (A=dest, B=data)
    int ~networkSend

    ldi B \7
    # Call the write routine (A=dest, B=data)
    int ~networkSend

    ldi B \8
    # Call the write routine (A=dest, B=data)
    int ~networkSend

    ldi B \9
    # Call the write routine (A=dest, B=data)
    int ~networkSend    

    ldi B \a
    # Call the write routine (A=dest, B=data)
    int ~networkSend

    ldi B \b
    # Call the write routine (A=dest, B=data)
    int ~networkSend

    ldi B \c
    # Call the write routine (A=dest, B=data)
    int ~networkSend

    ldi B \d
    # Call the write routine (A=dest, B=data)
    int ~networkSend

    ldi B \e
    # Call the write routine (A=dest, B=data)
    int ~networkSend

    ldi B \f
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