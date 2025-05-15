

# Define a buffer for incoming network messages
. $NET_RCV_BUFFER 16 
. $NET_RCV_BUFFER_ADRES 1
. $NET_RCV_READ_PNTR 1
. $NET_RCV_WRITE_PNTR 1

equ ~receive_status 0
equ ~src_adres 1
equ ~data_in 2

equ ~send_status 3
equ ~dst_adres 4
equ ~data_out 5


@init_nic_buffer
# --- Maybe add buffer init code to loader ---
    ldi Z 0
    sto Z $NET_RCV_READ_PNTR
    sto Z $NET_RCV_WRITE_PNTR
    ldi M $NET_RCV_BUFFER
    sto M $NET_RCV_BUFFER_ADRES
ret


# write data to nic, ~send_status=1
# wait for ACK ~send_status=0
@write_nic_isr
    # expects dest-adres in A 
    # expects data to send in B 

    ldi I ~dst_adres
    stx A $NIC_baseadres

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
    nop
rti


# Network Receive Interrupt Service Routine
# Triggered when NIC has received data (~receive_status != 0)
@read_nic_isr
    # --- Optional: Check if buffer is full ---
    # A software ring buffer is full if the next write position
    # (write_pointer + 1) % BUFFER_SIZE would be equal to the read_pointer.
    ldm M $NET_RCV_WRITE_PNTR
    addi M 1
    # Assuming buffer size is 16
    andi M 15 
    ldm L $NET_RCV_READ_PNTR
    tste M L
    # If buffer is full, jump to skip storing the packet.
    # The NIC will still be acknowledged, and the packet dropped.
    jmpt :skip_packet_storage_due_to_full_buffer

    # Buffer is not full. Proceed to read from NIC and store the data.
    # Read source address
    # Store source address in A (or elsewhere)
    # Note: The current implementation only stores the data byte (from B)
    # in the ring buffer. The source address (A) is read but not stored.
    ldi I ~src_adres
    ldx A $NIC_baseadres 

    # Read data byte
    # Store data in B (or elsewhere)
    ldi I ~data_in
    ldx B $NIC_baseadres 

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
    andi M 15 
    # Store potentially wrapped pointer
    sto M $NET_RCV_WRITE_PNTR 

:skip_packet_storage_due_to_full_buffer
    # This point is reached whether the packet was stored or skipped (due to full buffer).
    # Crucially, we must always acknowledge the NIC to clear the current interrupt
    # and allow it to signal new incoming data in the future.
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
        andi M 15     
        ; Store the wrapped pointer value back              
        sto M $NET_RCV_READ_PNTR    
        jmp :end_read_nic_message_logic
    
    :no_message
        ldi A \null

:end_read_nic_message_logic 
    
    ei
ret