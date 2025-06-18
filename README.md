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

1.  **Learn STACKS:** Dive into the language by studying `STACKS/parseV3.py` and the example programs in `STACKS/src/`, especially `processes.stacks`.
2.  **Understand the System:** Review `kernel3.asm` and `stern_runtime.asm` to grasp how processes are managed and how STACKS interacts with the underlying system.
3.  **Develop:** Write your multi-process applications in STACKS. Use the provided compiler tools (which leverage `parseV3.py` and `emitV3.py`) to translate your STACKS code into Stern-1 assembly for execution.
