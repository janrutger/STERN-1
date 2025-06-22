# /home/janrutger/git/STERN-1/STERN-2.py (New File)
import multiprocessing
import os
import time # Or sleep from time
import threading # Import threading
import sys # For sys.exit

# Import necessary components from your STERN-1 project
from stern_computer import SternComputer # Import the new class
from assembler1c import Assembler # Use your latest assembler
from FileIO import readFile, writeBin # Need writeBin if assembling per instance
from stringtable import makechars
from networkHub import NetworkHub

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

# --- function to assemble the nessasery code
def assembly_code():
    print("Assembling code...")
    # Ensure output goes to the shared ./bin directory relative to this script
    bin_output_dir = os.path.join(base_dir, "bin")
    os.makedirs(bin_output_dir, exist_ok=True) # Ensure bin dir exists
    # Calculate the assembler's variable pointer consistent with stern_computer.py's layout
    mem_size_sim = 1024 * 16
    video_size_sim = Vw * Vh
    stack_pointer_sim = mem_size_sim - 1 - video_size_sim
    assembler_var_pointer = stack_pointer_sim - 2048 # This correctly calculates to 12311 (2024)
    try:
        #assembler = Assembler(1024 * 12) # Use appropriate start_var pointer (consistent with instance layout)
        assembler = Assembler(assembler_var_pointer)
        assembler.assemble("loader3.asm", boot["start_loader"], "loader.bin")
        assembler.assemble("kernel3.asm", boot["start_kernel"], "kernel.bin")

        # Assemble the *same* program for both instances? Or different ones?
        # Assemble ROMs specified in configs
        # assembler.assemble("ChaosGame3.asm", boot["start_prog"], "ChaosGame3.bin", True)
        # assembler.assemble("ChaosGame4.asm", boot["start_prog"], "ChaosGame4.bin", True)
        # assembler.assemble("program0.asm", boot["start_prog"], "program0.bin", True) # Example if needed
        # assembler.assemble("program1.asm", boot["start_prog"], "program1.bin", True)
        assembler.assemble("test.asm", boot["start_prog"], "processes.bin", True)
        # assembler.assemble("spritewalker.asm", boot["start_prog"], "spritewalker.bin", True)
        print("Assembly complete.")
    except Exception as e:
        print(f"Assembly failed: {e}")
        sys.exit(1)

# --- Main Execution Block ---
if __name__ == "__main__":
    multiprocessing.freeze_support() # Recommended for cross-platform compatibility


    print("--- STERN-2 Multi-Instance Launcher ---")

    # --- Define general attributes ---
    # Base directory for relative paths (like disk dirs)
    base_dir = os.path.dirname(os.path.abspath(__file__))
    boot = {
        "num_instances_to_run": 1, # Configurable: 1 for development, 2 for multi-instance
        "start_loader": 0,
        "start_kernel": 1024,
        "intVectors": 3072, # New Interrupt Vector Table start address
        "start_prog": 4096,
        "hub_max_connections": 3,
    }

    # --- set the shared object
    max_connections = boot.get("hub_max_connections", 0)
    receive_queues = []
    send_queue = None
    if max_connections != 0:
        manager = multiprocessing.Manager()  # Create the manager first
        send_queue = manager.Queue()    # Create the single send queue
        # Create the receive queues and add them to the list
        receive_queues = [manager.Queue() for _ in range(max_connections)]   



    # --- Define Configurations for Each Instance ---
    instance0_config = {
        "instance_id": 0,
        "bin_dir": "./", # Explicitly state shared bin dir
        "disk_dir": "./disk0",
        "window_title": "STERN-1 (Instance 1)",
        "kernel_start_adres": boot["start_kernel"], # Use boot config for kernel start
        "start_rom": "processes.bin",
        "send_queue": send_queue,
        "receive_queue": receive_queues[0],
        # Add other specific settings if needed
    }

    instance1_config = {
        "instance_id": 1,
        "bin_dir": "./", # Explicitly state shared bin dir
        "disk_dir": "./disk0", # Use a separate disk dir for instance 2
        "window_title": "STERN-1 (Instance 2)",
        "kernel_start_adres": boot["start_kernel"], # Use boot config for kernel start
        "start_rom": "processes.bin",
        "send_queue": send_queue,
        "receive_queue": receive_queues[1],
        # Add other specific settings if needed
    }

    # --- Assembly Step (Run Once Before Launching Processes) ---
    assembly_code()

    # Determine the number of instances to run from config
    num_instances = boot.get("num_instances_to_run", 1)

    # Serial HUB code....    
    # Define a simple wrapper function if NetworkHub isn't directly callable as a target
    def run_hub_process(send_queue, receive_queues, max_connections):
        try:
            HUB = NetworkHub(send_queue, receive_queues, max_connections)
            HUB.start() # Assuming NetworkHub has a 'start' method
        except Exception as e:
            print(f"[Hub Process] Error: {e}")

    hub_process = None
    if num_instances > 1 and max_connections > 0: # Only start hub if it's configured to be used
        print("Creating and starting Network Hub process...")
        hub_process = multiprocessing.Process(target=run_hub_process, args=(send_queue, receive_queues, max_connections))
        hub_process.start()
        time.sleep(1) # Give hub a moment to initialize
    else:
        print("Network not created...")

    # --- Create and Start Processes ---
    print(f"Creating {num_instances} STERN instance(s)...")
    
    all_instance_configs = [instance0_config, instance1_config] # Add more if you have them
    processes = []

    for i in range(num_instances):
        if i < len(all_instance_configs):
            config = all_instance_configs[i]
            # Ensure instance_id in config matches the loop, or is already correctly set
            # config['instance_id'] = i # If you need to dynamically set it
            print(f"Preparing process for instance {config.get('instance_id', i)}...")
            process = multiprocessing.Process(target=run_stern_instance, args=(config.get('instance_id', i), config))
            processes.append(process)
        else:
            print(f"Warning: Not enough configurations defined for {num_instances} instances. Only starting {len(processes)}.")
            break

    print(f"Starting {len(processes)} STERN instance(s)...")
    for i, process in enumerate(processes):
        process.start()
        if i < len(processes) - 1: # Add delay between starts, except for the last one
            time.sleep(1) 

    # --- Wait for Processes to Finish ---
    print(f"Waiting for {len(processes)} STERN instance(s) to complete (close their windows)...")
    for process in processes:
        process.join()

    print(f"\n--- All {len(processes)} STERN instance(s) have halted. ---")

    # --- Clean up Hub Process ---
    print("Terminating Network Hub process...")
    # You might need a more graceful shutdown mechanism for the hub
    # (e.g., sending a 'stop' message via a queue) before terminating.
    if hub_process and hub_process.is_alive():
         hub_process.terminate() # Forceful termination
         hub_process.join(timeout=5) # Wait for termination
         if hub_process.is_alive():
              print("[Warning] Hub process did not terminate cleanly.")

    print("\n--- All processes finished. ---")
