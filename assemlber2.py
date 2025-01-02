from FileIO import readFile, writeBin

class Assembler:
    def __init__(self):
        self.instructions = {
            "nop": '10', "halt": '11', "ret": '12',
            "jmpf": '20', "jmpt": '21', "jmp": '22', "jmpx": '23', "call": '24',
            "ld": '30', "ldi": '31', "ldm": '32', "ldx": '33',
            "sto": '40', "stx": '41',
            "add": '50', "addi": '51', "sub": '52', "subi": '53', "subr": '54',
            "mul": '60', "muli": '61', "div": '62', "divi": '63', "divr": '64',
            "tst": '70', "tste": '71', "tstg": '72',
            "inc": '80', "dec": '81',
            "read": '98', "write": '99'
        }
        self.registers = {
            "I": '0', "A": '1', "B": '2', "C": '3', "K": '4', "L": '5', "M": '6', "X": '7', "Y": '8', "Z": '9'
        }
        self.symbols = {}
        self.varcount = 0
        self.assembly = []
        self.binary = []

    def parse_line(self, line):
        instruction = line.split()
        if instruction[0][0] in ["@", ".", ":", "%"]:
            return None
        elif instruction[0] in ['nop', 'halt', 'ret']:
            return self.instructions[instruction[0]]
        elif instruction[0] in ['ld', 'add', 'sub', 'div', 'tste', 'tstg']:
            return self.instructions[instruction[0]] + self.registers[instruction[1]] + self.registers[instruction[2]]
        elif instruction[0] in ['ldi', 'addi', 'muli', 'subi', 'divi', 'tst', 'subr', 'divr']:
            return self.instructions[instruction[0]] + self.registers[instruction[1]] + str(instruction[2])
        elif instruction[0] in ['ldm', 'sto', 'inc', 'dec', 'read', 'write', 'stx', 'ldx']:
            return self.instructions[instruction[0]] + self.registers[instruction[1]] + str(self.symbols[instruction[2]])
        elif instruction[0] in ['jmp', 'jmpt', 'jmpf', 'call']:
            return self.instructions[instruction[0]] + str(self.symbols[instruction[1]])
        elif instruction[0] in ['jmpx']:
            return self.instructions[instruction[0]] + self.registers[instruction[1]]
        return None

    def handle_symbols(self, line, pc, vars):
        if line[0] == "@":
            if line not in self.symbols:
                self.symbols[line] = pc
            else:
                raise ValueError(f"ERROR: Symbol already used: {line}")
        elif line[0] == ".":
            _line = line.split()
            if _line[1] not in self.symbols:
                self.symbols[_line[1]] = vars + self.varcount
                self.varcount += int(_line[2])
            else:
                raise ValueError(f"ERROR: Address already used: {_line[1]}")
        else:
            pc += 1
        return pc

    def assemble(self, sourcefile: str, pgr_start: int, var_start: int):
        try:
            source = readFile(sourcefile, 1)
        except Exception as e:
            raise IOError(f"Error reading file {sourcefile}: {e}")

        self.assembly = [line for line in source if line and line[0] not in ["#", ";"]]

        self.symbols = {}
        self.varcount = 0
        pc = pgr_start
        vars = var_start

        for line in self.assembly:
            pc = self.handle_symbols(line, pc, vars)

        print(self.symbols, self.varcount)

        self.binary = []
        pc = pgr_start
        for line in self.assembly:
            newLine = self.parse_line(line)
            if newLine:
                self.binary.append(newLine)
                pc += 1

        writeBin(self.binary)
        print(self.binary)

if __name__ == "__main__":
    assembler = Assembler()
    assembler.assemble("test.asm", 0, 32)