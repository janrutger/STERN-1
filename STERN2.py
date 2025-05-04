# /home/janrutger/git/STERN-1/STERN-2.py (New File)
import multiprocessing
import os
import time # Or sleep from time
import threading # Import threading
import sys # For sys.exit

# Import necessary components from your STERN-1 project
from stern_computer import SternComputer # Import the new class
from assembler1b import Assembler # Use your latest assembler
from FileIO import readFile, writeBin # Need writeBin if assembling per instance
from stringtable import makechars

# --- Configuration ---
Vh = 32
Vw = 64
VideoSize = Vw * Vh

# --- Function to run a single STERN instance ---
def run_stern_instance(instance_id, config):
    """Creates, configures, loads, and runs a SternComputer instance."""
    try:
        # 1. Create the computer instance (initializes hardware)
        computer = SternComputer(instance_id, config)
        # 2. Load the necessary software
        computer.load_binaries()
        # 3. Run the simulation (starts CPU and Tkinter)
        computer.run()
    except Exception as e:
        print(f"[Instance {instance_id}] FATAL ERROR during setup/run: {e}")


# --- Main Execution Block ---
if __name__ == "__main__":
    multiprocessing.freeze_support() # Recommended for cross-platform compatibility

    print("--- STERN-2 Multi-Instance Launcher ---")

    # --- Define general attributes ---
    # Base directory for relative paths (like disk dirs)
    base_dir = os.path.dirname(os.path.abspath(__file__))
    boot = {
        "start_loader": 0,
        "start_kernel": 512,
        "start_prog": 4096 + 512,
    }

    # --- Define Configurations for Each Instance ---
    instance1_config = {
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

    instance2_config = {
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
    # Ensure output goes to the shared ./bin directory relative to this script
    bin_output_dir = os.path.join(base_dir, "bin")
    os.makedirs(bin_output_dir, exist_ok=True) # Ensure bin dir exists
    try:
        assembler = Assembler(1024 * 12) # Use appropriate start_var pointer (consistent with instance layout)
        assembler.assemble("loader2.asm", boot["start_loader"], "loader.bin")
        assembler.assemble("kernel2.asm", boot["start_kernel"], "kernel.bin")
        # Assemble the *same* program for both instances? Or different ones?
        # Assemble ROMs specified in configs
        # assembler.assemble("ChaosGame4.asm", boot["start_prog"], instance1_config["start_rom"])
        assembler.assemble("ChaosGame3.asm", boot["start_prog"], instance2_config["start_rom"])
        # assembler.assemble("spritewalker.asm", boot["start_prog"], "program.bin") # Example if needed
        print("Assembly complete.")
    except Exception as e:
        print(f"Assembly failed: {e}")
        sys.exit(1)

    # --- Create and Start Processes ---
    print("Creating processes...")
    process1 = multiprocessing.Process(target=run_stern_instance, args=(1, instance1_config))
    process2 = multiprocessing.Process(target=run_stern_instance, args=(2, instance2_config))

    print("Starting processes...")
    process1.start()
    time.sleep(1) # Small delay to potentially avoid resource contention on startup
    process2.start()

    # --- Wait for Processes to Finish ---
    # They will finish when their Tkinter windows are closed
    print("Waiting for processes to complete (close their windows)...")
    process1.join()
    process2.join()

    print("\n--- Both STERN instances have halted. ---")
