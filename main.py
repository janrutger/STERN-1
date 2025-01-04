from memory import Memory
from CPU import Cpu
from assembler import Assembler
from display import Display
from FileIO import readFile

import threading
from time import sleep

def main():

    Vh = 32
    Vw = 64 
    VideoSize = Vw * Vh
    progStart = 0 
    varStart  = 32
    fontStart = 50

    MainMem = Memory(1024 * 16)  
    CPU = Cpu(MainMem, VideoSize) 
    screen = Display(Vw, Vh, MainMem, 5)

    # load fonts into MainMem
    font = readFile("standard.font", 2)
    adres = fontStart
    for value in font:
        MainMem.write(adres, value)
        adres =  adres + 1

    A = Assembler(varStart)
    A.assemble("test.asm", progStart, "out.bin")

    # load bin into MainMem
    program = readFile("out.bin", 0)
    adres = progStart
    for value in program:
        MainMem.write(adres, value)
        adres =  adres + 1

    # Start the CPU thread
    cpu_thread = threading.Thread(target=CPU.run, args=(progStart,))
    cpu_thread.start()
    sleep(1)

    # Start the screen main loop (tK)
    screen.display.mainloop()

    print("SYSTEM HALTED")

if __name__ == "__main__":
    main()