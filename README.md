# STERN-1 Virtual Computer & STERN-2 Multi-Instance Environment

## 1. Overview

The STERN-1 project is a sophisticated Python-based simulation of a custom 16-bit-like computer architecture. It provides a complete virtual environment, encompassing a CPU, memory, a rich set of I/O peripherals, and a graphical user interface. Programs for STERN-1 are developed using a dedicated assembly language and processed by a custom assembler.

The `STERN-2.py` script elevates this by enabling the concurrent operation of multiple STERN-1 instances. These instances can communicate with each other over a simulated network, facilitated by virtual Network Interface Cards (NICs) and a central Network Hub.

This project serves as an excellent platform for educational exploration of computer architecture, operating system concepts, assembly language programming, and basic networking principles in a controlled, simulated setting.

## 2. Core Features

### 2.1. STERN-1 Simulated Hardware
*   **Custom CPU (`cpu1.py`):**
    *   Unique instruction set (detailed in `assembler1b.py`).
    *   10 General-Purpose Registers (R0-R9), Program Counter (PC), Stack Pointer (SP).
    *   Status bit for conditional operations.
    - Interrupt handling mechanism.
    *   CPU performance monitoring (`CPUmonitor1.py`).
*   **Memory (`memory.py`):**
    *   Simulated word-addressable memory space.
    *   Dedicated regions for program code, data, stack, video RAM, and font data.
*   **Interrupt Controller (`interrupts.py`):**
    *   Manages a queue of pending hardware and software interrupts.
*   **Real-Time Clock (RTC) (`rtc.py`):**
    *   Generates periodic interrupts for time-based events.

### 2.2. Software Development & "Stacks Language"
*   **Custom Assembly Language:**
    *   Features a comprehensive set of instructions for data manipulation, arithmetic, control flow, and I/O.
    *   **"Stacks Language" Aspect:** The architecture and assembly language heavily utilize a stack, managed by the Stack Pointer (SP). Subroutine calls (`CALL`, `CALLX`) push the return address onto the stack, and returns (`RET`, `RTI`) pop it. This explicit stack management is a fundamental characteristic of programming for STERN-1.
*   **Assembler (`assembler1b.py`):**
    - Translates STERN-1 assembly language (`.asm`) into machine code (`.bin`).
    - Supports labels, global symbols (`@`, `$`), local labels (`:`), constants (`EQU ~NAME value`), and file includes (`INCLUDE`).
    *   Provides detailed error reporting with line numbers and source context.
    *   State management (`save_state`, `restore_state`) for modular assembly.

### 2.3. Input/Output (I/O) Subsystem & Peripherals
*   **I/O Manager (`hw_IO_manager3.py`):**
    *   Manages the Tkinter-based graphical user interface for each STERN-1 instance.
    *   Coordinates updates for all connected virtual devices.
*   **Screen Display:**
    - Displays video memory output (text-based console).
    *   Uses a custom bitmap font (`fontmaker.py`, `standard.font`).
*   **Keyboard Input:**
    *   Captures key presses from the Tkinter input bar.
    *   Generates keyboard interrupts with ASCII-like character codes.
*   **Virtual Disk (`virtualdisk.py`):**
    *   Simulates file system operations by mapping them to a directory on the host OS.
    *   Supports opening files (by hash of filename) and reading their content.
*   **Serial I/O (SIO) (`serialIO.py`):**
    *   Provides a channel-based mechanism for serial communication.
    *   Used by plotter devices to receive data from STERN-1 programs.
*   **Graphical Plotters (Matplotlib-based):**
    *   **Standard Plotter (`plotter_optimized.py`):** Visualizes a stream of Y-values against an auto-incrementing X-axis (sample index).
    *   **XY Plotter (`XY_plotter.py`):** Plots (X, Y) coordinate pairs, suitable for graphical applications like fractals.

