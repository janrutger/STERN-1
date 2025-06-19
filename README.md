# Stern-1: Multiprocessing CPU & STACKS Language

## Overview

The Stern-1 project features a CPU architecture with newly integrated multiprocessing capabilities. This system is supported by a dedicated kernel (`kernel3.asm`) and bootloader (`loader3.asm`). The STACKS programming language has been specifically updated to be "process-aware," enabling developers to write and manage multi-process applications that run directly on this enhanced Stern-1 architecture.

## Core Components

*   **Stern-1 CPU:** The central processing unit, now with hardware/architecture support for multiprocessing.
*   **Kernel (`kernel3.asm`):** A new multiprocessing kernel responsible for process scheduling, memory management for individual processes, and handling system calls.
*   **Bootloader (`loader3.asm`):** Initializes the system and loads the kernel.
*   **STACKS Language:**
    *   The primary high-level, stack-oriented language for programming the Stern-1.
    *   Parser: `STACKS/parseV3.py` (defines language grammar and structure)
    *   Lexer: `STACKS/lexV3.py`
    *   Emitter: `STACKS/emitV3.py` (generates Stern-1 assembly from STACKS code)
*   **Runtime Library (`asm/include/stern_runtime.asm`):** A library of essential routines and system call interfaces used by STACKS programs. It is included directly in `kernel3.asm`, making it available to all processes.

## STACKS Language & Multiprocessing

The STACKS language is intrinsically linked with Stern-1's multiprocessing model:

*   **Process-Aware:** STACKS includes dedicated keywords and constructs for defining processes, managing their execution, and facilitating inter-process communication.
*   **Process Memory Model:**
    *   Each process operates within its own isolated memory block (typically 1024 bytes, though this can be configured).
    *   Program code for a process is loaded at the beginning of its memory block.
    *   A data stack is situated at the top of the memory block, growing downwards. This stack area is also utilized for storing variables and arrays local to the process.
*   **Process Definition:** In STACKS, processes are defined using `PROCESS PID [STACK_SIZE] ... END` blocks, clearly delineating code for each concurrent task.
*   **Example:** The `STACKS/src/processes.stacks` file provides a practical example of how to write multi-process programs using STACKS, demonstrating process creation and basic interactions.

## Key Files & Directories
*   **Hardware Emulation & Interaction:**
    *   `stern_computer.py`: Defines a single STERN-1 computer instance, integrating all components.
    *   `hw_IO_manager3.py`: Manages the Tkinter-based GUI, screen updates, and keyboard input for each instance.
    *   `memory.py`: Simulates the main memory.
    *   `interrupts.py`: Handles interrupt queuing and dispatch.
    *   `rtc.py`: Real-Time Clock for timed interrupts (used by the scheduler).
    *   `virtualdisk.py`: Simulates disk operations.
    *   `serialIO.py`: Core logic for Serial I/O channels.
    *   `plotter_optimized.py`: Standard Y-value plotter using SIO.
    *   `XY_plotter.py`: X,Y coordinate plotter using SIO.
    *   `networkNICr2.py`: Virtual Network Interface Card for inter-process communication (simulated network).
    *   `networkHub.py`: Central hub for routing messages between NICs of different STERN-1 instances (if multiple instances are run via `STERN2.py`).
*   **CPU & Low-Level:**
    *   `cpuNG.py` (presumably, based on `cpu1.py` and project evolution): The CPU core.
    *   `decoder.py`: Decodes machine instructions.
    *   `assembler1b.py` (or `assembler1c.py` as seen in `STERN2.py`): The STERN-1 assembler.

*   **Assembly & Kernel:**
    *   `asm/loader3.asm`: System bootloader.
    *   `asm/kernel3.asm`: The multiprocessing kernel.
    *   `asm/include/stern_runtime.asm`: Core STACKS runtime library.
*   **STACKS Language Implementation:**
    *   `STACKS/parseV3.py`: The language parser, key to understanding STACKS syntax.
    *   `STACKS/lexV3.py`: The lexical analyzer.
    *   `STACKS/emitV3.py`: The assembly code emitter.
*   **STACKS Examples:**
    *   `STACKS/src/`: Directory containing example STACKS programs.
    *   `STACKS/src/processes.stacks`: A crucial example showcasing multiprocessing features.

