

# Define a buffer for incoming network messages
. $NET_RCV_BUFFER 64
equ ~net_rcv_buffer_wrap 63
equ ~net_rcv_message_size 3

. $NET_RCV_BUFFER_ADRES 1
. $NET_RCV_READ_PNTR 1
. $NET_RCV_WRITE_PNTR 1
. $NET_RCV_EXPECTED_PACKET_NUM 1

equ ~receive_status 0
equ ~src_adres 1
equ ~data_in 2

equ ~send_status 3
equ ~dst_adres 4
equ ~data_out 5

equ ~ack_status 6
equ ~message_type 7
equ ~packetnumber 8

equ ~service_id_out 9   
equ ~service_id_in 10   

equ ~data_type  0
equ ~ack_type  1

equ ~idle  0
equ ~ack   0
equ ~nack  1
equ ~noresend 2 

. $tmpstore 1

@init_nic_buffer
# --- Maybe add buffer init code to loader ---
    ldi Z 0
    sto Z $NET_RCV_READ_PNTR
    sto Z $NET_RCV_WRITE_PNTR
    ldi M $NET_RCV_BUFFER
    sto M $NET_RCV_BUFFER_ADRES

    # Initialize expected packet number to 0
    sto Z $NET_RCV_EXPECTED_PACKET_NUM
ret


# write data to nic, ~send_status=1
# wait for ACK ~send_status=0
@write_data_message_isr
@write_nic_isr
    # expects dest-adres in A 
    # expects data to send in B 
    # expects service_id in C


    ldi I ~dst_adres
    stx A $NIC_baseadres

    # Set message type to DATA_TYPE
    ldi M ~data_type
    ldi I ~message_type
    stx M $NIC_baseadres

    # Store the Service ID for the outgoing packet
    ldi I ~service_id_out
    stx C $NIC_baseadres

    ldi I ~data_out
    stx B $NIC_baseadres

    # set send status to 1
    ldi M 1
    ldi I ~send_status
    stx M $NIC_baseadres
    # wait for ACK
    :wait_for_nic_sending_ack
        ldi I ~send_status
        ldx M $NIC_baseadres
        # check for ACK
        tst M 0
    jmpf :wait_for_nic_sending_ack
rti


# write ACK-type helper
@write_ack_message
    # expects dest-adres in A 
    # expects ack/nack to send in B 

    ldi I ~dst_adres
    stx A $NIC_baseadres

    ldi M ~ack_type
    ldi I ~message_type
    stx M $NIC_baseadres

    ldi I ~ack_status
    stx B $NIC_baseadres

    # set send status to 1
    ldi M 1
    ldi I ~send_status
    stx M $NIC_baseadres

    # wait for ACK
    :wait_for_nic_sending_ack1
        ldi I ~send_status
        ldx M $NIC_baseadres
        # check for ACK
        tst M ~idle
    jmpf :wait_for_nic_sending_ack1
ret


# Network Receive Interrupt Service Routine
# Triggered when NIC has received data (~receive_status != 0)
@read_nic_isr
    # packetnumber is in A after calling this interrupt
    # store it in K
    ld K A
    ldm M $NET_RCV_EXPECTED_PACKET_NUM
    tste K M 
    jmpt :handle_expected_packet_number
    # when the received packetnumber is lower then expected
    tstg M K
    jmpt :send_ack_on_old_message
    # otherwise handle packet out of sequence
    jmp :handle_out_of_sequence_packet
    

    # when here the packet is expected
:handle_expected_packet_number

    # --- Check if buffer is full ---
    # Calculate available space in the buffer.
    # W (write pointer) is in M, R (read pointer) is in L.
    # K still holds the packet number.
    ldm M $NET_RCV_WRITE_PNTR   
    ldm L $NET_RCV_READ_PNTR     

    tste L M                        
        # Test if L (read_ptr) == M (write_ptr)
    jmpt :read_nic_isr_buffer_empty 
        # If equal, buffer is empty

