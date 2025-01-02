from decoder import decode


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
                case 31:    # LDI
                    self.registers[op1] = op2
                case 32:    # LDM
                    self.registers[op1] = int(self.memory.read(op2))
                case 40:    # STO
                    self.memory.write(op2, str(self.registers[op1]))
                case 50:    # ADD
                    self.registers[op1] = self.registers[op1] + self.registers[op2]
                case _:
                    exit("Invalid instruction")



