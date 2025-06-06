from memory import Memory
from cpu import Cpu
from assembler import Assembler
from display import Display
from FileIO import readFile

def main():
    memory = Memory(1024 * 16)   
    VideoSize = 32*64
    progStart = 0 
    varStart  = 32
    fontStart = 50

    CPU = Cpu(memory, VideoSize) 
    screen = Display(64, 32, 10, memory)

    # load fonts into memory
    font = readFile("standard.font", 2)
    adres = fontStart
    for value in font:
        memory.write(adres, value)
        adres =  adres + 1

    screen.display.mainloop()

    A = Assembler(varStart)
    A.assemble("test.asm", progStart, "out.bin")

    # load bin into memory
    program = readFile("out.bin", 0)
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