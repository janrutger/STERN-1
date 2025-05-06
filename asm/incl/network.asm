

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
    ldm M $NET_RCV_WRITE_PNTR
    addi M 1
    # Assuming buffer size is 16
    andi M 15 
    ldm L $NET_RCV_READ_PNTR
    tste M L
    # If full, maybe just drop packet?
    jmpt :net_buffer_full 

    # Read source address
    # Store source address in A (or elsewhere)
    ldi I ~src_adres
    ldx A $NIC_baseadres 

    # Store data in B (or elsewhere)
    ldi I ~data_in
    ldx B $NIC_baseadres 

    # --- Store data in buffer (Example: store data only) ---
    # This part needs refinement based on how you want to store packets
    # (e.g., store source addr then data, or just data?)
    # Store data (from B) into buffer
    inc I $NET_RCV_WRITE_PNTR
    stx B $NET_RCV_BUFFER_ADRES 

    # Check for buffer wrap-around
    ldm M $NET_RCV_WRITE_PNTR
    # Assuming buffer size is 16
    andi M 15 
    # Store potentially wrapped pointer
    sto M $NET_RCV_WRITE_PNTR 

    # Acknowledge receipt to NIC by clearing status
    ldi M 0
    ldi I ~receive_status
    stx M $NIC_baseadres

# Label for buffer full case (optional)
:net_buffer_full 
rti


# and a routine to read from the NIC buffer
# return next message in A 
@read_nic_message
    # It as subroutine, but interrupts are diabled
    # return \null when no message is waiting
    di 
    # check for empty buffer
    ldm I $NET_RCV_READ_PNTR
    ldm M $NET_RCV_WRITE_PNTR   
    tste I M 
    jmpt :no_message
        # when not empty, read buffer to a
        ldx A $NET_RCV_BUFFER_ADRES

        addi I 1
        sto I $NET_RCV_READ_PNTR

        # check for last adres in buffer
        # check modulo 16, by andi 15
        ldm M $NET_RCV_READ_PNTR
        andi M 15
        # cycle to 0 when mod = 0
        tste M Z
        jmpf :end_read_nic_message
            sto Z $NET_RCV_READ_PNTR 
            jmp :end_read_nic_message  
    
    :no_message
        ldi A \null

:end_read_nic_message 
    
    ei
ret