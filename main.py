from memory import Memory
from cpu import Cpu
from assembler import Assembler
from display import Display
from interrupts import Interrupts
from FileIO import readFile

import threading
from time import sleep

def main():

    Vh = 32
    Vw = 64 
    VideoSize = Vw * Vh

    MainMem = Memory(1024 * 16) 
    StackPointer = MainMem.MEMmax() - VideoSize
    start_mem  = 0
    start_prog = 0 
    start_var  = StackPointer - 1024
    start_font = 1024
    intVectors = 4096

    

    interrupts = Interrupts()

    CPU = Cpu(MainMem, interrupts, StackPointer, intVectors) 
    screen = Display(Vw, Vh, MainMem, 10)

    # load fonts into MainMem
    font = readFile("standard.font", 2)
    adres = start_font
    for value in font:
        MainMem.write(adres, value)
        adres =  adres + 1

    A = Assembler(start_var)
    A.assemble("loader.asm", start_prog, "out.bin")

    # load bin into MainMem
    program = readFile("out.bin", 0)
    adres = start_prog
    for value in program:
        MainMem.write(adres, value)
        adres =  adres + 1

    # Start the CPU thread
    cpu_thread = threading.Thread(target=CPU.run, args=(start_prog,))
    cpu_thread.start()
    sleep(1)


    # Start the screen main loop (tK)
    screen.display.mainloop()

    print("SYSTEM HALTED")

if __name__ == "__main__":
    main()