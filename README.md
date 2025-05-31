# STERN-1 Virtual Computer & STERN-2 Multi-Instance Launcher

## Overview

The STERN-1 project is a Python-based emulator for a custom 16-bit-like CPU architecture. It simulates a complete computer system, including a CPU, memory, various I/O devices, and a graphical user interface. The `STERN-2.py` script extends this by allowing multiple STERN-1 computer instances to run concurrently, with basic networking capabilities between them.

This project is designed for educational purposes, experimentation with computer architecture, and running custom assembly programs in a simulated environment.

## Features

- **Custom CPU Emulation (`cpu1.py`):**
    - A unique instruction set decoded and executed by the simulated CPU.
    - Registers, Program Counter (PC), Stack Pointer (SP), and status bit.
    - Interrupt handling mechanism.
- **Memory Simulation (`memory.py`):**
    - A block of memory accessible by the CPU and peripherals.
- **Assembler (`assembler1b.py`):**
    - Translates STERN-1 assembly language (`.asm`) into machine code (`.bin`).
    - Supports labels, global symbols (`@`, `$`), local labels (`:`), constants (`EQU ~NAME value`), and file includes (`INCLUDE`).
- **Graphical User Interface (Tkinter):**
    - Managed by `hw_IO_manager3.py`.
    - Displays video memory output (text-based console).
    - Handles keyboard input.
- **Virtual I/O Devices:**
    - **Video Display:** Renders characters to the Tkinter window.
    - **Keyboard Input:** Captures key presses for the CPU.
    - **Virtual Disk (`virtualdisk.py`):** Simulates disk operations.
    - **Serial I/O (`serialIO.py`):** Provides channels for serial communication, used by:
        - **Plotter (`plotter_optimized.py`):** Visualizes data streams from a serial channel using Matplotlib.
        - **XY Plotter (`XY_plotter.py`):** Plots X,Y coordinate pairs from a serial channel using Matplotlib.
    - **Virtual Network Interface Card (NIC) (`networkNICr2.py`):**
        - Enables basic packet-based communication between STERN instances.
        - Supports DATA and ACK/NACK packets.
        - Implements a simple Go-Back-N like retransmission for NACKs.
        - Uses shared queues for inter-process communication (IPC).
- **Multi-Instance Support (`STERN2.py`):**
    - Launches multiple `SternComputer` instances using Python's `multiprocessing`.
    - Each instance runs in its own process with its own Tkinter window.
- **Network Hub (`networkHub.py`):**
    - A central process that routes messages between the NICs of different STERN instances.
- **System Components:**
    - **Interrupt Controller (`interrupts.py`):** Manages hardware and software interrupts.
    - **Real-Time Clock (RTC) (`rtc.py`):** Generates timed interrupts.
    - **Font Loading:** Loads custom font files (`.font`) for display.
    - **Binary Loading (`FileIO.py`):** Loads pre-compiled programs, kernel, and loader into memory.
- **CPU Performance Monitoring (`CPUmonitor1.py`):**
    - Measures and reports estimated clock speed and cycle times.

## Directory Structure

```
STERN-1/
├── STERN2.py               # Main launcher for multiple instances
├── stern_computer.py       # Defines a single STERN computer instance
├── cpu1.py                 # CPU logic
├── memory.py               # Memory simulation
├── assembler1b.py          # Assembler
├── hw_IO_manager3.py       # I/O device manager and Tkinter GUI
├── serialIO.py             # Serial I/O device
├── networkNICr2.py         # Network Interface Card
├── networkHub.py           # Network Hub for IPC
├── plotter_optimized.py    # Standard data plotter
├── XY_plotter.py           # X,Y coordinate plotter
├── virtualdisk.py          # Virtual disk drive
├── interrupts.py           # Interrupt handling
├── rtc.py                  # Real-Time Clock
├── FileIO.py               # Utilities for reading/writing files
├── stringtable.py          # Character to ASCII value mapping
├── decoder.py              # Decodes machine code instructions
├── CPUmonitor1.py          # CPU performance monitor
├── fontmaker.py            # Script to generate font files (utility)
├── asm/                    # Directory for assembly source files (*.asm)
│   ├── incl/               # Directory for included assembly files
│   ├── loader2.asm
│   ├── kernel2.asm
│   ├── ChaosGame3.asm
│   ├── networkEcho.asm
│   └── ...                 # Other assembly programs
├── bin/                    # Directory for compiled binaries (*.bin) and fonts (*.font)
│   ├── standard.font
│   ├── loader.bin
│   ├── kernel.bin
│   └── ...                 # Compiled programs
├── disk0/                  # Example virtual disk directory for instance 0
└── README.md               # This file
```

