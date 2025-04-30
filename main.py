# /home/janrutger/git/STERN-1/main.py
from memory import Memory
from cpu1 import Cpu
from assembler1a import Assembler
from hw_IO_manager2 import DeviceIO
from plotter_optimized import PlotterOptimized as Plotter
# --- Import the new XYPlotter ---
from XY_plotter import XYPlotter
# --- End Import ---
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
    # Instantiate the standard plotter (e.g., on channel 0)
    plotter = Plotter(SIO)
    # --- Instantiate the XY plotter (e.g., on channel 1) ---
    # Adjust width/height if needed for the XY plot's coordinate system
    xy_plotter = XYPlotter(SIO) 
    # --- End Instantiate ---

    DU0     = Vdisk(myASCII, MainMem, IOmem_du0,"./disk0")
    CPU     = Cpu(MainMem, RTC, interrupts, StackPointer, intVectors)
    # --- Pass the xy_plotter instance to DeviceIO ---
    devices = DeviceIO(myASCII, interrupts, DU0, plotter, xy_plotter, SIO, Vw, Vh, MainMem, 16) # <-- Add xy_plotter
    # --- End Pass ---

    # load fonts into MainMem
    font_file = "standard.font"
    try:
        font = readFile(font_file, 2)
        adres = start_font
        for value in font:
            MainMem.write(adres, value)
            adres =  adres + 1
    except FileNotFoundError:
        print(f"Error: Font file '{font_file}' not found in ./bin/")
        # Decide how to handle this - exit or continue without font?
        # exit(1)
    except Exception as e:
        print(f"Error loading font: {e}")
        # exit(1)


    # --- Assembler and Loading ---
    A = Assembler(start_var)
    try:
        A.assemble("loader2.asm", start_loader, "loader.bin")
        A.assemble("kernel2.asm",  start_kernel, "kernel.bin")
        # Example: Assemble a program that uses the XY plotter
        A.assemble("ChaosGame.asm", start_prog,   "program.bin") # Make sure program.bin is the correct one
        # A.assemble("spritewalker.asm", start_prog,   "program.bin") # Or keep the old one if testing that

        # Function to load a binary file safely
        def load_bin(filename, expected_len=None):
            try:
                program_data = readFile(filename, 0)
                if expected_len is not None and len(program_data) != expected_len:
                     print(f"Warning: Expected {expected_len} lines in {filename}, found {len(program_data)}")
                for line in program_data:
                    if len(line) == 2:
                        try:
                            addr = int(line[0])
                            val = line[1] # Keep as string for memory write
                            MainMem.write(addr, val)
                        except ValueError:
                            print(f"Error: Invalid number format in {filename}: {line}")
                        except IndexError as ie:
                             print(f"Error: Memory write error in {filename} at address {line[0]}: {ie}")
                    else:
                        print(f"Warning: Skipping malformed line in {filename}: {line}")
            except FileNotFoundError:
                print(f"Error: Binary file '{filename}' not found in ./bin/")
                # exit(1) # Or handle differently
            except Exception as e:
                print(f"Error loading {filename}: {e}")
                # exit(1)

        # Load binaries
        print("Loading loader.bin...")
        load_bin("loader.bin")
        print("Loading kernel.bin...")
        load_bin("kernel.bin")
        print("Loading program.bin...")
        load_bin("program.bin")

    except FileNotFoundError as e:
         print(f"Error: Assembly file not found during assembly: {e}")
         exit(1)
    except Exception as e:
         print(f"Error during assembly or loading: {e}")
         exit(1)
    # --- End Assembler and Loading ---


    # Start the CPU thread
    print(f"Starting CPU at address: {start_kernel}")
    cpu_thread = threading.Thread(target=CPU.run, args=(start_kernel,))
    #cpu_thread.daemon = True # Allow main thread to exit even if CPU thread is running
    cpu_thread.start()


    # Start the devices main loop (Tkinter)
    print("Starting Device IO loop...")
    try:
        devices.display.mainloop()
    except Exception as e:
        print(f"Error in Tkinter mainloop: {e}") # Catch potential errors here too

    print("SYSTEM HALTED")
    # Optional: Explicitly wait for CPU thread to finish if needed, though daemon=True usually suffices
    # cpu_thread.join(timeout=1.0)


if __name__ == "__main__":
    main()
