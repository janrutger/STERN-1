## Network Message Dispatcher and Service Handlers

. $SERVICE_JUMP_TABLE 2             
% $SERVICE_JUMP_TABLE @service_handler_0 @service_handler_echo
. $MAX_SERVICE_ID 1                 
% $MAX_SERVICE_ID 1

; Buffer for data received by service 0 (16 positions)
. $SERVICE0_DATA_BUFFER 16      
. $SERVICE0_WRITE_PNTR 1        
. $SERVICE0_DATA_BUFFER_ADRES 1
% $SERVICE0_DATA_BUFFER_ADRES $SERVICE0_DATA_BUFFER

;. $temp_src_addr 1    
;. $temp_data 1
;. $temp_service_id 1

@network_message_dispatcher
    call @read_nic_message
    ; Expects from @read_nic_message:
    ; A = src_addr, B = data, C = service_id.
    ; If no message, A = \null.

    tst A \null
    jmpt :nmd_no_message 

    ; Message received. Store details temporarily.
    ; sto A $temp_src_addr
    ; sto B $temp_data
    ; sto C $temp_service_id

    ; Validate service_id (C)
    ldm M $MAX_SERVICE_ID
    tstg C M
    jmpt :nmd_invalid_service_id 

    ; C = service_id, which is the index for the jump table.
    ; Get the handler address from the jump table.
    ; ldi L $SERVICE_JUMP_TABLE   ; L = base address of jump table
    ; add L C                     ; L = address of the specific service handler pointer in the table
    ; ldx K L                     ; K = actual address of the service handler routine
    
    ld I C
    ldx M $SERVICE_JUMP_TABLE
    ld I M 

    ; Prepare registers for the service call:
    ; A = src_addr, B = data, C = service_id
    ; ldm A $temp_src_addr
    ; ldm B $temp_data
    ; ldm C $temp_service_id      ; Pass original service_id to handler

    ; Index in I
    callx $mem_start
:nmd_invalid_service_id
    ; Optional: Handle invalid service ID (e.g., log error, send NACK)
    ; For now, we just call fatal error.
    call @fatal_error
:nmd_no_message
ret


@service_handler_0
    ; Service 0: Reserved for the "current program"
    ; Called with A = src_addr, B = data, C = service_id (which is 0)
    ; Stores only the data (from B) into a ring buffer.
    ; No buffer full check is performed.

    ; Get current write pointer value into I, and increment it in memory
    inc I $SERVICE0_WRITE_PNTR 

    ; Store data (B) using I as the index
    stx B $SERVICE0_DATA_BUFFER_ADRES      

    # Assuming buffer size is 16, Apply modulo operation for wrap-around.
    ldm M $SERVICE0_WRITE_PNTR
    andi M 15 
    sto M $SERVICE0_WRITE_PNTR
ret

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
    call @send_data_packet_sub ; This is the new subroutine in networkR2.asm



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