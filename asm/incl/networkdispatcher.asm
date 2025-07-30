## Network Message Dispatcher and Service Handlers

. $SERVICE_JUMP_TABLE 2             
% $SERVICE_JUMP_TABLE  @service_handler_0 @service_handler_echo
. $SERVICE_JUMP_TABLE_ADRES 1
% $SERVICE_JUMP_TABLE_ADRES $SERVICE_JUMP_TABLE

. $MAX_SERVICE_ID 1                 
% $MAX_SERVICE_ID 1

; --- Service 0 Data Buffers (Per-Process) ---
equ ~MAX_PROCESSES 5
equ ~SERVICE0_BUFFER_SIZE 16
equ ~SERVICE0_BUFFER_MASK 15 ; for andi operation (size - 1)

; --- Buffers ---
. $SERVICE0_DATA_BUFFER_P0 16 ; ~SERVICE0_BUFFER_SIZE
. $SERVICE0_DATA_BUFFER_P1 16 ; ~SERVICE0_BUFFER_SIZE
. $SERVICE0_DATA_BUFFER_P2 16 ; ~SERVICE0_BUFFER_SIZE
. $SERVICE0_DATA_BUFFER_P3 16 ; ~SERVICE0_BUFFER_SIZE
. $SERVICE0_DATA_BUFFER_P4 16 ; ~SERVICE0_BUFFER_SIZE

; --- Jump table to get buffer base address ---
. $SERVICE0_DATA_BUFFER_JUMP_TABLE 5 ; ~MAX_PROCESSES
% $SERVICE0_DATA_BUFFER_JUMP_TABLE $SERVICE0_DATA_BUFFER_P0 $SERVICE0_DATA_BUFFER_P1 $SERVICE0_DATA_BUFFER_P2 $SERVICE0_DATA_BUFFER_P3 $SERVICE0_DATA_BUFFER_P4

; --- Read/Write Pointers (one for each process) ---
. $SERVICE0_WRITE_PNTRS 5 ; ~MAX_PROCESSES
. $SERVICE0_READ_PNTRS  5 ; ~MAX_PROCESSES
% $SERVICE0_WRITE_PNTRS 0 0 0 0 0
% $SERVICE0_READ_PNTRS  0 0 0 0 0

. $_sh0_temp_buffer_base 1 ; temp var for service handler 0

@network_message_dispatcher
    call @read_nic_message      ; NOTE: MAYBE an SYSCALL
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
    callx $mem_start        ; starting the service routine

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
    ; Decodes PID from payload, stores value in the correct process buffer.
    ; Payload = (value * 10) + pid (where pid is 0-4)
    ; If a buffer is full, it discards the oldest item.

    ; --- Decode PID and Value ---
    ldi K 10                    ; K = 10
    dmod B K                    ; B = B / 10 (value), K = B % 10 (pid)
    ; Now B holds the value to store, K holds the target PID.

    ; --- Validate PID (in K) ---
    ld M K                      ; M = PID
    ldi L ~MAX_PROCESSES        ; L = 5
    tstg L M                    ; is ~MAX_PROCESSES > PID? (i.e. is PID < 5)
    jmpf :_sh0_invalid_pid      ; if not, pid is invalid.

    ; --- Get pointers for the PID in K ---
    ld I K ; I = PID
    ldx M $SERVICE0_WRITE_PNTRS ; M = write_pntr[pid]
    ldx L $SERVICE0_READ_PNTRS  ; L = read_pntr[pid]

    ; --- Check if buffer is full ---
    ; (write_pointer + 1) % size == read_pointer (for the specific PID)
    ld C M                      ; C = current write_pointer
    addi C 1                    ; C = potential next write_pointer
    andi C ~SERVICE0_BUFFER_MASK ; C = (potential next write_pointer) % size
    tste C L                    ; Is (next_write_pntr) == read_pntr?
    jmpt :_sh0_buffer_is_full   ; If true, buffer is full

