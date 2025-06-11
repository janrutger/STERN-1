; STERN-Iv2 Kernel with Process Management
;
; kernel is starting at adres 1024 and runs as PID=0
; The CPU in the Stern-I supports context switching
; cntsw <adres>  where the adres contains the next context

; --- Kernel Data Declarations ---
; max number of processes
. $MAX_PROCESSES 1
% $MAX_PROCESSES 5

; pointer to the process table
; 3584 is halfway the interupt pointers
. $PROCESS_TABLE_BASE 1
% $PROCESS_TABLE_BASE 3584

; Words per Process Table Entry: State, CPUSlotID
; . $PTE_SIZE 1
; % $PTE_SIZE 2
equ ~PTE_SIZE 2


; --- PTE Offsets (relative to start of a PTE) ---
equ ~PTE_STATE 0
equ ~PTE_CPU_SLOT_ID 1

; Stores the PID (0-4) of the currently executing process
; starts by default PID=0 (max total of 5 processes)
. $CURRENT_PROCESS_ID 1
% $CURRENT_PROCESS_ID 0

; --- Process States ---
equ ~PROC_STATE_FREE 0
equ ~PROC_STATE_READY 1
equ ~PROC_STATE_KERNEL_ACTIVE 3

; --- Syscall Numbers ---
equ ~SYSCALL_SET_PROCESS_READY 10 ; Syscall to set a process to READY state



@kernel_init
    ; from loader3.asm
    call @init_stern 

    ; Proces table starts at $PROCESS_TABLE_BASE and PTE size is ~PTE_SIZE
    call @setup_syscall_vectors
    call @init_process_table

    # init the sheduler for now: Network Message Dispatcher
    # ldi M @network_message_dispatcher
    # or scheduler_round_robin
    ldi M @scheduler_round_robin
    sto M $scheduler_routine_ptr

    ; Make process 1 ready immediately (for testing)
    ldi A 1
    int ~SYSCALL_SET_PROCESS_READY

    ; Make process 2 ready immediately (for testing)
    ldi A 2
    int ~SYSCALL_SET_PROCESS_READY

    ; This is the kernel's main work loop (for PID 0)
    ; Example: check for commands, manage system tasks, or idle.
    ; For now, it can be an idle loop.

:kernel_main_loop
    ; The rest of the main loop
    ; nop ; or some useful kernel background task
    jmp :kernel_main_loop 
halt




## INCLUDE helpers
INCLUDE stacks_runtime
INCLUDE networkdispatcher

@setup_syscall_vectors
    ; The loader (loader3.asm) already sets up the RTC ISR (Interrupt 8)
    ; and its @RTC_ISR calls the routine pointed to by $scheduler_routine_ptr,
    ; which this kernel sets to @scheduler_round_robin.

    ; Setup Set Process Ready Syscall ISR (Interrupt ~SYSCALL_SET_PROCESS_READY)
    ldi K ~SYSCALL_SET_PROCESS_READY
    ldm M $INT_VECTORS            ; M (register) = Base address of IVT (e.g. $INT_VECTORS from loader3.asm)
    add M K                       ; M (register) = IVT_base + interrupt_number. M now holds the target address.
    ldi K @_isr_set_process_ready ; K (register) = Address of the ISR routine (this is the value to store).
    ld I M                        ; Copy the target address from register M into register I (R0).
    stx K $mem_start              ; Store value from K into Memory[I] (as $mem_start is 0).
    ret


@init_process_table
    ; C is loop counter for PID
    ldi C 0 
:init_pte_loop
    ; Calculate address of PTE[C]
    ldm K $PROCESS_TABLE_BASE
    ld I C
    muli I ~PTE_SIZE
    add K I
    ; K is now base address of PTE[C]

    ; CPUSlotID = PID
    ld I K
    addi I ~PTE_CPU_SLOT_ID
    stx C $mem_start


    tst C 0 
    ; Is it PID 0 (Kernel)?
    jmpf :init_user_pte
        ; --- Initialize Kernel PTE (PID 0) ---
        ldi M ~PROC_STATE_KERNEL_ACTIVE
        ld I K
        addi I ~PTE_STATE
        stx M $mem_start 

        ; Kernel uses a pre-defined stack area, e.g. main stack or a specific kernel stack

        jmp :next_pte

:init_user_pte
    ; --- Initialize User PTE (PID 1-4) ---
    ldi M ~PROC_STATE_FREE
    ld I K
    addi I ~PTE_STATE
    stx M $mem_start 

    # the CPU knows about the entry-point (PC) and stack-base (SP)

:next_pte
    ; Loop if C < MAX_PROCESSES
    addi C 1
    ldm K $MAX_PROCESSES
    tste C K
    jmpf :init_pte_loop 
ret

; --- Scheduler Temporary Variables ---
. $sched_old_pid 1
. $sched_next_pid 1
. $sched_loop_counter 1
. $sched_candidate_pte_addr 1

; --- Scheduler ---
@scheduler_round_robin
    ; This routine is called by the RTC ISR. Interrupts are disabled at entry.
    ; interrupts already disabled
    ;di
    ; Interrupts are disabled during critical scheduling path

    ldm A $CURRENT_PROCESS_ID
    sto A $sched_old_pid

    ; --- Save current process's STACKS runtime index ---
    ; NOTE: The CPU is taking care ot the SP, the current runtime is outdated
    ; $sr_stack_idx holds the current index.
    ; Target: $PROCESS_STACK_INDICES[old_pid]
    ; ldm K $PROCESS_STACK_INDICES
    ; add K A ; K = address of $PROCESS_STACK_INDICES[old_pid]
    ; ldm M $sr_stack_idx
    ; sto M K ; Save M[$sr_stack_idx] to M[$PROCESS_STACK_INDICES + old_pid]

    ; --- Find next READY process (Round Robin) ---
    ldm C $MAX_PROCESSES
    sto C $sched_loop_counter 
    ; Max iterations to find a process
    ldm A $sched_old_pid 
    ; Start search from next PID (A will be incremented first)