### 2.4. Networking (STERN-2 Multi-Instance)
*   **Virtual Network Interface Card (NIC) (`networkNICr2.py`):**
    *   Emulates a NIC in each STERN-1 instance.
    *   Interfaced via memory-mapped registers.
    *   Supports sending and receiving DATA and ACK/NACK packets.
    *   Implements a basic Go-Back-N like retransmission strategy for NACKs.
    *   Includes support for `service_id` for application-level multiplexing.
*   **Network Hub (`networkHub.py`):**
    *   A central process that routes packets between STERN-1 instances.
    *   Uses shared `multiprocessing.Queue`s for Inter-Process Communication (IPC).
*   **Multi-Instance Orchestration (`STERN2.py`):**
    *   Launches multiple `SternComputer` instances, each in its own process.
    *   Manages the setup of shared network queues.
    *   Handles the assembly of common and instance-specific code.

## 3. Directory Structure

```
STERN-1/
├── STERN2.py               # Main launcher for multiple STERN-1 instances
├── stern_computer.py       # Class defining a single STERN-1 computer instance
├── README.md               # This file
│
├── cpu1.py                 # CPU logic and instruction execution
├── memory.py               # Memory simulation
├── decoder.py              # Decodes machine code instructions
├── assembler1b.py          # STERN-1 assembly language assembler
├── CPUmonitor1.py          # CPU performance monitoring utility
│
├── hw_IO_manager3.py       # I/O device manager, Tkinter GUI (supports networking)
├── interrupts.py           # Interrupt controller
├── rtc.py                  # Real-Time Clock simulation
├── stringtable.py          # Character to ASCII-like value mapping
├── FileIO.py               # Utilities for reading/writing project-specific files
│
├── serialIO.py             # Serial I/O device logic
├── plotter_optimized.py    # Standard Y-value data plotter
├── XY_plotter.py           # X,Y coordinate pair plotter
├── virtualdisk.py          # Virtual disk drive simulation
│
├── networkNICr2.py         # Virtual Network Interface Card
├── networkHub.py           # Network Hub for inter-instance communication
│
├── fontmaker.py            # Utility script to generate font files
│
├── asm/                    # Directory for assembly source files (*.asm)
│   ├── incl/               # Directory for included assembly files (e.g., constants.asm)
│   ├── loader2.asm         # Bootloader program
│   ├── kernel2.asm         # Basic kernel/monitor program
│   ├── ChaosGame3.asm      # Example program (plots a Sierpinski triangle)
│   ├── ChaosGame4.asm      # Example program (plots a Sierpinski triangle using XY plotter)
│   ├── networkEcho.asm     # Example network program (echo server)
│   ├── out0.asm            # Example network client program
│   ├── out1.asm            # Example network server program
│   └── ...                 # Other assembly programs
│
├── bin/                    # Directory for compiled binaries (*.bin) and fonts (*.font)
│   ├── standard.font       # Default font data
│   ├── loader.bin
│   ├── kernel.bin
│   └── ...                 # Compiled programs
│
└── disk0/                  # Example virtual disk directory for instance 0
```

## 4. Prerequisites

