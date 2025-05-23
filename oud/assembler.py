from FileIO import readFile, writeBin


def assembler(sourcefile: str, pgr_start: int, var_start: int):
    instructions = {"nop"  : '10', "halt" : '11', "ret"  : '12',
                    "jmpf" : '20', "jmpt" : '21', "jmp"  : '22', "jmpx" : '23', "call" : '24',
                    "ld"   : '30', "ldi"  : '31', "ldm"  : '32', "ldx"  : '33',
                    "sto"  : '40', "stx"  : '41',
                    "add"  : '50', "addi" : '51', "sub"  : '52', "subi" : '53', "subr" : '54',
                    "mul"  : '60', "muli" : '61', "div"  : '62', "divi" : '63', "divr" : '64',
                    "tst"  : '70', "tste" : '71', "tstg" : '72',
                    "inc"  : '80', "dec"  : '81',
                    "read" : '98', "write": '99'}
    
    registers = {"I":'0', "A":'1', "B":'2', "C":'3', "K":'4', "L":'5', "M":'6', "X":'7', "Y":8, "Z":'9'}
        
    source = readFile(sourcefile, 1)

    assembly = []
    for line in source:
        if line == "" or line[0] == "#" or line[0] == ";":
            pass
        else:
            assembly.append(line)

    print(assembly)

    symbols = dict()
    varcount = 0

    pc = pgr_start
    vars = var_start

    for line in assembly:
        if line[0] == "@":
            if line not in symbols.keys():
                symbols[line] = pc
            else:
                exit("ERROR Symbol already used : " + line)
        elif line[0] == ".":
            _line = line.split()
            if _line[1] not in symbols.keys():
                symbols[_line[1]] = (vars + varcount)
                varcount = varcount + int(_line[2])  # +1 if lenght must be stored
            else:
                exit("ERROR address already used : " + _line[1])
        else:
            pc = pc +1

    print(symbols,  varcount)

    binary = []
    pc = pgr_start
    for line in assembly:
        instruction = line.split()
        #print(instruction)

        if instruction[0][0] in ["@", ".", ":", "%"]:
            pass
        elif instruction[0] in ['nop', 'halt', 'ret']:
            newLine = (instructions[instruction[0]])
            binary.append(newLine)
            pc = pc +1
        elif instruction[0] in ['ld', 'add', 'sub', 'div', 'tste', 'tstg']:
            newLine = (instructions[instruction[0]] + registers[instruction[1]] + registers[instruction[2]])
            binary.append(newLine)
            pc = pc +1
        elif instruction[0] in ['ldi', 'addi', 'muli', 'subi', 'divi', 'tst', 'subr', 'divr' ]:
            newLine = (instructions[instruction[0]] + registers[instruction[1]] + str(instruction[2]))
            binary.append(newLine)
            pc = pc +1
        elif instruction[0] in ['ldm', 'sto', 'inc', 'dec', 'read', 'write', 'stx', 'ldx' ]:
            newLine = (instructions[instruction[0]] + registers[instruction[1]] + str(symbols[instruction[2]]))
            binary.append(newLine)
            pc = pc +1
        elif instruction[0] in ['jmp', 'jmpt', 'jmpf', 'call' ]:
            newLine = (instructions[instruction[0]]  + str(symbols[instruction[1]]))
            binary.append(newLine)
            pc = pc +1
        elif instruction[0] in [ 'jmpx' ]:
            newLine = (instructions[instruction[0]] + registers[instruction[1]])
            binary.append(newLine)
        

    writeBin(binary)
    print(binary)






if __name__ == "__main__":
    prg_start = 0
    var_start = 32
    assembler("ChaosGame.asm", prg_start, var_start)