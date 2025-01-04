from decoder import decode
from time import sleep


class Cpu:
    def __init__(self, memory, Vmem):
        self.memory = memory
        
        self.registers = [0] * 11   # 10 registers
                                    # 0      index register
                                    # 1 .. 9 General registers

                    
        self.PC = 0                                 # init PC
        self.SP = self.memory.MEMmax() - Vmem   # init SP
        self.statusbit = 0



    def run(self, startAdres: int):
        # the CPU starts running from PC
        # ends running after the HALT instruction

        runState = True
        self.PC = startAdres
        while runState:
            sleep(.01)
            # read instruction from memory
            memValue = self.memory.read(self.PC)
            self.PC = self.PC + 1  

            # Decode instruction
            inst, op1, op2 = decode(memValue)
            print(inst, op1, op2)


            # execute instruction
            match inst:
                case 11:    # HALT 
                    self.PC = self.PC - 1
                    runState = False
                case 20:    # JMPF adres 		jump when statusbit is false 0
                    if self.statusbit == 0:
                        self.PC = op1
                case 31:    # LDI r val
                    self.registers[op1] = op2
                case 32:    # LDM r mem
                    self.registers[op1] = int(self.memory.read(op2))
                case 40:    # STO r mem
                    self.memory.write(op2, str(self.registers[op1]))
                case 41:    # STX r mem + ri
                    adres = int(self.memory.read(op2)) + self.registers[0]
                    self.memory.write(adres, str(self.registers[op1]))
                case 50:    # ADD r1 r2
                    self.registers[op1] = self.registers[op1] + self.registers[op2]
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
                    print("Invalid instruction")
                    exit("Invalid instruction")



