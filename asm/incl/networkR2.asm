

# Define a buffer for incoming network messages
. $NET_RCV_BUFFER 16 
. $NET_RCV_BUFFER_ADRES 1
. $NET_RCV_READ_PNTR 1
. $NET_RCV_WRITE_PNTR 1
. $NET_RCV_EXPECTED_SEQ_NUM 1 # Stores the next expected packet sequence number

equ ~receive_status 0
equ ~src_adres 1
equ ~data_in 2

equ ~send_status 3
equ ~dst_adres 4
equ ~data_out 5

equ ~ack_status 6
equ ~message_type 7
equ ~packetnumbber 8

equ ~data_type  0
equ ~ack_type  1

equ ~idle  0
equ ~ack   0
equ ~nack  1




@init_nic_buffer
# --- Maybe add buffer init code to loader ---
    ldi Z 0
    sto Z $NET_RCV_READ_PNTR
    sto Z $NET_RCV_WRITE_PNTR
    sto Z $NET_RCV_EXPECTED_SEQ_NUM ; Initialize expected sequence number to 0
    ldi M $NET_RCV_BUFFER
    sto M $NET_RCV_BUFFER_ADRES
ret


# write data to nic, ~send_status=1
# wait for ACK ~send_status=0
@write_data_message_isr
@write_nic_isr
    # expects dest-adres in A 
    # expects data to send in B 

    ldi I ~dst_adres
    stx A $NIC_baseadres

    ldi M ~data_type
    ldi I ~message_type
    stx M $NIC_baseadres

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
    ld C A ; C = incoming_packet_seq_num (from NIC, A is clobbered by ldx)

    ldm M $NET_RCV_EXPECTED_SEQ_NUM ; M = expected_seq_num
    tste M C ; Test if incoming_seq_num (C) == expected_seq_num (M)
    jmpf :handle_out_of_sequence_packet

; :handle_in_sequence_packet (implicit label if tste M C is true)
    ; Packet is the one we expect. Check buffer.
    ldm X $NET_RCV_WRITE_PNTR ; X = current_write_ptr
    ldm Y $NET_RCV_READ_PNTR  ; Y = current_read_ptr

    ld K X ; K = current_write_ptr
    addi K 1
    andi K 15 ; K = (current_write_ptr + 1) % 16 (potential next_write_ptr)
    
    tste K Y ; Test if (write_ptr + 1) % 16 == read_ptr (buffer full)
    jmpt :buffer_full_for_in_sequence_packet ; Buffer is full

    ; Buffer not full, store the in-sequence packet
    ; Get sender's address for ACK
    ldi I ~src_adres
    ldx A $NIC_baseadres ; A = sender's address (destination for ACK)

    ; Get data byte
    ldi I ~data_in
    ldx B $NIC_baseadres ; B = data byte to store

    ; Store data B into buffer at index X (current_write_ptr)
    ldm L $NET_RCV_BUFFER_ADRES ; L = base address of the actual buffer
    add L X                     ; L = absolute address to write to (base + current_write_index X)
    st B L                      ; Store B into M[L]

    ; Update $NET_RCV_WRITE_PNTR to K (which is (original_write_ptr + 1) % 16)
    sto K $NET_RCV_WRITE_PNTR

    ; Increment expected sequence number (M still holds $NET_RCV_EXPECTED_SEQ_NUM)
    addi M 1
    ; Assuming sequence numbers can be > 15, handle wrap-around based on actual max sequence number.
    ; If sequence numbers are e.g. 0-255, then 'addi M 1' will naturally wrap in an 8-bit context.
    ; If M is a word and sequence numbers are smaller, an ANDI might be needed.
    ; For now, assume sequence numbers fit and wrap appropriately for the protocol.
    sto M $NET_RCV_EXPECTED_SEQ_NUM

    ; Send ACK for the received packet (C contains its sequence number)
    ; A already has dst_adres for ACK
    mov L B              ; Save data B in L if needed, B will be used for ack_type
    ldi B ~ack           ; B = ACK type for @write_ack_message
    
    ldi I ~packetnumbber
    stx C $NIC_baseadres ; Set packet number for ACK (original incoming seq_num C)
    
    call @write_ack_message ; write_ack_message expects dest in A, type in B
    jmp :clear_nic_and_rti

:buffer_full_for_in_sequence_packet
    ; Expected packet (C) arrived, but buffer is full. Send NACK for it.
    ; M still holds $NET_RCV_EXPECTED_SEQ_NUM (which is equal to C here)
    ldi I ~src_adres
    ldx A $NIC_baseadres ; A = sender's address (for NACK destination)
    ldi B ~nack          ; B = NACK type
    
    ldi I ~packetnumbber
    stx C $NIC_baseadres ; Set packet number for NACK (the one that just arrived, C)

    call @write_ack_message
    jmp :clear_nic_and_rti

:handle_out_of_sequence_packet
    ; Incoming packet C is not $NET_RCV_EXPECTED_SEQ_NUM (M)
    ; Discard this packet.
    ; Send NACK for the *expected* sequence number (M) to inform the sender.
    ldi I ~src_adres
    ldx A $NIC_baseadres ; A = sender's address (for NACK destination)
    ldi B ~nack
    
    ; Packet number for NACK should be $NET_RCV_EXPECTED_SEQ_NUM (which is in M)
    ldi I ~packetnumbber
    stx M $NIC_baseadres ; NACKing the one we EXPECT (M)

    call @write_ack_message
    ; Fall through to :clear_nic_and_rti

:clear_nic_and_rti
    ; Clear the NIC's receive status to indicate this packet event has been handled
    ; Ensure M is not needed beyond this point or use a different register
    ldi M 0
    ldi I ~receive_status
    stx M $NIC_baseadres
    
:read_nic_isr_end
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