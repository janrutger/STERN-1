## Network Message Dispatcher and Service Handlers

. $SERVICE_JUMP_TABLE 2             
% $SERVICE_JUMP_TABLE  @service_handler_0 @service_handler_echo
. $SERVICE_JUMP_TABLE_ADRES 1
% $SERVICE_JUMP_TABLE_ADRES $SERVICE_JUMP_TABLE

. $MAX_SERVICE_ID 1                 
% $MAX_SERVICE_ID 1

; Buffer for data received by service 0 (16 positions)
. $SERVICE0_DATA_BUFFER 16      
. $SERVICE0_WRITE_PNTR 1        
. $SERVICE0_DATA_BUFFER_ADRES 1
% $SERVICE0_WRITE_PNTR 0 

. $SERVICE0_READ_PNTR 1         
% $SERVICE0_READ_PNTR 0        

% $SERVICE0_DATA_BUFFER_ADRES $SERVICE0_DATA_BUFFER


@network_message_dispatcher
    call @read_nic_message
    ; Expects from @read_nic_message:
    ; A = src_addr, B = data, C = service_id.
    ; Status bit:
    ;   - SET (true) if the buffer was empty (A will be \null).
    ;   - CLEARED (false) if a message was successfully read.

    ; Jump if status bit is SET (true), meaning no message was read
    jmpt :nmd_no_message 

    ; Validate service_id (C)
    ldm M $MAX_SERVICE_ID
    tstg C M
    jmpt :nmd_invalid_service_id 
    
    ld I C
    ldx M $SERVICE_JUMP_TABLE_ADRES

    ld I M 
    callx $mem_start

    # After the service handler successfully returns,
    # jump to the dispatcher's exit point.
    jmp :nmd_no_message

:nmd_invalid_service_id
    ; Optional: Handle invalid service ID (e.g., log error, send NACK)
    ; For now, we just call fatal error.
    call @fatal_error

:nmd_no_message
ret


@service_handler_0
; Called with A = src_addr, B = data, C = service_id (which is 0)
    ; Stores only the data (from B) into a ring buffer.
    ; If the buffer is full, it advances the read pointer, discarding the oldest item,
    ; to make space for the new item, thus keeping the most recent data in order.

    ; Check if the buffer is full.
    ; A buffer is full if (write_pointer + 1) % size == read_pointer.

    ldm M $SERVICE0_WRITE_PNTR  
    ldm L $SERVICE0_READ_PNTR   

    ; K = current write_pointer (copy for calculation)
    ; K = potential next write_pointer
    ; K = (potential next write_pointer) % 16
    ld K M                      
    addi K 1                    
    andi K 15                   

    ; Is (next_write_pntr) == read_pntr?
    ; If true, buffer is full
    tste K L                    
    jmpt :s0_buffer_is_full     

:s0_proceed_with_write
    ; Buffer is not full OR space has been made.
    ; Get current write pointer value into I, and increment it in memory
    inc I $SERVICE0_WRITE_PNTR

    ; Store data (B) using I as the index
    stx B $SERVICE0_DATA_BUFFER_ADRES      

    ; Finalize the $SERVICE0_WRITE_PNTR update in memory (wrap-around)
    ldm M $SERVICE0_WRITE_PNTR
    andi M 15 
    sto M $SERVICE0_WRITE_PNTR
ret

:s0_buffer_is_full
    ; Buffer is full. Advance the read pointer to discard the oldest item.
    ; inc I $SERVICE0_READ_PNTR will load current read_pntr into I and inc in memory
    inc I $SERVICE0_READ_PNTR   
    ldm M $SERVICE0_READ_PNTR   
    andi M 15               
    ; Store wrapped new read_pntr    
    sto M $SERVICE0_READ_PNTR   

    ; Now proceed to write the new data
    jmp :s0_proceed_with_write  




@service_handler_echo
    ; Service 1: Echo service
    ; Called with A = src_addr (this becomes destination for echo)
    ;             B = data_to_echo
    ;             C = service_id (which is 1)

    ; Prepare for @send_data_packet_sub:
    ; A should be dst_addr (it's already the incoming src_addr)
    ; B should be data (it's already the incoming data)
    ; C should be the service_id for the *outgoing* packet.
    ; Let's send the echo back with service_id 0 (targeting "current program" on the sender).
    ldi C 0 
    call @send_data_packet_sub 
ret




## helpers


# Subroutine to send a data packet
# Similar to @write_data_message_isr but ends with 'ret'
@send_data_packet_sub
    # expects dest-adres in A 
    # expects data to send in B 
    # expects service_id in C (for outgoing packet)

    ldi I ~dst_adres
    stx A $NIC_baseadres

    ldi M ~data_type
    ldi I ~message_type
    stx M $NIC_baseadres

    ldi I ~service_id_out  
    stx C $NIC_baseadres

    ldi I ~data_out
    stx B $NIC_baseadres

    # set send status to 1
    ldi M 1
    ldi I ~send_status
    stx M $NIC_baseadres
    # wait for NIC to acknowledge it has taken the data
    :wait_for_nic_sending_ack_sub
        ldi I ~send_status
        ldx M $NIC_baseadres
        # check for ACK (status becomes 0)
        tst M 0
    jmpf :wait_for_nic_sending_ack_sub
ret


@read_service0_data
    ; Reads a byte from the SERVICE0_DATA_BUFFER.
    ; Returns:
    ;   In Register A: data byte if available. (Content of A is undefined if buffer is empty and status bit is 0)
    ;   Status bit: 1 if data was read and is in A.
    ;               0 if buffer is empty.
    ; This routine should be called from the main program.
    ; It is the consumer for data produced by @service_handler_0.

    ; Disable interrupts to ensure atomic access to pointers
    di 

    ldm M $SERVICE0_READ_PNTR  
    ldm L $SERVICE0_WRITE_PNTR 

    ; Is read_pointer == write_pointer?
    tste M L 
        ; If M == L (empty), tste sets status bit to 1.
        ; If M != L (data), tste sets status bit to 0.

    ; Jump if status bit is 1 (meaning M == L, buffer is empty)
    jmpt :s0_buffer_empty_set_status 

    ; Buffer is not empty, data is available
    ; I = old $SERVICE0_READ_PNTR value, $SERVICE0_READ_PNTR is incremented in memory
    inc I $SERVICE0_READ_PNTR
    ldx A $SERVICE0_DATA_BUFFER_ADRES 
    
    ; Wrap-around for $SERVICE0_READ_PNTR (which is already incremented in memory)
    ldm M $SERVICE0_READ_PNTR
    andi M 15              
    ; Store the wrapped pointer value back       
    sto M $SERVICE0_READ_PNTR     

    ; Set status bit to 1 (data available)
    ldi M 1 
    ; Sets status bit to 1 because M (1) is not equal to 0.
    tst M 1 
    jmp :s0_read_done

:s0_buffer_empty_set_status
    ; We jumped here because M == L, and tste M L set the status bit to 1.
    ; We need to set status bit to 0 to indicate buffer empty.
    ldi M 0 
    ; Sets status bit to 0 because M (0) is equal to 0.
    tst M 1 
    ; Register A's content is not guaranteed here / can be considered garbage.

:s0_read_done
    ; Enable interrupts
    ei 
ret