:_sh0_proceed_with_write
    ; Buffer is not full OR space has been made.
    ; --- Write the value (in B) to the correct buffer ---
    ld I K ; I = PID (from K)
    ldx L $SERVICE0_DATA_BUFFER_JUMP_TABLE ; L = base address of buffer for PID
    sto L $_sh0_temp_buffer_base ; Store base address in temp var

    ld I K ; I = PID
    ldx C $SERVICE0_WRITE_PNTRS ; C = write offset for PID
    ld I C ; Load offset into I for stx
    stx B $_sh0_temp_buffer_base ; M[base_addr + offset] = value

    ; --- Increment and update the write pointer for the PID ---
    ld I K ; I = PID (from K)
    ldx C $SERVICE0_WRITE_PNTRS ; C = current write_pntr[pid]
    addi C 1
    andi C ~SERVICE0_BUFFER_MASK
    stx C $SERVICE0_WRITE_PNTRS ; write_pntr[pid] = new pointer
ret

:_sh0_buffer_is_full
    ; Buffer is full. Advance the read pointer for this PID to discard the oldest item.
    ld I K ; I = PID
    ldx L $SERVICE0_READ_PNTRS ; L = current read_pntr[pid]
    addi L 1
    andi L ~SERVICE0_BUFFER_MASK
    stx L $SERVICE0_READ_PNTRS ; read_pntr[pid] = new pointer
    jmp :_sh0_proceed_with_write

:_sh0_invalid_pid
    ; The PID decoded from the packet (in K) is out of range.
    ; This is a protocol error. For now, just return without doing anything.
ret


@service_handler_echo
    ; Service 1: Echo service
    ; Called with A = src_addr (this becomes destination for echo)
    ;             B = data_to_echo
    ;             C = service_id (which is 1)

    ; This service handler runs in kernel mode. It can directly call other
    ; kernel routines like @send_nic_message to queue a reply.
    ; A user process would need to use a SYSCALL to achieve the same result.
    ;
    ; A should be dst_addr (it's already the incoming src_addr)
    ; B should be data (it's already the incoming data)
    ; C should be the service_id for the *outgoing* packet.
    ; We send the echo back with service_id 0, the standard reply service.
    ldi C 0 
    call @send_nic_message

ret

. $_rs0d_temp_buffer_base 1 ; temp var for read service 0

@read_service0_data
    ; Reads a byte from the appropriate SERVICE0_DATA_BUFFER for the PID in A.
    ; Expects:
    ;   In Register A: The PID of the calling process.
    ; Returns:
    ;   In Register A: data byte if available. (Content of A is undefined if buffer is empty)
    ;   Status bit: 1 if data was read and is in A.
    ;               0 if buffer is empty.

    ; Disable interrupts to ensure atomic access to pointers
    di 

    ; Save calling PID from A into K for later use
    ld K A ; K = PID

    ; --- Validate PID ---
    ldi M ~MAX_PROCESSES
    tstg M K ; Is ~MAX_PROCESSES > K? (i.e. is K < ~MAX_PROCESSES)
    jmpf :_rs0d_invalid_pid_or_empty

    ; --- Get pointers for the PID in K ---
    ld I K ; I = PID
    ldx M $SERVICE0_READ_PNTRS  ; M = read_pntr[K]
    ldx L $SERVICE0_WRITE_PNTRS ; L = write_pntr[K]

    ; --- Is buffer empty? ---
    tste M L
    ; If M == L (empty), tste sets status bit to 1.
    jmpt :_rs0d_buffer_empty ; Jump if status bit is 1 (buffer is empty)

    ; --- Buffer is not empty, data is available for PID in K ---
    ; Get buffer base address for PID
    ld I K
    ldx C $SERVICE0_DATA_BUFFER_JUMP_TABLE ; C = base address of buffer for PID
    sto C $_rs0d_temp_buffer_base

    ; Get read offset (for PID in K) and read data into A
    ld I K
    ldx L $SERVICE0_READ_PNTRS ; L = read offset for PID
    ld I L ; Load offset into I for ldx
    ldx A $_rs0d_temp_buffer_base ; A = M[base_addr + offset] (the data)

    ; --- Increment and update the read pointer for the PID (in K) ---
    ld I K ; I = PID
    ldx M $SERVICE0_READ_PNTRS ; M = current read_pntr[K]
    addi M 1
    andi M ~SERVICE0_BUFFER_MASK
    stx M $SERVICE0_READ_PNTRS ; read_pntr[K] = new pointer

    ; Set status bit to 1 (data available)
    ldi M 1 
    tst M 1 
    jmp :_rs0d_done

:_rs0d_invalid_pid_or_empty
:_rs0d_buffer_empty
    ; Set status bit to 0 to indicate buffer empty.
    ldi M 0 
    tst M 1 

:_rs0d_done
    ; Enable interrupts
    ei 
ret