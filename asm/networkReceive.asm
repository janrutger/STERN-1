
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

    di
    call @read_nic_message
    ei

    # After @read_nic_message:
    #   A = Source Address (or \null if no message)
    #   B = Data Value
    #   C = Service ID
    #   Status bit: CLEARED if message received, SET if buffer empty.

    ;tst A \null
    # Jump to :message_received if status bit is CLEARED (false), indicating a message was read.
    jmpf :message_received 

    # No message, loop back and check again
    jmp :receive_loop

:message_received
    # A message was received. Data Value is in B.
    # Move the data from B to A, as @print_char expects the character in A.
    ld A B
    # Print the received character
    call @print_char

    # Optional: Add a newline after printing
    call @print_nl

    # Go back to check for more messages
    jmp :receive_loop