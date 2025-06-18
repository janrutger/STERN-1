# STACKS Programming Language for Stern-1

## Overview

STACKS is a specialized, stack-oriented programming language designed for the Stern-1 CPU architecture. It has been significantly enhanced to be "process-aware," enabling developers to write multi-process applications that leverage Stern-1's multiprocessing capabilities.

The language uses Reverse Polish Notation (RPN) for expressions and provides high-level constructs for process management, inter-process communication (IPC), data structures, and interaction with Stern-1 hardware devices.

**Key Implementation Files:**
*   Parser: `STACKS/parseV3.py` (Defines language grammar and structure)
*   Lexer: `STACKS/lexV3.py` (Tokenizes the source code)
*   Emitter: `STACKS/emitV3.py` (Generates Stern-1 assembly from STACKS code)

## Core Concepts

*   **Stack-Based:** Operations primarily manipulate a data stack. Operands are pushed onto the stack, and operators consume them, pushing results back.
*   **Reverse Polish Notation (RPN):** Expressions are written with operands first, followed by the operator (e.g., `10 20 +` to add 10 and 20).
*   **Process-Oriented:** Designed for defining and running multiple concurrent processes.

## Process Definition & Memory Model

Processes are the fundamental unit of execution for STACKS programs on Stern-1.

*   **Definition:**
    ```stacks
    PROCESS <PID> [STACK_SIZE]
      // ... code for this process ...
    END
    ```
    *   `<PID>`: A unique integer identifying the process.
    *   `[STACK_SIZE]`: (Optional) An integer specifying the size (in words) for this process's data stack. Defaults to 64 if not provided.

*   **Memory Model per Process:**
    *   Each process operates within its own isolated memory block (typically 1024 bytes, configurable at the system level).
    *   **Program Code:** Loaded at the beginning of the process's memory block.
    *   **Data Area & Stack:** The remaining space is used for:
        *   **Variables & Arrays:** Allocated from the top of this area, growing downwards.
        *   **Data Stack:** Occupies the highest addresses within this area, growing downwards towards the variables/arrays. Used for RPN calculations, function arguments, and local storage.

    The `parseV3.py` and `emitV3.py` components manage symbol allocation and code generation within this per-process memory model. If a process reaches the end of its `PROCESS ... END` block without an explicit termination, it's automatically stopped by the system.

## Key Language Features

### 1. Basic Stack Operations
*   `DUP`: Duplicates the top item on the stack (TOS).
*   `DDOT` (`..`): Same as `DUP`.
*   `OVER`: Duplicates the second item on the stack to the top.
*   `DROP`: Removes the TOS.
*   `SWAP`: Swaps the top two items on the stack.
*   `DOT` (`.`): (Implicit) Uses the TOS as an operand if an operation needs one and it's not explicitly provided.

### 2. Arithmetic & Logic
*   `+`, `-`, `*`, `/`: Standard arithmetic operations.
*   `PCT`: Modulo operation.
*   `EQEQ`: Equality comparison (pushes 1 if true, 0 if false).
*   `NOTEQ`: Inequality comparison.
*   `LT`: Less than comparison.
*   `GT`: Greater than comparison.
*   `BANG` (`!`): Factorial (unary operation on TOS).
*   `GCD`: Greatest Common Divisor (binary operation on top two stack items).

### 3. Control Flow
*   **Labels:**
    ```stacks
    LABEL myLabel
    ```
    Defines a named location in the code. Labels are local to the process.
*   **Unconditional Jump:**
    ```stacks
    GOTO myLabel
    ```
*   **Conditional Execution Block (IF-like):**
    ```stacks
    {condition_expression} DO
      // ... code to execute if condition_expression is non-zero (true) ...
    END
    ```
    The `{condition_expression}` (which can be a series of RPN operations) should result in a value on the stack. `DO` pops this value.
*   **Conditional Jump:**
    ```stacks
    {condition_expression} GOTO myLabel
    ```
    Jumps to `myLabel` if the `condition_expression` (popped from stack) is non-zero (true).
*   **Looping (WHILE-like):**
    ```stacks
    OPENC // Marks start of condition evaluation for a loop
      {condition_setup_expression} // Pushes values for condition check
      {condition_check_expression} // Results in boolean on stack
    CLOSEC // Marks end of condition evaluation
    DO
      // ... loop body ...
      // Manually jump back to OPENC to re-evaluate condition
      GOTO loop_condition_label // (where loop_condition_label is before OPENC)
    END
    ```
    This structure requires manual label placement and jumps for loop control. The `OPENC`/`CLOSEC` keywords are syntactic sugar and don't directly translate to specific assembly beyond managing the expression.

### 4. Input/Output
*   `PRINT`: Pops a number from the stack and prints it, followed by a newline.
    ```stacks
    123 PRINT // Output: 123
    ```
