

# Define a buffer for incoming network messages
. $NET_RCV_BUFFER 64
equ ~net_rcv_buffer_wrap 63

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
equ ~packetnumbber 8

equ ~service_id_out 9   
equ ~service_id_in 10   

equ ~data_type  0
equ ~ack_type  1

equ ~idle  0
equ ~ack   0
equ ~nack  1
equ ~noresend 2 


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
    nop
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
    # A software ring buffer is full if the next write position
    # (write_pointer + 1) % BUFFER_SIZE would be equal to the read_pointer.
    ldm M $NET_RCV_WRITE_PNTR
    addi M 1
    # Assuming buffer size is 16
    andi M ~net_rcv_buffer_wrap 
    ldm L $NET_RCV_READ_PNTR
    tste M L
    # If buffer is full, jump to skip storing the packet.
    # The NIC will be NACK the packet.
    jmpt :skip_packet_storage_due_to_full_buffer

    call @write_to_networkbuffer
    
    
    # Send a ack
    # This point the data is stored, 
    # and send a ACK to the sender 
    ldi I ~packetnumbber
    stx K $NIC_baseadres

    # A-reg  contains the dst-adres
    
    ldi B ~ack

    call @write_ack_message

    addi K 1
    sto K $NET_RCV_EXPECTED_PACKET_NUM
    jmp :read_nic_isr_end

# resend ACK on earlier processed message
:send_ack_on_old_message
    ldi I ~packetnumbber
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
    ldi I ~packetnumbber
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
    ldi I ~packetnumbber
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


# and a routine to read from the NIC buffer
# return next message in A 
@read_nic_message
    # It as subroutine, but interrupts are diabled
    # return \null when no message is waiting
    di 
    # check for empty buffer
    ldm M $NET_RCV_READ_PNTR  
    ldm L $NET_RCV_WRITE_PNTR 
    tste M L 
    jmpt :no_message
        ; Buffer not empty
        ; I = old $NET_RCV_READ_PNTR value, $NET_RCV_READ_PNTR is incremented in memory
        inc I $NET_RCV_READ_PNTR    
        ldx A $NET_RCV_BUFFER_ADRES

        ; Wrap-around for $NET_RCV_READ_PNTR
        ; M = new $NET_RCV_READ_PNTR value
        ldm M $NET_RCV_READ_PNTR  
        ; M = (new $NET_RCV_READ_PNTR) % 16  
        andi M ~net_rcv_buffer_wrap   
        ; Store the wrapped pointer value back              
        sto M $NET_RCV_READ_PNTR    
        jmp :end_read_nic_message_logic
    
    :no_message
        ldi A \null

:end_read_nic_message_logic 
    
    ei
ret




@write_to_networkbuffer
 # Buffer is not full. Proceed to read from NIC and store the data.
    # Read source address
    # Store source address in A is the destination for ack/nack 
    # Note: The current implementation only stores the data byte (from B)
    # in the ring buffer. The source address (A) is read but not stored.
    ldi I ~src_adres
    ldx A $NIC_baseadres 

    # Read data byte
    # Store data in B (or elsewhere)
    ldi I ~data_in
    ldx B $NIC_baseadres 

    # Read Service ID from NIC
    ldi I ~service_id_in
    ldx C $NIC_baseadres 

    # packetnumber is still in K  

    # --- Store data in buffer (Example: store data only) ---
    # This part needs refinement based on how you want to store packets
    # (e.g., store source addr then data, or just data?)
    # Store data (from B) into buffer

    # The 'inc I $address' instruction, as you described:
    # 1. Loads the value from memory at $address into register I.
    # 2. Increments the value in memory at $address.
    inc I $NET_RCV_WRITE_PNTR
    # Register I now holds the original write pointer (the index for storing).
    # The $NET_RCV_WRITE_PNTR variable in memory has been incremented.
    # Store data byte B at the buffer location indicated by I.
    stx B $NET_RCV_BUFFER_ADRES 

    # Finalize the $NET_RCV_WRITE_PNTR update in memory:
    # Load the (already incremented by 'inc I') write pointer from memory.
    ldm M $NET_RCV_WRITE_PNTR
    # Assuming buffer size is 16
    # Apply modulo operation for wrap-around.
    andi M ~net_rcv_buffer_wrap 
    # Store potentially wrapped pointer
    sto M $NET_RCV_WRITE_PNTR 

ret