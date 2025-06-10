# /home/janrutger/git/STERN-1/cpu.py
from decoder import decode
from time import sleep
from CPUmonitor1 import CpuMonitor

# --- Process Management Constants ---
NUM_PROCESS_CONTEXTS = 5  # 0 for kernel, 1-4 for user processes
KERNEL_CONTEXT_ID = 0
USER_PROCESS_MEM_SIZE = 1024
# This should align with STERN2.py's boot["start_prog"], typically 4096
USER_PROCESSES_START_ADDRESS = 4096 # Base address for user process segments

class Cpu:
    # Remove 'sio' from the constructor arguments
    def __init__(self, memory, rtc, interrupts, SP, intVector):
        self.monitor = CpuMonitor()

        self.memory     = memory
        self.interrupts = interrupts
        # self.sio        = sio # <-- Remove this line
        self.rtc        = rtc

        self.registers = [0] * 10   # 10 registers
                                    # 0      index register
                                    # 1 .. 9 General registers


        self.PC = 0    # init PC
        self.SP = SP   # init SP
        self.statusbit  = 0
        self.intVector = intVector # Base address for interrupt vectors
        self.interruptEnable = False
        self.saved_state = {} # For saving state during regular INT/RTI

        # --- Process Management Attributes ---
        self.pcbs = [{'initialized': False} for _ in range(NUM_PROCESS_CONTEXTS)]
        self.current_context_id = KERNEL_CONTEXT_ID # Start with kernel context
        self.initial_SP_for_kernel = SP # Save SP for kernel context initialization
        self.kernel_start_address_from_run = 0 # Will be set by run()

    def save_state(self):
        """Saves CPU state for standard interrupt handling (used by INT, restored by RTI/ctxsw)."""
        self.saved_state = {
            'registers': self.registers.copy(),
            'PC': self.PC,
            'SP': self.SP,
            'statusbit': self.statusbit}

    def restore_state(self):
        if self.saved_state:
            # print(f"DEBUG CPU: Restoring state: PC={self.saved_state['PC']}, SP was {self.SP}, Status={self.saved_state['statusbit']}")
            self.registers = self.saved_state['registers'].copy()
            self.PC = self.saved_state['PC']
            self.SP = self.saved_state['SP']
            self.statusbit = self.saved_state['statusbit']
            # SP is not part of self.saved_state for INT/RTI, it's preserved or managed by stack ops.
            # For context switching, SP is part of the PCB.
        else:
            print("CPU Warning: No saved_state to restore for RTI/ctxsw.")

    def _save_current_process_context(self):
        """Saves the current CPU state into the PCB of the current_context_id."""
        pcb = self.pcbs[self.current_context_id]
        pcb['registers'] = self.registers.copy()
        pcb['PC'] = self.PC
        pcb['SP'] = self.SP
        pcb['statusbit'] = self.statusbit
        pcb['initialized'] = True
        # print(f"DEBUG CPU: Saved context for ID {self.current_context_id}: PC={pcb['PC']}, SP={pcb['SP']}")

    def _load_process_context(self, target_context_id):
        """Loads CPU state from the PCB of the target_context_id. Initializes if new."""
        if not (0 <= target_context_id < NUM_PROCESS_CONTEXTS):
            print(f"CPU Error: Invalid target_context_id {target_context_id} for load.")
            # Potentially halt or raise an error
            self.statusbit = 1 # Indicate error
            return False

        pcb = self.pcbs[target_context_id]
        if not pcb.get('initialized', False):
            # print(f"DEBUG CPU: Initializing PCB for context ID {target_context_id}")
            pcb['registers'] = [0] * 10
            pcb['statusbit'] = 0
            if target_context_id == KERNEL_CONTEXT_ID:
                pcb['PC'] = self.kernel_start_address_from_run
                pcb['SP'] = self.initial_SP_for_kernel
            else:
                # User processes (ID 1 to N)
                # User process ID 'n' (1-indexed) maps to (n-1) for segment calculation
                process_index = target_context_id - 1 # 0-indexed for user processes
                base_addr = USER_PROCESSES_START_ADDRESS + (process_index * USER_PROCESS_MEM_SIZE)
                pcb['PC'] = base_addr
                pcb['SP'] = base_addr + USER_PROCESS_MEM_SIZE - 1 # Stack top
            pcb['initialized'] = True

        self.registers = pcb['registers'].copy()
        self.PC = pcb['PC']
        self.SP = pcb['SP']
        self.statusbit = pcb['statusbit']
        self.current_context_id = target_context_id
        print(f"DEBUG CPU: Loaded context for ID {self.current_context_id}: PC={self.PC}, SP={self.SP}")
        return True

    def run(self, startAdres: int):
        # the CPU starts running from PC
        # ends running after the HALT instruction

        runState = True
        runCounter = 0

        # Initialize kernel context (context 0)
        self.kernel_start_address_from_run = startAdres
        self.PC = startAdres
        # self.SP is already set by __init__ to initial_SP_for_kernel
        # Ensure PCB[0] is marked as initialized with this starting state,
        # or let the first _save_current_process_context() handle it.
        # For safety, explicitly initialize and load context 0 if it's the first run.
        if not self.pcbs[KERNEL_CONTEXT_ID].get('initialized', False):
            self._load_process_context(KERNEL_CONTEXT_ID) # This will use kernel_start_address_from_run and initial_SP_for_kernel

        self.monitor.start_monitoring()
        while runState:
            if runCounter % 1000 == 0:
                # Give GUI some time, yielding
                sleep(0.004)
                runCounter = 0
            runCounter += 1

            self.monitor.start_cycle()

            # read instruction from memory
            memValue = self.memory.read(self.PC)
            self.PC = self.PC + 1

            # Decode instruction
            inst, op1, op2 = decode(memValue)
            #print(self.PC-1, inst, op1, op2)


            # execute instruction
            match inst:
                # --- (Instruction cases remain the same) ---
                case 10:    # NOP
                    continue
                case 11:    # HALT
                    self.PC = self.PC - 1
                    runState = False
                case 12:    # RET
                    self.SP = self.SP + 1
                    self.PC = self.memory.read(self.SP)
                case 13:    # EI
                    self.interruptEnable = True
                case 14:    # DI
                    self.interruptEnable = False
                case 15:    # RTI              return from interrupt
                    self.restore_state()
                    self.interruptEnable = True
                case 20:    # JMPF adres 		jump when statusbit is false 0
                    if self.statusbit == 0:
                        self.PC = op1
                case 21:    # JMPT adres 		jump when statusbit is false 1
                    if self.statusbit == 1:
                        self.PC = op1
                case 22:    # jmp adres         Jump alwys
                    self.PC = op1
                case 24:    # CALL adres 		store return adres on stack, dec stack
                    self.memory.write(self.SP, self.PC) # store PC at stackpointer
                    self.SP = self.SP - 1               # update stackpointer
                    self.PC = op1                       #load PC wirh jump adres
                case 25:    # CALLX	adres 		calls the adres stored in adres + R(i), stores return adres n stack, dec stack
                    #adres = int(self.memory.read(int(self.memory.read(op1)) + self.registers[0]))
                    adres = int(self.memory.read(op1)) + self.registers[0]
                    self.memory.write(self.SP, self.PC) # store PC at stackpointer
                    self.SP = self.SP - 1               # update stackpointer
                    self.PC = adres                       #load PC wirh jump adres
                case 26:    # INT integer		calls interrupt integer, first saves systemstate
                    adres = int(self.memory.read(self.intVector + op1))
                    self.interruptEnable = False
                    self.save_state()
                    self.PC = adres
                case 27:    # ctxsw next_context_id (op1 is next_context_id)
                    # This instruction is typically run at the end of an interrupt handler (e.g., scheduler)
                    # 1. Restore state of the process that was originally interrupted
                    self.restore_state() # Restores from self.saved_state (PC, regs, status of interrupted proc)
                                         # SP of interrupted process is assumed to be what it was, or managed by stack ops.
                    
                    # 2. Save the (just restored) complete context of the outgoing process
                    #    self.current_context_id still refers to the process that was interrupted.
                    self._save_current_process_context()

                    # 3. Load the context of the new process (op1)
                    next_pid = self.memory.read(op1) # content of op1 is next_context_id
                    self._load_process_context(next_pid) 

                    self.interruptEnable = True # Re-enable interrupts
                case 30:    # LD r1 r2
                    self.registers[op1] = self.registers[op2]
                case 31:    # LDI r val
                    self.registers[op1] = op2
                case 32:    # LDM r mem
                    self.registers[op1] = int(self.memory.read(op2))
                case 33:    # LDX Ra adres 	adres + R(i)
                    adres = int(self.memory.read(op2)) + self.registers[0]
                    self.registers[op1] = int(self.memory.read(adres))
                case 40:    # STO r mem
                    self.memory.write(op2, str(self.registers[op1]))
                case 41:    # STX r mem + ri
                    adres = int(self.memory.read(op2)) + self.registers[0]
                    self.memory.write(adres, str(self.registers[op1]))
                case 50:    # ADD r1 r2
                    self.registers[op1] = self.registers[op1] + self.registers[op2]
                case 51:    # ADDI r val
                    self.registers[op1] = self.registers[op1] + op2
                case 52:    # SUB r1 r2
                    self.registers[op1] = self.registers[op1] - self.registers[op2]
                case 53:    # SUBI r val
                    self.registers[op1] = self.registers[op1] - op2
                case 60:    # MUL r1 r2
                    self.registers[op1] = self.registers[op1] * self.registers[op2]
                case 61:    # MULI r val
                    self.registers[op1] = self.registers[op1] * op2
                case 62:    # DIV r1 r2
                    self.registers[op1] = self.registers[op1] // self.registers[op2]
                case 63:    # DIVI r1 val
                    self.registers[op1] = self.registers[op1] // op2
                case 65:    # DMOD	Ra	Rb	    divmod Ra Rb, returns quotiënt in Ra, remainder in Rb
                    quotient, remainder = divmod(self.registers[op1], self.registers[op2])
                    self.registers[op1] = quotient
                    self.registers[op2] = remainder
                case 70:    # TST Ra integer 	set statusbit when equal
                    if self.registers[op1] == op2:
                        self.statusbit = 1
                    else:
                        self.statusbit = 0
                case 71:     # TSTE r1 r2       set status bit when equal
                    if self.registers[op1] == self.registers[op2]:
                        self.statusbit = 1
                    else:
                        self.statusbit = 0
                case 72:     # TSTG r1 r2       set status bit when r1 > r2
                    if self.registers[op1] > self.registers[op2]:
                        self.statusbit = 1
                    else:
                        self.statusbit = 0
                case 80:    # INC r mem
                    x = int(self.memory.read(op2))
                    self.registers[op1] = x
                    self.memory.write(op2, str(x + 1))
                case 81:    # DEC r mem
                    x = int(self.memory.read(op2))
                    x = x - 1
                    self.registers[op1] = x
                    self.memory.write(op2, str(x))
                case 90:    # ANDI r val
                    self.registers[op1] = self.registers[op1] & op2
                case 91:    # XORX Ra adres	binary XOR wíth Ra and adres + R(i)
                    adres = int(self.memory.read(op2)) + self.registers[0]
                    self.registers[op1] = self.registers[op1] ^ int(self.memory.read(adres))
                case _:
                    print("CPU: Invalid instruction", inst, op1, op2)
                    exit("Invalid instruction")



            #check for interrupts
            if self.interruptEnable:
                self.rtc.tick()
                # print("Interrupts enabled")
                if self.interrupts.pending():
                    # get interruption and execute
                    # print(self.interrupts.get())
                    interrupt, value = self.interrupts.get()
                    adres = int(self.memory.read(self.intVector + interrupt))
                    self.save_state()
                    self.interruptEnable = False
                    self.registers[1] = value
                    self.PC = adres

            self.monitor.end_cycle()

        self.monitor.stop_monitoring()
        self.monitor.report()

        print("CPU halted")
