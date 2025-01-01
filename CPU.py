

class CPU:
    def __init__(self, memory):
        self.memory = memory
        
        self.registers = [0] * 12   # 11 registers
                                    # 0      index register
                                    # 1 .. 9 General registers
                                    # 10     PC, programcounter
                                    # 11     SP, Stack pointer
                    
        self.registers[10] = 0                      # init PC
        self.registers[11] = self.memory.MEMmax()   # init SP

        

