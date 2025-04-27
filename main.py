from memory import Memory
from cpu1 import Cpu
from assembler import Assembler
from hw_IO_manager1 import DeviceIO 
#from plotter2 import Plotter
from plotter_optimized import PlotterOptimized as Plotter
from memory import Memory
from interrupts import Interrupts
from rtc import RTC as Rtc
from virtualdisk import VirtualDisk as Vdisk
from serialIO import serialIO as Serial
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
    RTC = Rtc(interrupts)

    MainMem = Memory(1024 * 16) 
    StackPointer = MainMem.MEMmax() - VideoSize
    start_var  = StackPointer - 2024
    IOmem_du0  = start_var - 8  # first device
    IOmem_sio  = start_var - 16 # second device

    start_loader  = 0
    start_kernel  = start_loader + 512
    start_font = 2024
    intVectors = 4096
    start_prog = intVectors + 512

    SIO     = Serial(MainMem, IOmem_sio)
    plotter = Plotter(SIO)
    DU0     = Vdisk(myASCII, MainMem, IOmem_du0,"./disk0")   
    CPU     = Cpu(MainMem, RTC, interrupts, StackPointer, intVectors) 
    devices = DeviceIO(myASCII, interrupts, DU0, plotter, SIO, Vw, Vh, MainMem, 16)

    # load fonts into MainMem
    font  = readFile("standard.font", 2)
    adres = start_font
    for value in font:
        MainMem.write(adres, value)
        adres =  adres + 1

    A = Assembler(start_var)
    A.assemble("loader2.asm", start_loader, "loader.bin")
    A.assemble("kernel2.asm",  start_kernel, "kernel.bin")
    A.assemble("spritewalker.asm", start_prog,   "program.bin")

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
    cpu_thread = threading.Thread(target=CPU.run, args=(start_kernel,))
    cpu_thread.start()
    

    # Start the devices main loop (tK)
    devices.display.mainloop()

    print("SYSTEM HALTED")

if __name__ == "__main__":
    main()