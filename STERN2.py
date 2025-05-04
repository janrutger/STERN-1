# /home/janrutger/git/STERN-1/STERN-2.py (New File)
import multiprocessing
import os
import time # Or sleep from time
import threading # Import threading

# Import necessary components from your STERN-1 project
from memory import Memory
from cpu1 import Cpu
from assembler1b import Assembler # Use your latest assembler
from hw_IO_manager2 import DeviceIO
from plotter_optimized import PlotterOptimized as Plotter
from XY_plotter import XYPlotter
from interrupts import Interrupts
from rtc import RTC as Rtc
from virtualdisk import VirtualDisk # Assuming VirtualDisk is adaptable
# TODO: You'll likely need a modified SerialIO or a new NetworkIO class for IPC
# from serialIO_networked import SerialIONetworked as Serial
from serialIO import serialIO as Serial # Placeholder - NEEDS MODIFICATION FOR IPC
from FileIO import readFile, writeBin # Need writeBin if assembling per instance
from stringtable import makechars

# --- Configuration ---
Vh = 32
Vw = 64
VideoSize = Vw * Vh
BASE_MEM_SIZE = 1024 * 16 # Example size

# --- Function to run a single STERN instance ---
def run_stern_instance(instance_id, config):
    """Sets up and runs a single STERN-1 simulation instance."""
    print(f"[Instance {instance_id}] Starting...")

    # --- Create Instance-Specific Components ---
    myASCII = makechars()
    interrupts = Interrupts()
    RTC = Rtc(interrupts)
    MainMem = Memory(BASE_MEM_SIZE) # Each process gets its own memory

    # --- Calculate Memory Layout (Potentially based on config if needed) ---
    StackPointer = MainMem.MEMmax() - VideoSize
    start_var = StackPointer - 2024
    IOmem_du0 = start_var - 8
    IOmem_sio = start_var - 16 # Base address for SIO

    start_font = 2024
    intVectors = 4096
    # Start addresses might be common or configured
    start_kernel = config.get("kernel_start_adres", 512)
    rom_file = config.get("start_rom", "program.bin")

    # --- Ensure Directories Exist ---
    # Bin dir is assumed to be ./bin relative to execution
    os.makedirs(config["disk_dir"], exist_ok=True)
    os.makedirs(config["bin_dir"], exist_ok=True)

    # --- Instantiate Devices with Instance Config ---
    # IMPORTANT: Modify Serial/NetworkIO to use config['network_port'] etc. for IPC
    # This placeholder Serial won't allow communication between instances.
    SIO = Serial(MainMem, IOmem_sio) # Needs modification!
    plotter = Plotter(SIO) # Assumes plotter uses SIO channel 0
    xy_plotter = XYPlotter(SIO) # Assumes XY uses SIO channel 1

    DU0 = VirtualDisk(myASCII, MainMem, IOmem_du0, config["disk_dir"])
    CPU = Cpu(MainMem, RTC, interrupts, StackPointer, intVectors)

    # --- DeviceIO with unique title ---
    devices = DeviceIO(
        myASCII, interrupts, DU0, plotter, xy_plotter, SIO,
        Vw, Vh, MainMem, 16 # Scale
        # Add window_title support to DeviceIO if needed:
        # window_title=config["window_title"]
    )

    # --- Load Font (Common or instance-specific) ---
    font_file = "standard.font" # Assuming font is shared
    try:
        font = readFile(font_file, 2) # Read from shared ./bin/
        adres = start_font
        for value in font:
            MainMem.write(adres, value)
            adres += 1
    except Exception as e:
        print(f"[Instance {instance_id}] Error loading font: {e}")
        # Handle error appropriately

    # --- Load Pre-Assembled Binaries ---
    # Binaries should already exist in the shared ./bin/ directory
    # (or specific instance dirs if assembled separately)
    def load_bin(filename):
        try:
            # Construct full path relative to the script's execution context
            # Assumes readFile looks in ./bin/ by default for type 0
            # filepath = os.path.join("./bin", filename) # If readFile needs full path
            # program_data = readFile(filepath, 0) # If readFile needs full path
            program_data = readFile(os.path.basename(filename), 0)
            for line in program_data:
                if len(line) == 2:
                    try:
                        addr = int(line[0])
                        val = line[1]
                        MainMem.write(addr, val)
                    except (ValueError, IndexError) as load_err:
                        print(f"[Instance {instance_id}] Error processing line in {filename}: {line} -> {load_err}")
                else:
                    print(f"[Instance {instance_id}] Warning: Skipping malformed line in {filename}: {line}")
        except FileNotFoundError:
            print(f"[Instance {instance_id}] Error: Binary file '{filename}' not found in {base_dir}")
        except Exception as e:
            print(f"[Instance {instance_id}] Error loading {filename}: {e}")

    print(f"[Instance {instance_id}] Loading binaries from ./bin/...")
    load_bin("loader.bin")
    load_bin("kernel.bin")
    load_bin(rom_file)
    #load_bin("program.bin") # Load the specific program binary

    # --- Start CPU in this process ---
    print(f"[Instance {instance_id}] Starting CPU at address: {start_kernel}")
    # Run CPU in a THREAD within this process
    try:
        cpu_thread = threading.Thread(target=CPU.run, args=(start_kernel,))
        cpu_thread.daemon = True # Allow main thread (Tkinter) to exit even if CPU thread is running
        cpu_thread.start()

        # Start Tkinter mainloop (blocks until window is closed)
        print(f"[Instance {instance_id}] Starting Device IO loop...")
        devices.display.mainloop()

    except Exception as e:
        print(f"[Instance {instance_id}] Runtime Error in mainloop/CPU start: {e}")
    finally:
        # This block executes when the Tkinter window is closed
        # The daemon CPU thread will exit automatically shortly after
        print(f"[Instance {instance_id}] Mainloop ended or error occurred.")
        print(f"[Instance {instance_id}] Halted.")