:read_nic_isr_buffer_not_empty
    # Buffer not empty. Available bytes = (L_read_ptr - M_write_ptr + 64) & 63
    sub L M                         
        # L = L_read_ptr - M_write_ptr
    addi L 64                       
        # L = L_read_ptr - M_write_ptr + 64
    andi L ~net_rcv_buffer_wrap     
        # L now holds available_bytes
    jmp :read_nic_isr_check_space

:read_nic_isr_buffer_empty
    # Buffer is empty. Available bytes = 64 (full buffer capacity).
    ldi L 64                        
        # L = 64 (available_bytes)

:read_nic_isr_check_space
    # L holds available_bytes. Check if L < message_size (3)
    ldi M ~net_rcv_message_size     
        # M = 3 (message_size)
    # tstg M L tests if M > L (message_size > available_bytes)
    tstg M L                        
    jmpt :skip_packet_storage_due_to_full_buffer 
        # If message_size > available_bytes, buffer is full for this message.

    # Enough space, write to buffer

    call @write_to_networkbuffer
    
    
    # Send a ack
    # This point the data is stored, 
    # and send a ACK to the sender 
    ldi I ~packetnumber
    stx K $NIC_baseadres

    # A-reg  contains the dst-adres
    
    ldi B ~ack

    call @write_ack_message

    addi K 1
    sto K $NET_RCV_EXPECTED_PACKET_NUM
    jmp :read_nic_isr_end

# resend ACK on earlier processed message
:send_ack_on_old_message
    ldi I ~packetnumber
    stx K $NIC_baseadres
    # A-reg  NOT contains already the dst adres
    # Load destination address for the NACK (source address of the incoming packet)
    ldi I ~src_adres
    ldx A $NIC_baseadres
    ldi B ~ack
    call @write_ack_message
    jmp :read_nic_isr_end


:skip_packet_storage_due_to_full_buffer
    # This point is reached when the buffer is full.
    # In this case, we want to send an NACK to the sender.
    # This NACK send the expected packetnumber
    # send a nack
    ldm K $NET_RCV_EXPECTED_PACKET_NUM
    ldi I ~packetnumber
    stx K $NIC_baseadres

    # A-reg  NOT contains already the dst adres
    # Load destination address for the NACK (source address of the incoming packet)
    ldi I ~src_adres
    ldx A $NIC_baseadres

    ldi B ~nack
    call @write_ack_message

    jmp :read_nic_isr_end

:handle_out_of_sequence_packet
    # received an unexpected pakketnumber
    # discard the message and send a NORESEND with the expected packet number
    ldm K $NET_RCV_EXPECTED_PACKET_NUM
    ldi I ~packetnumber
    stx K $NIC_baseadres

    # A-reg needs to contain the destination address for the NORESEND (source of the incoming packet)
    ldi I ~src_adres
    ldx A $NIC_baseadres

    ldi B ~noresend 
    call @write_ack_message

    jmp :read_nic_isr_end



:read_nic_isr_end
    # Clear the NIC's receive status to indicate this packet event has been handled
    ldi M 0
    ldi I ~receive_status
    stx M $NIC_baseadres
rti