## Getting Started
1.  **Understand the Architecture:** Familiarize yourself with the Stern-1 CPU, its multiprocessing model, the kernel's role (`kernel3.asm`), and how processes manage their memory.
2.  **Learn STACKS:**
    *   Study `STACKS/parseV3.py` to understand the language grammar and capabilities.
    *   Review example programs in `STACKS/src/`, especially `processes.stacks`.
3.  **Compilation & Execution Flow (Conceptual):**
    *   Write STACKS code (e.g., `my_program.stacks`).
    *   Use a compiler/toolchain (which would internally use `lexV3.py`, `parseV3.py`, and `emitV3.py`) to translate STACKS code into Stern-1 assembly (`.asm` file).
    *   The Stern-1 assembler (e.g., `assembler1c.py`) compiles the `.asm` file into a `.bin` machine code file.
    *   The `STERN2.py` script can be used to launch one or more Stern-1 instances. It handles:
        *   Assembling common binaries like `loader3.asm` and `kernel3.asm`.
        *   Assembling the STACKS program's generated `.asm` file (e.g., `processes.asm` to `processes.bin`).
        *   Configuring and starting `SternComputer` instances, each loading the loader, kernel, and its specific program ROM.
    *   The `loader3.asm` initializes basic hardware and interrupt vectors, then jumps to the `kernel3.asm`.
    *   The `kernel3.asm` initializes process tables, SIO, syscalls, and starts the scheduler and initial user processes (like PID 1, often a shell).
    *   STACKS processes then run, making syscalls (via `stern_runtime.asm` routines) for I/O, process management, etc.

## Hardware Devices & Interaction

The Stern-1 virtual environment includes several emulated hardware devices that STACKS programs can interact with, primarily through system calls handled by the kernel.

*   **Screen Display:**
    *   Managed by `hw_IO_manager3.py` using Tkinter.
    *   Presents a text-based console.
    *   Output is typically achieved by STACKS programs via syscalls like `~SYSCALL_PRINT_NUMBER` and `~SYSCALL_PRINT_CHAR`, which are wrappers around routines in `printing.asm` (included in `stern_runtime.asm`). These routines write character codes to a designated video memory area, which `hw_IO_manager3.py` then renders.
    *   Low-level screen operations (clear, scroll) are also available via interrupts/syscalls (e.g., `int ~SYSCALL_CLEAR_SCREEN`).

*   **Keyboard Input:**
    *   Captured by the Tkinter input bar in `hw_IO_manager3.py`.
    *   Key presses generate an interrupt (ISR: `@KBD_WRITE` in `loader3.asm`), which stores the key code in a buffer.
    *   STACKS programs typically read input using words like `INPUT` (for numbers) or `RAWIN` (for strings), which ultimately call runtime routines that read from this keyboard buffer (e.g., via `@KBD_READ` in `loader3.asm`).

*   **Serial I/O (SIO) Subsystem:**
    *   Provides channel-based communication, managed by `serialIO.py` and the kernel.
    *   STACKS programs interact with SIO channels using `CHANNEL ON/OFF` statements, which translate to kernel syscalls (`~SYSCALL_REQUEST_SIO_CHANNEL`, `~SYSCALL_RELEASE_SIO_CHANNEL`).
    *   Data is written to an owned SIO channel using routines that eventually call `~SYSCALL_WRITE_SIO_CHANNEL`.
    *   **Plotters:** The `plotter_optimized.py` (standard Y-value plotter) and `XY_plotter.py` (X,Y coordinate plotter) are primary users of SIO channels. STACKS programs use `PLOT` (which might write to a default SIO channel, e.g., channel 0 for the standard plotter, or channel 1 for the XY plotter as seen in `processes.stacks`) to send data points. The respective plotter Python scripts monitor their assigned SIO channel for new data and update the Matplotlib visualisations.

*   **Virtual Disk:**
    *   Simulated by `virtualdisk.py`, mapping operations to a host OS directory.
    *   Interaction is via memory-mapped I/O registers and interrupts (e.g., `int ~SYSCALL_OPEN_FILE`, `int ~SYSCALL_READ_FILE_LINE` which are ISRs in `loader3.asm` that interact with the virtual disk's registers).

*   **Networking (Virtual NIC):**
    *   Each Stern-1 instance can have a `networkNICr2.py` for inter-process communication if multiple instances are run (e.g., via `STERN2.py`).
    *   STACKS programs use `CONNECTION` objects to send/receive data, which call runtime routines (`@stacks_network_write`, service routines for read) that interact with the NIC's memory-mapped registers and potentially trigger network interrupts.
