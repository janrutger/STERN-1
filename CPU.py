

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
            instruction = self.memory.read(self.PC)
            self.PC = self.PC + 1


            # Decode instruction


            # execute instruction
            pass



