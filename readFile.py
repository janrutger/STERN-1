def readFile(filename: str, filetype: int):
    if filetype == 0:   # 0 is filetype binary
        binary = []
        file = open("./bin/" + filename, "r")
        for line in file:
            binary.append(line.strip())
        file.close()
        return(binary)

