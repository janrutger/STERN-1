from memory import Memory
from CPU import Cpu
from readFile import readFile

def main():
    memory = Memory(1024 * 16)   
    CPU = Cpu(memory)  
    progStart = 0 

    # load a file into memory
    program = readFile("test.bin", 0)
    adres = progStart
    for value in program:
        memory.write(adres, value)
        adres =  adres + 1

    # make the CPU runnig
    # must be a Thread when main wil serve the display
    # CPU stops at HALT instruction
    CPU.run(progStart)
    

    print("SYSTEM HALTED")




if __name__ == "__main__":
    main()