
    # Print initial message
    ldi A \r
    call @print_char
    ldi A \e
    call @print_char
    ldi A \a
    call @print_char
    ldi A \d
    call @print_char
    ldi A \y
    call @print_char
    ldi A \.
    call @print_char
    ldi A \.
    call @print_char
    ldi A \.
    call @print_char
    call @print_nl


:receive_loop
    # Check if a message is available in the buffer
    call @read_nic_message
    # @read_nic_message returns:
    # Register A = received data (or \null if no message read)
    tst A \null
    jmpf :message_received 

    # No message, loop back and check again
    jmp :receive_loop

:message_received
    # Register A contains data
    # Print the received character
    call @print_char

    # Optional: Add a newline after printing
    call @print_nl

    # Go back to check for more messages
    jmp :receive_loop