*   `INPUT`: Reads a number from standard input and pushes it onto the stack.
*   `RAWIN`: Reads a raw string from input. Pushes a null terminator (0) then the characters of the string in reverse order onto the stack.
*   `SHOW`: Pops characters from the stack (until a null terminator or stack underflow) and prints them as a string.
    ```stacks
    'Hello' SHOW // Output: Hello
    ```
*   `PLOT`: Pops a number from the stack and sends it to the default SIO plotting channel.
    ```stacks
    42 PLOT
    ```

### 5. String Literals
*   Defined using single quotes: `'my string'`.
*   When encountered, a null terminator (0) is pushed onto the stack, followed by the ASCII values of the characters in the string, in reverse order of their appearance.
    *   Example: `'Hi'` results in `0`, then `'i'`, then `'H'` being pushed (so `H` is TOS).

### 6. Backtick Assembly Calls
*   Allows direct calls to Stern-1 assembly routines (prefixed with `@` in assembly).
    ```stacks
    `my_asm_routine` // Compiles to: call @my_asm_routine
    ```

### 7. Timers
*   `timer_id TIMER SET`: Sets/resets the specified timer.
*   `timer_id TIMER PRINT`: Prints the elapsed time of the specified timer.
*   `timer_id TIMER GET`: Pushes the elapsed time of the timer onto the stack.
    ```stacks
    0 TIMER SET     // Start timer 0
    // ... some operations ...
    0 TIMER PRINT   // Print elapsed time for timer 0
    0 TIMER GET     // Push elapsed time for timer 0 to stack
    ```

### 8. SIO Channels
*   `channel_id CHANNEL ON`: Requests and activates an SIO channel.
*   `channel_id CHANNEL OFF`: Releases an SIO channel.
    ```stacks
    0 CHANNEL ON  // Activate SIO channel 0
    // ... use channel 0 (e.g., with PLOT) ...
    0 CHANNEL OFF // Release SIO channel 0
    ```

## Multiprocessing Features

### 1. Process Definition
As described earlier, using `PROCESS PID [STACK_SIZE] ... END`.

### 2. Process Management
*   `MYPID`: An expression keyword that pushes the current process's PID onto the stack.
    ```stacks
    MYPID PRINT // Prints the PID of the currently executing process
    ```
*   `{pid_expression} STARTPROCESS`: Pops a PID from the stack (result of `pid_expression`) and attempts to start that process. Pushes a status code (0 for success) back onto the stack.
    ```stacks
    2 STARTPROCESS // Attempts to start process with PID 2
    DROP           // Optionally drop the status code
    ```
*   `{pid_expression} STOPPROCESS`: Pops a PID from the stack and attempts to stop that process. Pushes a status code back.
    ```stacks
    MYPID STOPPROCESS // Current process stops itself
    ```

### 3. Inter-Process Communication (IPC) via Connections
STACKS uses a `CONNECTION` abstraction for IPC, which maps to the Stern-1 NIC for message passing.

*   **Defining a READ Connection (Service/Server):**
    ```stacks
    connection_name CONNECTION READ service_routine_name
    ```
    *   `connection_name`: Identifier for this connection endpoint.
    *   `service_routine_name`: Name of a STACKS function (or an assembly label starting with `@`) that will be called when this connection is "read" (i.e., when data arrives for its associated service ID). This routine is responsible for processing the incoming data (which will be on the stack or in a known memory location via the NIC ISR) and typically pushes a result and a status code back onto the STACKS stack.
    *   When `connection_name` is used as an item in an expression, it triggers the call to `@service_routine_name`.

*   **Defining a WRITE Connection (Client):**
    ```stacks
    connection_name CONNECTION WRITE destination_pid service_id
    ```
    *   `destination_pid`: The PID of the target process.
    *   `service_id`: An integer identifying the service on the target process.
    *   To send data: `value_to_send AS connection_name`. This pushes `value_to_send` onto the stack, then the `AS connection_name` part triggers a call to a generated assembly stub. This stub pops the value, sets up the `destination_pid` and `service_id`, and calls the runtime's `@stacks_network_write` routine.

**Example:**
```stacks
// Process A (Server)
PROCESS 10
  FUNCTION handle_data_request
    // Assume incoming data was placed on stack by NIC ISR + runtime
    // Or, service routine reads from NIC registers via runtime helpers
    // For this example, let's assume data is on stack
    DROP // Drop some hypothetical request parameter
    100  // Result
    0    // Status (0 = success)
  END FUNCTION

  data_service CONNECTION READ handle_data_request

  // ... later, to "process" an incoming request (if event-driven or polled)
  // data_service // This would call @handle_data_request
END

// Process B (Client)
PROCESS 20
  request_sender CONNECTION WRITE 10 1 // Target PID 10, Service ID 1

  // ... later, to send data
  42 AS request_sender // Sends 42 to Process 10, Service 1
END