:find_next_proc_loop
    ; Wrap around PID: A = (A+1) % MAX_PROCESSES
    addi A 1
    ldm K $MAX_PROCESSES
    dmod A K 
    ld A K 

    ; Get PTE for candidate process A
    ldm K $PROCESS_TABLE_BASE
    ld I A 
    ; I = candidate_pid
    muli I ~PTE_SIZE
    add K I 
    ; K = address of PTE[A]
    sto K $sched_candidate_pte_addr 
    ; Save for later

    ldm I $sched_candidate_pte_addr
    addi I ~PTE_STATE
    ldx M $mem_start
    ; M = State of candidate process

    tst M ~PROC_STATE_READY
    jmpt :found_sched_process
    tst M ~PROC_STATE_KERNEL_ACTIVE 
    ; Kernel is always "ready"
    jmpt :found_sched_process

    subi C 1 
    tst C 0
    jmpf :find_next_proc_loop 

    ; If loop finishes, no other READY process found, revert to old_pid
    ldm A $sched_old_pid
    ; Recalculate PTE address for old_pid if needed, or assume it's still valid
    ldm K $PROCESS_TABLE_BASE
    ld I A
    muli I ~PTE_SIZE
    add K I
    sto K $sched_candidate_pte_addr

:found_sched_process
    ; A holds the next_pid. $sched_candidate_pte_addr holds its PTE address.
    sto A $sched_next_pid

    ldm B $sched_old_pid
    tste A B 
    ; Is next_pid same as old_pid?
    jmpt :scheduler_no_switch

    ; --- Context Switch IS Needed ---
    ; Update $CURRENT_PROCESS_ID
    sto A $CURRENT_PROCESS_ID

    ; NOTE: Any per-process software state (e.g., STACKS pointers if not part of hardware context)
    ; for the OLD process should be saved before this point.
    ; The NEW process's software state should be restored by ctxsw or by the new process itself.
    ; The commented-out STACKS management code (related to $PROCESS_STACK_INDICES, etc.) 
    ; needs to be correctly integrated if per-process STACKS environments are used.
    ; Example of conceptual placement:
    ;   call @save_old_process_software_context ; (pass old_pid from $sched_old_pid)
    ;   call @prepare_new_process_software_context_in_pcb ; (pass new_pid from A)

    ; Perform the context switch.
    ; This instruction switches to the process whose ID is stored in the memory location $CURRENT_PROCESS_ID.
    ; It is assumed that ctxsw handles loading the new process's hardware state (PC, SP, registers, flags)
    ; and correctly manages interrupt state, effectively replacing the 'rti' for the interrupted context.

    ctxsw $CURRENT_PROCESS_ID

    ; ctxsw instruction handles re-enabling interrupts and transfers control.
    ; The rti from the original RTC_ISR will be skipped.
    ; EXECUTION FOR THE OLD PROCESS STOPS HERE. Code after ctxsw will not be executed by the old process.


:scheduler_no_switch
    ; No context switch needed, or switched back to the same process.
    ; Return to the caller (@RTC_ISR), which will then execute 'rti' to complete the interrupt.
    ret


;-------------------------------------------------------------------------------
; System Call: Set Process Ready
; INT ~SYSCALL_SET_PROCESS_READY
; Expects: Register A (R1) = PID of the process to set to READY state.
;-------------------------------------------------------------------------------
@_isr_set_process_ready ; Linked from IVT[~SYSCALL_SET_PROCESS_READY]
    ; CPU has saved state and disabled interrupts.
    ; Register A of the *calling process* (which is now the current CPU's Reg A) holds the target PID.

    ; Validate Target PID in Register A
    ; Must be > 0 (not kernel) and < $MAX_PROCESSES
    tst A 0                             ; Check if PID is 0 (kernel)
    jmpt :_isr_set_ready_invalid_pid    ; If A == 0, invalid.

    ldm K $MAX_PROCESSES                ; K = MAX_PROCESSES (e.g., 5)
    tstg K A                            ; Status = 1 if K > A (e.g., 5 > A). This means A is a valid user PID (1,2,3,4)
    jmpf :_isr_set_ready_invalid_pid    ; If not (K > A), then A is >= K or invalid.

    ; PID is valid. Calculate address of PTE[target_pid].state
    ; Target PID is in register A.
    ; PTE_state_addr = $PROCESS_TABLE_BASE + (target_pid_A * ~PTE_SIZE) + ~PTE_STATE
    ldm K $PROCESS_TABLE_BASE           ; K (register) = base of process table
    ld M A                              ; M (register) = target_pid (from register A)
    muli M ~PTE_SIZE                    ; M (register) = target_pid * PTE_SIZE
    add K M                             ; K (register) = address of PTE for target_pid (K = K + M)
    addi K ~PTE_STATE                   ; K (register) = address of PTE[target_pid].state

    ; Now K holds the direct address of the state field. Load this into I (R0) for stx.
    ld I K                              ; I (register R0) = direct address of the state field (value from register K)
    ldi A ~PROC_STATE_READY             ; A (register R1) = new state value ~PROC_STATE_READY (original target PID in A is overwritten)
    stx A $mem_start                    ; M[I] = value_of_register_A (Assumes $mem_start contains 0)

:_isr_set_ready_done
    rti

:_isr_set_ready_invalid_pid
    ; Optionally, set an error status for the calling process or log. For now, just return.
    ; The calling process's registers (including A) are preserved by the INT/RTI mechanism.
    rti
