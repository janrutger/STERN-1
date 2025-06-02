

# Define a buffer for incoming network messages

. $NET_RCV_BUFFER 64
equ ~net_rcv_buffer_wrap 63
equ ~net_rcv_message_size 3

. $NET_RCV_BUFFER_ADRES 1
. $NET_RCV_READ_PNTR 1
. $NET_RCV_WRITE_PNTR 1


#. $NET_RCV_EXPECTED_PACKET_NUM 1 ; Replaced by per-source table
; Define maximum number of NICs we can track sequence numbers for
; Table to store expected packet number for each source NIC
equ ~MAX_NICS 4 
. $NET_RCV_EXPECTED_PACKET_NUM_TABLE 4

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

    # Initialize per-source expected packet number table to 0
    # Assumes Z register is 0
    ldi I $NET_RCV_EXPECTED_PACKET_NUM_TABLE 
    ; I = base address of table
    ldi C ~MAX_NICS                          
    ; C = loop counter
:init_expected_num_loop
    tste Z C                                   
    ; If C is zero, done
    jmpt :init_expected_num_loop_end
    stx Z $mem_start                                  
    addi I 1                                 
    ; Move to next entry in table
    subi C 1                                 
    ; Decrement counter
    jmp :init_expected_num_loop
:init_expected_num_loop_end
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
    # Received packetnumber is in A (passed by interrupt mechanism)
    # Store it in K (K will hold the received_packet_num)
    ld K A

    # Get Source NIC ID from NIC register
    ; Y now holds the source_nic_id
    ldi I ~src_adres
    ldx Y $NIC_baseadres 

    # Validate Source ID (Y) against ~MAX_NICS
    ldi X ~MAX_NICS      
    ; Load MAX_NICS into X for comparison (M is used later)
    tstg Y X             
    ; Test if Y >= MAX_NICS (S > X-1 is true if Y is out of bounds)
    jmpt :_read_nic_isr_invalid_source 
    ; If Y is out of bounds, handle it

    # Get Expected Packet Number for this Source (Y)
    # M will hold the expected_packet_num for source Y
    ldi I $NET_RCV_EXPECTED_PACKET_NUM_TABLE 
    ; I = base address of table
    add I Y                                  
    ; I = address of table[Y] (I now points to the specific entry)
    ldx M $mem_start                                  
    ; M = expected_packet_num for source Y

    # Compare received_packet_num (K) with source-specific expected_packet_num (M)
    tste K M 
    jmpt :_read_nic_isr_handle_expected_src  
    ; K == M (Expected packet)
    tstg M K
    jmpt :_read_nic_isr_send_ack_old_src     
    ; K < M (Old packet)
    jmp :_read_nic_isr_handle_out_of_sequence_src 
    ; K > M (Out of sequence)


:_read_nic_isr_handle_expected_src
    # K = received_packet_num, Y = src_nic_id, M = expected_packet_num_for_Y (K==M here)
    # I = pointer to NET_RCV_EXPECTED_PACKET_NUM_TABLE[Y]

    sto M $tmpstore 
    ; Save M (current expected_packet_num, which is K) as buffer check uses M

    # --- Check if buffer is full ---
    ldm X $NET_RCV_WRITE_PNTR   
    ; Use X for write_ptr to avoid clobbering M yet
    ldm L $NET_RCV_READ_PNTR     
    tste L X 
    # Test if L (read_ptr) == X (write_ptr)
    jmpt :read_nic_isr_buffer_empty 
:read_nic_isr_buffer_not_empty
    sub L X 
    # L = L_read_ptr - X_write_ptr
    addi L 64                       
    andi L ~net_rcv_buffer_wrap     
    jmp :read_nic_isr_check_space
:read_nic_isr_buffer_empty
    ldi L 64                        
:read_nic_isr_check_space
    ldi X ~net_rcv_message_size     
    ; Use X for message_size
    tstg X L 
    # Test if message_size (X) > available_bytes (L)
    jmpt :_read_nic_isr_buffer_full_src 
    ; Jump if buffer is full for this message

    # Buffer has space: Write to network buffer
    call @write_to_networkbuffer
    ; K still holds received_packet_num. S still holds src_id. J points to table[S].

    # Send ACK for received packet K to source Y
    ldi I ~packetnumber
    stx K $NIC_baseadres
    ld A Y 
    ; Destination for ACK is the original sender
    ldi B ~ack
    call @write_ack_message

    # Increment expected_packet_num for this source Y
    # I was clobbered by write_to_networkbuffer, so recompute it.
    # Y should still hold src_nic_id at this point.
    ldi I $NET_RCV_EXPECTED_PACKET_NUM_TABLE
    add I Y         
    ; I now points to table[Y] again
    addi K 1         
    ; K now holds new_expected_packet_num for source Y
    stx K $mem_start          
    ; Store new_expected_packet_num in table[Y] (I still points there)
    jmp :read_nic_isr_end

:_read_nic_isr_buffer_full_src
    # Buffer is full. Send NACK for the *expected* packet number for this source.
    ldm M $tmpstore 
    ; Restore M to original expected_packet_num (which was K)
    ldi I ~packetnumber
    stx M $NIC_baseadres 
    ; Send NACK for M (the expected packet number)

    ld A Y 
    ; Destination for NACK is the original sender
    ldi B ~nack
    call @write_ack_message
    jmp :read_nic_isr_end

:_read_nic_isr_send_ack_old_src
    # K = received_packet_num (which is < expected M for this source Y)
    # Resend ACK for the old packet K to source Y.
    ldi I ~packetnumber
    stx K $NIC_baseadres
    ld A Y 
    ; Destination for ACK is the original sender
    ldi B ~ack
    call @write_ack_message
    jmp :read_nic_isr_end

:_read_nic_isr_handle_out_of_sequence_src
    # K = received_packet_num (which is > expected M for this source Y)
    # Discard message, send NORESEND with the *expected* packet number (M) for source Y
    ldi I ~packetnumber
    stx M $NIC_baseadres 
    ; Send NORESEND for M (the expected packet number)
    ld A Y 
    ; Destination for NORESEND is the original sender
    ldi B ~noresend 
    #ldi B ~nack ; Sending a ~nack is creating and ACK-traffic storm
    call @write_ack_message
    jmp :read_nic_isr_end

:_read_nic_isr_invalid_source
    # Source ID (Y) was out of range for NET_RCV_EXPECTED_PACKET_NUM_TABLE.
    # Currently, we just ignore this packet and clear NIC status.
    # More sophisticated error handling could be added here if needed.
    # For example, logging an error or sending a specific error message if the protocol supported it.
    # For now, it falls through to read_nic_isr_end.

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
#
# is called by the networkdispatcher and is is running as Interrupt


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
ret
