from FileIO import readFile, writeBin
from stringtable import makechars

class Assembler:
    def __init__(self, var_pointer: int):
        self.NextVarPointer = var_pointer
        self.instructions = {
            "nop": '10', "halt": '11', "ret": '12', "ei": '13', "di": '14', "rti": '15',
            "jmpf": '20', "jmpt": '21', "jmp": '22', "jmpx": '23', "call": '24', "callx": '25', "int": '26',
            "ld": '30', "ldi": '31', "ldm": '32', "ldx": '33',
            "sto": '40', "stx": '41',
            "add": '50', "addi": '51', "sub": '52', "subi": '53', "subr": '54',
            "mul": '60', "muli": '61', "div": '62', "divi": '63', "divr": '64', "dmod": '65',
            "tst": '70', "tste": '71', "tstg": '72',
            "inc": '80', "dec": '81',
            "andi": '90', "xorx": '91', "read": '98', "write": '99'
        }
        self.registers = {
            "I": '0', "A": '1', "B": '2', "C": '3', "K": '4', "L": '5', "M": '6', "X": '7', "Y": '8', "Z": '9'
        }
        self.myASCII = makechars()
        self.symbols = {}
        self.labels = {}
        self.assembly = []
        self.binary = []

    def read_source(self, sourcefile):
        self.source = readFile(sourcefile, 1)

    def include_source(self, filename):
        return readFile(filename, 1)

    def parse_source(self):
        self.assembly = []
        files_to_include = []
        for line in self.source:
            if line == "" or line[0] == "#" or line[0] == ";":
                continue
            if line.startswith("INCLUDE"):
                parts = line.split()
                if len(parts) == 2:
                    files_to_include.append(parts[1])
                else:
                    exit("ERROR: INCLUDE instruction requires a filename")
            else:
                self.assembly.append(line)

        for file in files_to_include:
            included_source = self.include_source("incl/" + file + ".asm")
            for line in included_source:
                if line == "" or line[0] == "#" or line[0] == ";":
                    continue
                self.assembly.append(line)
        #print(self.assembly, len(self.assembly))

    def parse_symbols(self, prg_start):
        pc = prg_start
        self.labels = {}
        for line in self.assembly:
            if line[0] == "@":
                if line not in self.symbols:
                    self.symbols[line] = pc
                else:
                    exit("ERROR Symbol already used : " + line)
            elif line[0] == ":":
                if line not in self.labels:
                    self.labels[line] = pc
                else:
                    exit("ERROR Label already used : " + line)
            elif line[0] == ".":
                _line = line.split()
                if _line[1] not in self.symbols:
                    self.symbols[_line[1]] = self.NextVarPointer
                    self.NextVarPointer += int(_line[2])
                else:
                    exit("ERROR address already used : " + _line[1])
            elif line[0] == "%":
                continue
            else:
                pc += 1
        #print(self.symbols, self.labels, self.NextVarPointer, pc)

    def get_adres(self, label: str) -> str:
        if label in self.symbols.keys():
            return str(self.symbols[label])
        elif label in self.labels.keys():
            return str(self.labels[label])
        else:
            exit("ERROR Unkown Symbol of Label, check for typeo " + label)

    def get_value(self, label: str) -> str:
        if label.isdigit():
            return str(label)
        elif label[0] in ['-', '+'] and label[1:].isdigit():
            return str(label)
        elif label[0] == "\\":
            return str(self.myASCII[label[1:]])
        elif label[0] in ["@", "$"]:
            return str(self.symbols[label])
        else:
            exit("ERROR Not a correct value, check for typeo " + label)

    def generate_binary(self, prg_start, output_file):
        self.binary = []
        pc = prg_start
        for line in self.assembly:
            instruction = line.split()
            if instruction[0][0] in ["@", ".", ":"]:
                continue
            elif instruction[0][0] in ["%"]:
                if instruction[1] in self.symbols.keys():
                    adres = int(self.symbols[instruction[1]])
                    for value in instruction[2:]:
                        newLine = (adres, self.get_value(value))
                        self.binary.append(newLine)
                        adres += 1
                else:
                    exit("ERROR Not a correct adres, check for typeo " + instruction[1])
            elif instruction[0] in ['nop', 'halt', 'ret', 'rti', 'ei', 'di']:
                newLine = (pc, self.instructions[instruction[0]])
                self.binary.append(newLine)
                pc += 1
            elif instruction[0] in ['ld', 'add', 'mul', 'sub', 'div', 'tste', 'tstg', 'dmod']:
                newLine = (pc, self.instructions[instruction[0]] + self.registers[instruction[1]] + self.registers[instruction[2]])
                self.binary.append(newLine)
                pc += 1
            elif instruction[0] in ['ldi', 'addi', 'muli', 'subi', 'divi', 'tst', 'subr', 'divr', 'andi']:
                newLine = (pc, self.instructions[instruction[0]] + self.registers[instruction[1]] + self.get_value(instruction[2]))
                self.binary.append(newLine)
                pc += 1
            elif instruction[0] in ['ldm', 'sto', 'inc', 'dec', 'read', 'write', 'stx', 'ldx', 'xorx']:
                newLine = (pc, self.instructions[instruction[0]] + self.registers[instruction[1]] + self.get_adres(instruction[2]))
                self.binary.append(newLine)
                pc += 1
            elif instruction[0] in ['jmp', 'jmpt', 'jmpf', 'call', 'jmpx', 'callx']:
                newLine = (pc, self.instructions[instruction[0]] + self.get_adres(instruction[1]))
                self.binary.append(newLine)
                pc += 1
            elif instruction[0] in ['int']:
                newLine = (pc, self.instructions[instruction[0]] + self.get_value(instruction[1]))
                self.binary.append(newLine)
                pc += 1
            else:
                raise ValueError("ERROR Unkown instruction " + instruction[0])
        writeBin(self.binary, output_file)
        #print(self.binary, len(self.binary))

    def assemble(self, filename, prog_start, output="out.bin"):
        self.read_source(filename)
        self.parse_source()
        self.parse_symbols(prog_start)
        self.generate_binary(prog_start, output)

if __name__ == "__main__":
    prog_start = 0
    varPointer = 1024 * 8
    assembler = Assembler(varPointer)
    assembler.assemble("loader2.asm", prog_start)

    prog_start = 2 * 1024
    assembler.assemble("kernel2.asm", prog_start)

    prog_start = 5 * 1024
    assembler.assemble("test.asm", prog_start)