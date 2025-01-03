

def readFile(filename: str, filetype: int):
    if filetype == 0:   # 0 is filetype binary
        binary = []
        file = open("./bin/" + filename, "r")
        for line in file:
            binary.append(line.strip())
        file.close()
        return(binary)
    
    elif filetype == 1: # 1 is type assembly
        assembly = []
        file = open("./asm/" + filename, "r")
        for line in file:
            assembly.append(line.strip())
        file.close()
        return(assembly)

def writeBin(binary, output_file: str):
    with open("./bin/" + output_file, "w") as file:
        for line in binary:
            file.write(line + "\n")
    

