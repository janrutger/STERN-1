from decoder import decode


class Cpu:
    def __init__(self, memory):
        self.memory = memory
        
        self.registers = [0] * 11   # 10 registers
                                    # 0      index register
                                    # 1 .. 9 General registers

                    
        self.PC = 0                      # init PC
        self.SP = self.memory.MEMmax()   # init SP



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
            instruction = decode(memValue)
            print(instruction)


            # execute instruction
            match instruction[0]:
                case 11:    # HALT 
                    self.PC = self.PC - 1
                    runState = False
                case 31:    # LDI
                    self.registers[instruction[1]] = instruction[2]
                case 32:    # LDM
                    self.registers[instruction[1]] = int(self.memory.read(instruction[2]))
                case 40:    # STO
                    self.memory.write(instruction[2], str(self.registers[instruction[1]]))
                case 50:    # ADD
                    self.registers[instruction[1]] = self.registers[instruction[1]] + self.registers[instruction[2]]
                case _:
                    exit("Invalid instruction")



