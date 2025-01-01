from readFile import readFile


def assembler(sourcefile: str, pgr_start: int, var_start: int):
    source = readFile(sourcefile, 1)

    assembly = []
    for line in source:
        if line == "" or line[0] == "#" or line[0] == ";":
            pass
        else:
            assembly.append(line)

    print(assembly)

    labels = dict()
    symbols = dict()
    varcount = 0

    pc = pgr_start
    vars = var_start

    for line in assembly:
        if line[0] == ":":
            if line not in labels.keys():
                labels[line] = pc
            else:
                exit("ERROR Label already used: " + line)
        elif line[0] == "@":
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
        # elif line[0] == "%":
        #     _line = line.split()
        #     if _line[1] in symbols.keys():
        #         i = 0
        #         for char in _line[2]:
        #             if char in myASCII.keys():
        #                 newline = symbols[_line[1]] + i, myASCII[char]
        #             else:
        #                 newline = symbols[_line[1]] + i, myASCII["#"]
        #             binProgram.append(newline)
        #             i = i + 1
        #         newline = symbols[_line[1]] + i, myASCII["null"]
        #         binProgram.append(newline)

        #     else:
        #         exit("ERROR address undefined : " + _line[1])
        else:
            pc = pc +1

    print(symbols, labels)


    pc = pgr_start
    for line in assembly:
        instruction = line.split()
        print(instruction)

        if instruction[0][0] in ["@", ".", ":", "%"]:
            pass






if __name__ == "__main__":
    prg_start = 0
    var_start = 32
    assembler("test.asm", prg_start, var_start)