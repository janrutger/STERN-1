


:receive_loop_s0
    # Call the routine to read from Service 0's data buffer
    call @read_service0_data
    # After @read_service0_data:
    #   A = Data byte (if status bit is 1/SET)
    #   Status bit: 1 (SET) if data was read, 0 (CLEARED) if buffer empty.

    # Jump to :message_received_s0 if status bit is SET (true), indicating data was read.
    jmpt :message_received_s0

    # No message, loop back and check again
    jmp :receive_loop_s0

:message_received_s0
    # A message was received from Service 0. Data is already in A.
    # Print the received character (which is in A)
    call @print_char
    call @print_nl

    # Go back to check for more messages
    jmp :receive_loop_s0