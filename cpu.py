from decoder import decode
from time import sleep


class Cpu:
    def __init__(self, memory, interrupts, SP, intVector):
        self.memory     = memory
        self.interrupts = interrupts
        
        self.registers = [0] * 10   # 10 registers
                                    # 0      index register
                                    # 1 .. 9 General registers

                    
        self.PC = 0    # init PC
        self.SP = SP   # init SP
        self.statusbit  = 0
        self.intVector = intVector
        self.interruptEnable = True
        self.saved_state = {}


    def save_state(self):
        self.saved_state = {
            'registers': self.registers.copy(),
            'PC': self.PC,
            'statusbit': self.statusbit}
        
    def restore_state(self):
        if self.saved_state:
            self.registers = self.saved_state['registers'].copy()
            self.PC = self.saved_state['PC']
            self.statusbit = self.saved_state['statusbit']
        else:
            print("No state state to restore.")

    def run(self, startAdres: int):
        # the CPU starts running from PC
        # ends running after the HALT instruction

        runState = True
        self.PC = startAdres
        while runState:
            #sleep(.001)
            # read instruction from memory
            memValue = self.memory.read(self.PC)
            self.PC = self.PC + 1  

            # Decode instruction
            inst, op1, op2 = decode(memValue)
            print(self.PC, inst, op1, op2)


            # execute instruction
            match inst:
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
                    adres = int(self.memory.read(int(self.memory.read(op1)) + self.registers[0]))
                    self.memory.write(self.SP, self.PC) # store PC at stackpointer
                    self.SP = self.SP - 1               # update stackpointer
                    self.PC = adres                       #load PC wirh jump adres
                case 26:    # INT integer		calls interrupt integer, first saves systemstate
                    adres = int(self.memory.read(self.intVector + op1))
                    self.save_state()
                    self.PC = adres
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
                case 61:    # MULI r val
                    self.registers[op1] = self.registers[op1] * op2
                case 70:    # TST Ra integer 	set statusbit when equal 
                    if self.registers[op1] == op2:
                        self.statusbit = 1
                    else:
                        self.statusbit = 0
                case 71:     # r1 = r2 set status bit when equal
                    if self.registers[op1] == self.registers[op2]:
                        self.statusbit = 1
                    else:
                        self.statusbit = 0
                case 80:    # INC r mem
                    x = int(self.memory.read(op2))
                    self.registers[op1] = x
                    self.memory.write(op2, str(x + 1))
                case _:
                    print("CPU: Invalid instruction")
                    exit("Invalid instruction")
            

            #check for interrupts
            if self.interruptEnable:
                print("Interrupts enabled")
                if self.interrupts.pending():
                    # get interruption and execute
                    # print(self.interrupts.get())
                    interrupt, value = self.interrupts.get()
                    adres = int(self.memory.read(self.intVector + interrupt))
                    self.save_state()
                    self.registers[1] = value
                    self.PC = adres


                # else:
                #     print("No interruption")