@write_to_networkbuffer
    # This routine is called after the buffer full check has passed.
    # It reads the message components (src_addr, data, service_id) from the NIC
    # (A=src_addr, B=data_in, C=service_id_in are read from NIC within this routine)
    # and stores them into the $NET_RCV_BUFFER.
    # It then updates the $NET_RCV_WRITE_PNTR by ~net_rcv_message_size.

    # Read source address from NIC into A
    ldi I ~src_adres
    ldx A $NIC_baseadres

    # Read data byte from NIC into B
    ldi I ~data_in
    ldx B $NIC_baseadres

    # Read Service ID from NIC into C
    ldi I ~service_id_in
    ldx C $NIC_baseadres

    # K still holds the packet number (not stored in the buffer message in this design).

    # Get the current write pointer (offset for the first byte of the message)
    ; Load current write offset into I
    ldm I $NET_RCV_WRITE_PNTR   

    # Store src_addr (from A) into buffer at current write offset
    # stx uses I as the index into the memory block starting at $NET_RCV_BUFFER_ADRES
    stx A $NET_RCV_BUFFER_ADRES

    # Increment I to point to the next byte location, wrap if necessary for the index
    addi I 1 
    andi I ~net_rcv_buffer_wrap
    ; Store data_in (from B) into buffer at the new offset
    stx B $NET_RCV_BUFFER_ADRES 

    # Increment I again for the third byte, wrap if necessary for the index
    addi I 1
    andi I ~net_rcv_buffer_wrap
    ; Store service_id_in (from C) into buffer at the new offset
    stx C $NET_RCV_BUFFER_ADRES 

    # Now, update the main $NET_RCV_WRITE_PNTR by the full message_size
    ldm M $NET_RCV_WRITE_PNTR
    ; Add message_size (3)
    ; Apply buffer wrap
    ; Store updated write pointer
    addi M ~net_rcv_message_size    
    andi M ~net_rcv_buffer_wrap  
    sto M $NET_RCV_WRITE_PNTR       
ret




@read_nic_message

# and a routine to read from the NIC buffer
# API:
# Reads a 3-byte message (src_addr, data_value, service_id) from the network receive buffer.
# Returns:
#   A: src_addr (or \null if buffer was empty)
#   B: data_value (undefined if buffer was empty)
#   C: service_id (undefined if buffer was empty)
#   Status bit:
#       - SET (true) if the buffer was empty (A will be \null).
#       - CLEARED (false) if a message was successfully read (A, B, C contain the message parts).
# Modifies: A, B, C, I, L, M. Updates $NET_RCV_READ_PNTR.


    # It as subroutine, but interrupts are diabled
    # di 
    # Load read and write pointers to check if the buffer is empty
    ldm M $NET_RCV_READ_PNTR  
    ldm L $NET_RCV_WRITE_PNTR 
    # Test if M (read_ptr) equals L (write_ptr).
    # If equal, buffer is empty, status bit will be SET.
    # If not equal, buffer has data, status bit will be CLEARED.
    tste M L 
       # Jump to handle empty buffer case if status bit is SET (M == L)
    jmpt :read_nic_msg_buffer_empty 

    # Buffer is not empty (status bit is CLEARED from tste M L)
    # Load current read offset into I for indexed addressing
    ldm I $NET_RCV_READ_PNTR      

    # Read src_addr (first byte of message) into A
    ldx A $NET_RCV_BUFFER_ADRES   

    # Increment local index I, wrap it, and read data_value (second byte) into B
    addi I 1
    andi I ~net_rcv_buffer_wrap
    ldx B $NET_RCV_BUFFER_ADRES   

    # Increment local index I, wrap it, and read service_id (third byte) into C
    addi I 1
    andi I ~net_rcv_buffer_wrap
    ldx C $NET_RCV_BUFFER_ADRES   

    # Advance the main $NET_RCV_READ_PNTR by the full message_size
    # Reload original read pointer into M
    ldm M $NET_RCV_READ_PNTR      
    # Add message_size (3)
    addi M ~net_rcv_message_size  
    # Wrap the main read pointer
    andi M ~net_rcv_buffer_wrap   
    # Store the updated main read pointer
    sto M $NET_RCV_READ_PNTR      

    # Status bit is already CLEARED, indicating a message was read.
    jmp :read_nic_msg_end

:read_nic_msg_buffer_empty
    # Buffer is empty (status bit is SET from tste M L).
    # Set A to \null to indicate no message.
    ldi A \null
    # B and C are undefined in this case.

:read_nic_msg_end
    # Enable interrupts
    # ei
ret