# --- Main Execution Block ---
if __name__ == "__main__":
    multiprocessing.freeze_support() # Recommended for cross-platform compatibility

    print("--- STERN-2 Multi-Instance Launcher ---")

    # --- Define general attibutes
    boot = {
        "start_loader": 0,
        "start_kernel": 512,
        "start_prog": 4096 + 512,  
    }

    # --- Define Configurations for Each Instance ---
    config1 = {
        "instance_id": 1,
        "bin_dir": "./", # Explicitly state shared bin dir
        "disk_dir": "./disk0",
        "window_title": "STERN-1 (Instance 1)",
        "network_role": "server", # Example for IPC
        "network_port": 12345,    # Example for IPC
        "kernel_start_adres": 512,
        "start_rom": "rom0.bin",
        # Add other specific settings if needed
    }

    config2 = {
        "instance_id": 2,
        "bin_dir": "./", # Explicitly state shared bin dir
        "disk_dir": "./disk0", # Use a separate disk dir for instance 2
        "window_title": "STERN-1 (Instance 2)",
        "network_role": "client", # Example for IPC
        "network_port": 12345,    # Example for IPC (client connects to server's port)
        "kernel_start_adres": 512,
        "start_rom": "rom1.bin",
        # Add other specific settings if needed
    }

    # --- Assembly Step (Run Once Before Launching Processes) ---
    print("Assembling code...")
    try:
        # Ensure output goes to the shared ./bin directory
        assembler = Assembler(1024 * 12) # Use appropriate start_var pointer (consistent with instance layout)
        assembler.assemble("loader2.asm", boot["start_loader"], "loader.bin") # Output relative to ./bin/
        assembler.assemble("kernel2.asm", boot["start_kernel"], "kernel.bin") # Output relative to ./bin/
        # Assemble the *same* program for both instances? Or different ones?
        #assembler.assemble("ChaosGame3.asm", boot["start_prog"], "rom0.bin") # Output relative to ./bin/
        assembler.assemble("ChaosGame4.asm", boot["start_prog"], "rom1.bin") # Output relative to ./bin/
        assembler.assemble("spritewalker.asm", boot["start_prog"], "program.bin") # Output relative to ./bin/
        print("Assembly complete.")
    except Exception as e:
        print(f"Assembly failed: {e}")
        exit(1)

    # --- Create and Start Processes ---
    print("Creating processes...")
    process1 = multiprocessing.Process(target=run_stern_instance, args=(1, config1))
    process2 = multiprocessing.Process(target=run_stern_instance, args=(2, config2))

    print("Starting processes...")
    process1.start()
    time.sleep(1) # Small delay to potentially avoid resource contention on startup
    process2.start()

    # --- Wait for Processes to Finish ---
    # They will finish when their Tkinter windows are closed
    print("Waiting for processes to complete (close their windows)...")
    process1.join()
    process2.join()

    print("--- Both STERN-1 instances have halted. ---")