*   Python 3.x
*   Tkinter (typically included with Python's standard library)
*   Matplotlib (`pip install matplotlib`)
*   NumPy (`pip install numpy`)

## 5. How to Run

The primary method for running the simulation is via the `STERN2.py` script, which orchestrates the assembly of necessary code and the launch of multiple STERN-1 computer instances.

1.  **Ensure Prerequisites are Met:**
    Install Python and the required libraries:
    ```bash
    pip install matplotlib numpy
    ```
2.  **Navigate to the Project Directory:**
    ```bash
    cd path/to/STERN-1
    ```
3.  **Run the `STERN2.py` Script:**
    ```bash
    python STERN2.py
    ```

This command will:
1.  **Assemble Code:** Compile `loader2.asm`, `kernel2.asm`, and the programs specified in the `assembly_code()` function within `STERN2.py` (e.g., `ChaosGame4.asm`, `program0.bin`, `program1.bin`). The output `.bin` files will be placed in the `./bin/` directory.
2.  **Launch Network Hub:** Start the `NetworkHub` process, which listens for and routes messages between STERN instances.
3.  **Launch STERN Instances:** Initialize and start two (or more, if configured in `STERN2.py`) `SternComputer` instances. Each instance will:
    *   Open its own Tkinter window for display and keyboard input.
    *   Initialize its virtual hardware (CPU, Memory, RTC, NIC, etc.).
    *   Load the `loader.bin` and `kernel.bin`.
    *   Load its specific program ROM (defined in its configuration in `STERN2.py`).
    *   Begin CPU execution and activate its I/O device loop.

To stop the simulation, close the Tkinter windows of each STERN instance. The `STERN2.py` script will then attempt to gracefully terminate the Network Hub process.

## 6. Key Architectural Components

*   **`SternComputer` (`stern_computer.py`):**
    An object encapsulating all hardware, software loading, and operational logic for a single STERN-1 machine. It is configured via a Python dictionary passed during instantiation.
*   **`Cpu` (`cpu1.py`):**
    The central processing unit. It fetches instructions from memory, decodes them using `decoder.py`, and executes them according to the defined instruction set.
*   **`Memory` (`memory.py`):**
    A list-based simulation of the computer's main memory, storing instructions, data, video buffer, and font.
*   **`Assembler` (`assembler1b.py`):**
    A crucial tool that translates human-readable STERN-1 assembly language into the machine code that the `Cpu` can execute.
*   **`DeviceIO` (`hw_IO_manager3.py`):**
    The bridge between the simulated hardware and the user. It manages the Tkinter GUI, handles screen updates, keyboard input, and polls other devices like the Virtual Disk, SIO channels, and the NIC.
*   **`VirtualNIC` & `NetworkHub`:**
    These components, along with `multiprocessing` queues, form the networking subsystem, allowing separate STERN-1 processes to exchange simple data packets.

## 7. Customization and Experimentation

*   **Write Assembly Programs:** Create new `.asm` files in the `./asm/` directory. Add them to the `assembly_code()` function in `STERN2.py` to have them compiled. You can then specify these new `.bin` files as the `start_rom` in an instance's configuration.
*   **Configure Instances:** Modify the `instance1_config`, `instance2_config`, etc., dictionaries in `STERN2.py` to change parameters such as the program ROM to load, the virtual disk directory, or network queue assignments.
*   **Modify Hardware Behavior:** The Python classes for each component (e.g., `cpu1.py`, `virtualdisk.py`, `networkNICr2.py`) can be modified to alter their functionality or experiment with new hardware features.
*   **Extend Instruction Set:** Add new instructions to `assembler1b.py` (in `self.instructions`) and implement their corresponding execution logic in `cpu1.py` (in the `match inst:` block).
*   **Develop New Peripherals:** Create new Python classes for custom I/O devices and integrate them into `DeviceIO` and the `SternComputer` setup.

## 8. Potential Future Enhancements (Inferred)

*   **Advanced Assembler Features:**
    *   Implement robust range checking for immediate values and constants.
    *   Support for macros or more complex expressions in `EQU` directives.
*   **Networking:**
    *   More sophisticated network protocols or error handling.
    *   A more graceful shutdown mechanism for the `NetworkHub`.
*   **Operating System Concepts:**
    *   Develop a more advanced kernel with features like basic process management (within a single STERN instance) or a simple file system API.
*   **Debugging Tools:**
    *   A built-in debugger or enhanced tracing capabilities for assembly programs.
*   **Configuration Flexibility:**
    *   Make more memory layout parameters (e.g., `start_var`, `start_font`, `intVectors` in `stern_computer.py`) easily configurable via the instance configuration dictionary in `STERN2.py`.

This STERN-1 environment provides a rich and flexible platform for learning and experimentation. Enjoy exploring the intricacies of computer systems!
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