from memory import Memory
from cpu import Cpu
from assembler import Assembler
from display4 import Display
from interrupts import Interrupts
from FileIO import readFile
from stringtable import makechars

import threading
from time import sleep

def main():

    Vh = 32
    Vw = 64 
    VideoSize = Vw * Vh

    myASCII = makechars()
    interrupts = Interrupts()

    MainMem = Memory(1024 * 16) 
    StackPointer = MainMem.MEMmax() - VideoSize
    start_var  = StackPointer - 2024

    start_loader  = 0
    start_kernel  = start_loader + 512
    start_font = 2024
    intVectors = 4096
    start_prog = intVectors + 512


    CPU    = Cpu(MainMem, interrupts, StackPointer, intVectors) 
    screen = Display(myASCII, interrupts, Vw, Vh, MainMem, 10)

    # load fonts into MainMem
    font  = readFile("standard.font", 2)
    adres = start_font
    for value in font:
        MainMem.write(adres, value)
        adres =  adres + 1

    A = Assembler(start_var)
    A.assemble("loader2.asm", start_loader, "loader.bin")
    A.assemble("kernel.asm",  start_kernel, "kernel.bin")
    A.assemble("calculator.asm", start_prog,   "program.bin")

    # Loader bin into MainMem
    program = readFile("loader.bin", 0)
    for line in program:
        MainMem.write(int(line[0]), line[1])

    # Kernel bin into MainMem
    program = readFile("kernel.bin", 0)
    for line in program:
        MainMem.write(int(line[0]), line[1])

    # Program bin into MainMem
    program = readFile("program.bin", 0)
    for line in program:
        MainMem.write(int(line[0]), line[1])

    # Start the CPU thread
    cpu_thread = threading.Thread(target=CPU.run, args=(start_prog,))
    cpu_thread.start()

    # Start the screen main loop (tK)
    screen.display.mainloop()

    print("SYSTEM HALTED")

if __name__ == "__main__":
    main()