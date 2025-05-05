# /home/janrutger/git/STERN-1/stern_computer.py
import os
import threading
import time # Or sleep from time

# Import necessary components from your STERN-1 project
from memory1 import Memory
from cpu1 import Cpu
# assembler1b is not needed here if assembly happens before instantiation
from hw_IO_manager3 import DeviceIO # verion 3 has network support
from plotter_optimized import PlotterOptimized as Plotter
from XY_plotter import XYPlotter
from interrupts import Interrupts
from rtc import RTC as Rtc
from virtualdisk import VirtualDisk
from networkNIC import VirtualNIC
# TODO: Replace with a networked version for actual IPC
from serialIO import serialIO as Serial # Placeholder - NEEDS MODIFICATION FOR IPC
from FileIO import readFile
from stringtable import makechars

# --- Configuration Defaults (can be overridden by config dict) ---
Vh = 32
Vw = 64
VideoSize = Vw * Vh
BASE_MEM_SIZE = 1024 * 16
DEFAULT_FONT_FILE = "standard.font"
DEFAULT_LOADER_FILE = "loader.bin"
DEFAULT_KERNEL_FILE = "kernel.bin"

class SternComputer:
    """Represents a single STERN-1 computer instance."""

    def __init__(self, instance_id, config):
        """Initializes the hardware components of the STERN-1 instance."""
        self.instance_id = instance_id
        self.config = config
        self.base_dir = os.path.dirname(os.path.abspath(__file__)) # Get base dir of this file
        self.bin_dir = os.path.join(self.base_dir, "bin") # Assume bin is relative to this file

        print(f"[Instance {self.instance_id}] Initializing...")

        # --- Create Instance-Specific Components ---
        self.myASCII = makechars()
        self.interrupts = Interrupts()
        self.RTC = Rtc(self.interrupts)
        self.MainMem = Memory(self.config.get("mem_size", BASE_MEM_SIZE))

        # --- Calculate Memory Layout ---
        self.StackPointer = self.MainMem.MEMmax() - VideoSize
        start_var = self.StackPointer - 2024 # TODO: Make configurable?
        IOmem_du0 = start_var - 8
        IOmem_sio = start_var - 16 # Base address for SIO
        IOmem_nic = start_var - 24 # Base address for NIC

        self.start_font = 2024 # TODO: Make configurable?
        self.intVectors = 4096 # TODO: Make configurable?
        self.kernel_start_address = self.config.get("kernel_start_adres", 512)
        self.rom_file = self.config.get("start_rom", "program.bin")

        # --- Ensure Directories Exist ---
        disk_path = os.path.join(self.base_dir, self.config["disk_dir"])
        os.makedirs(disk_path, exist_ok=True)
        # Bin dir existence checked during loading/assembly

        # --- Instantiate Devices ---
        # IMPORTANT: Modify Serial/NetworkIO for IPC using config details
        self.SIO = Serial(self.MainMem, IOmem_sio) # Needs modification for IPC!
        self.plotter = Plotter(self.SIO) # Assumes plotter uses SIO channel 0
        self.xy_plotter = XYPlotter(self.SIO) # Assumes XY uses SIO channel 1

        # --- Instantiate NIC ---
        self.NIC = VirtualNIC(
            self.instance_id, self.MainMem, IOmem_nic,
            self.config.get("send_queue"), # Get from config
            self.config.get("receive_queue"), # Get from config
            self.interrupts
        )
        # --- End Instantiate NIC ---

        self.DU0 = VirtualDisk(self.myASCII, self.MainMem, IOmem_du0, disk_path)
        self.CPU = Cpu(self.MainMem, self.RTC, self.interrupts, self.StackPointer, self.intVectors)

        # --- DeviceIO (Tkinter window) ---
        # TODO: Add window_title support to DeviceIO if desired
        self.devices = DeviceIO(
            self.myASCII, self.interrupts, self.DU0, self.plotter, self.xy_plotter, self.SIO, self.NIC,
            Vw, Vh, self.MainMem, 16 # Scale
            # window_title=self.config.get("window_title", f"STERN-{self.instance_id}")
        )

        self._load_font()

    def _load_font(self):
        """Loads the font file into memory."""
        font_filename = self.config.get("font_file", DEFAULT_FONT_FILE)
        try:
            # readFile looks in ./bin/ by default for type 2
            font_data = readFile(font_filename, 2)
            address = self.start_font
            for value in font_data:
                self.MainMem.write(address, value)
                address += 1
        except FileNotFoundError:
             print(f"[Instance {self.instance_id}] Error: Font file '{font_filename}' not found in {self.bin_dir}")
        except Exception as e:
            print(f"[Instance {self.instance_id}] Error loading font '{font_filename}': {e}")

    def load_binaries(self):
        """Loads the standard loader, kernel, and the instance-specific ROM."""
        print(f"[Instance {self.instance_id}] Loading binaries from {self.bin_dir}...")
        self._load_single_bin(DEFAULT_LOADER_FILE)
        self._load_single_bin(DEFAULT_KERNEL_FILE)
        self._load_single_bin(self.rom_file) # Load the specific program binary

    def _load_single_bin(self, filename):
        """Helper to load a single binary file."""
        try:
            # readFile looks in ./bin/ by default for type 0
            program_data = readFile(filename, 0)
            for line in program_data:
                if len(line) == 2:
                    try:
                        addr = int(line[0])
                        val = line[1]
                        self.MainMem.write(addr, val)
                    except (ValueError, IndexError, MemoryError) as load_err: # Catch MemoryError too
                        print(f"[Instance {self.instance_id}] Error processing line in {filename}: {line} -> {load_err}")
                else:
                    print(f"[Instance {self.instance_id}] Warning: Skipping malformed line in {filename}: {line}")
        except FileNotFoundError:
            print(f"[Instance {self.instance_id}] Error: Binary file '{filename}' not found in {self.bin_dir}")
        except Exception as e:
            print(f"[Instance {self.instance_id}] Error loading {filename}: {e}")

    def run(self):
        """Starts the CPU thread and the DeviceIO main loop."""
        print(f"[Instance {self.instance_id}] Starting CPU at address: {self.kernel_start_address}")
        try:
            cpu_thread = threading.Thread(target=self.CPU.run, args=(self.kernel_start_address,))
            cpu_thread.daemon = True # Allow main process to exit if Tkinter closes
            cpu_thread.start()

            print(f"[Instance {self.instance_id}] Starting Device IO loop...")
            self.devices.display.mainloop() # Blocks until window is closed

        except Exception as e:
            print(f"[Instance {self.instance_id}] Runtime Error: {e}")
        finally:
            # This block executes when the Tkinter window is closed
            print(f"[Instance {self.instance_id}] Mainloop ended or error occurred.")
            # CPU thread (daemon) will exit automatically.
            print(f"[Instance {self.instance_id}] Halted.")