## Prerequisites

- Python 3.x
- Tkinter (usually included with Python's standard library)
- Matplotlib (`pip install matplotlib`)
- NumPy (`pip install numpy`)

## How to Run

The primary way to run the simulation is using the `STERN2.py` script, which handles the assembly of necessary code and the launching of multiple STERN computer instances.

1.  **Ensure Prerequisites are Met:** Install Python, Matplotlib, and NumPy.
2.  **Navigate to the Project Directory:**
    ```bash
    cd path/to/STERN-1
    ```
3.  **Run the `STERN2.py` Script:**
    ```bash
    python STERN2.py
    ```

This will:
-   **Assemble Code:** Compile `loader2.asm`, `kernel2.asm`, and the programs specified in `STERN2.py` (e.g., `networkEcho.asm`, `ChaosGame3.asm`) into `.bin` files located in the `./bin/` directory.
-   **Launch Network Hub:** Start the `NetworkHub` process for inter-instance communication.
-   **Launch STERN Instances:** Start two (or more, if configured) `SternComputer` instances. Each instance will open its own Tkinter window.

Each STERN instance will then:
-   Initialize its hardware components (Memory, CPU, RTC, NIC, etc.).
-   Load the `loader.bin` and `kernel.bin` into memory.
-   Load its specific program ROM (e.g., `networkReceive.bin`, `ChaosGame3.bin`) into memory.
-   Start its CPU execution thread and its Tkinter GUI main loop.

To stop the simulation, close the Tkinter windows for each STERN instance. The `STERN2.py` script will then attempt to terminate the Network Hub process.

## Key Components

-   **`SternComputer` (`stern_computer.py`):** Encapsulates all hardware and software loading for a single STERN-1 machine. It is configured via a dictionary.
-   **`Cpu` (`cpu1.py`):** The heart of the machine, fetching, decoding, and executing instructions.
-   **`Memory` (`memory.py`):** Stores program code, data, and video memory.
-   **`Assembler` (`assembler1b.py`):** Converts assembly language to machine code. Crucial for preparing software to run on the STERN-1.
-   **`DeviceIO` (`hw_IO_manager3.py`):** Manages the Tkinter window, screen updates, keyboard input, and periodic updates for other devices like the Virtual Disk, SIO, and NIC.
-   **`VirtualNIC` & `NetworkHub`:** Provide the mechanism for instances to send and receive simple messages, simulating a basic network.

## Customization

-   **Assembly Programs:** Write your own `.asm` files and add them to the `assembly_code()` function in `STERN2.py` to have them compiled and run.
-   **Instance Configuration:** Modify `instance1_config` and `instance2_config` in `STERN2.py` to change parameters like the program ROM to load (`start_rom`), disk directory, etc.
-   **Memory Layout:** The memory layout (stack pointer, I/O addresses, font location) is defined in `stern_computer.py`.
-   **Hardware Behavior:** Modify the respective Python files (e.g., `cpu1.py`, `virtualdisk.py`) to change how simulated hardware components behave.

## TODOs & Potential Future Work (Inferred from Code Comments)

-   **SerialIO for IPC:** The `Serial` class in `stern_computer.py` is noted as a placeholder needing modification for IPC, although `VirtualNIC` currently handles inter-instance communication. This might refer to a different type of IPC or direct serial port emulation.
-   **Configuration:** Make more memory layout parameters (e.g., `start_var`, `start_font`, `intVectors` in `stern_computer.py`) configurable via the instance config dictionary.
-   **Assembler Enhancements:**
    -   Add range checks for constants and immediate values.
-   **CPU Monitor:** The SIO (Serial I/O) timing sections in `CPUmonitor1.py` are currently commented out. These could be re-enabled or expanded for more detailed I/O performance analysis.
-   **Network Hub Shutdown:** Implement a more graceful shutdown mechanism for the `NetworkHub` (e.g., using a stop signal/event) rather than relying solely on `terminate()`.
-   **Error Handling:** Continue to improve error handling and reporting across all modules.

This project provides a solid foundation for exploring computer systems concepts in a hands-on way. Enjoy experimenting with STERN-1!