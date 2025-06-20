# /home/janrutger/git/STERN-1/assembler1c.py
from FileIO import readFile, writeBin
from stringtable import makechars
import sys # Import sys for stderr

# --- Optional: Define a custom exception for cleaner handling ---
class AssemblyError(Exception):
    """Custom exception for assembly errors."""
    pass

# --- Constants for shared heap ---
DEFAULT_SHARED_HEAP_START_ADDRESS = 8192  # After 4 user processes (4096 + 4*1024)
DEFAULT_SHARED_HEAP_SIZE = 3072          # 3 * 1024 as per prompt
# --- End Optional ---

class Assembler:
    def __init__(self, var_pointer: int):
        self.NextVarPointer = var_pointer
        self.instructions = {
            "nop": '10', "halt": '11', "ret": '12', "ei": '13', "di": '14', "rti": '15',
            "jmpf": '20', "jmpt": '21', "jmp": '22', "jmpx": '23', "call": '24', "callx": '25', "int": '26', "ctxsw": '27',
            "ld": '30', "ldi": '31', "ldm": '32', "ldx": '33',
            "sto": '40', "stx": '41',
            "add": '50', "addi": '51', "sub": '52', "subi": '53', "subr": '54',
            "mul": '60', "muli": '61', "div": '62', "divi": '63', "divr": '64', "dmod": '65',
            "tst": '70', "tste": '71', "tstg": '72',
            "inc": '80', "dec": '81', "andi": '82', "xorx": '83',
            "push": '90', "pop": '91'
        }
        self.registers = {
            "I": '0', "A": '1', "B": '2', "C": '3', "K": '4', "L": '5', "M": '6', "X": '7', "Y": '8', "Z": '9'
        }
        self.myASCII = makechars()
        self.symbols = {} # Global symbols (@, $)
        self.kernel_file_labels = {} # Labels (:) defined in kernel mode for the current file

        self.SHARED_HEAP_START_ADDRESS = DEFAULT_SHARED_HEAP_START_ADDRESS
        self.SHARED_HEAP_SIZE = DEFAULT_SHARED_HEAP_SIZE
        self.NextSharedVarPointer = self.SHARED_HEAP_START_ADDRESS
        self.shared_symbols = {} # &symbol -> address in heap
        self.process_file_labels = {} # {pid: {label_or_var_name: address}} for current file
        self.constants = {} # Global constants (~) - NEW
        self.assembly = []
        self.binary = []
        self.source = []
        self._current_filename = "" # Store filename for error messages
        self._line_map = {} # Map assembly index to (orig_line, orig_file)

        # --- State for saving/restoring ---
        self._saved_symbols = None
        self._saved_constants = None
        self._saved_next_var_pointer = None
        self._saved_shared_symbols = None
        self._saved_next_shared_var_pointer = None

        # --- Process Management State ---
        self.current_mode = 'kernel'  # 'kernel' or 'process'
        self.current_kernel_pid = None  # PID of the process currently being assembled (1-4)
        # prog_start for the *file* if it's a process file (e.g., USER_PROCESSES_START_ADDRESS)
        self.current_process_base_prog_start_for_file = None
        self.current_process_block_start_addr = None  # Calculated PC for the current process block
        self.current_process_initial_sp_val = None
        self.current_process_stacksize_directive = 32 # Default stack size
        self.current_process_var_alloc_start_addr = None # Where process vars start allocating upwards
        self.current_process_var_next_free_addr = None # Next free address for process vars
        # Tracks the highest PC reached by code in current process block (address *after* last instruction)
        self.current_process_code_end_addr = 0

        self.is_first_directive_processed = False # To check if file starts with .PROCES
        self.is_process_definition_file = False # True if first significant directive was .PROCES

        # Constants for process management (mirroring cpu1.py)
        self.USER_PROCESS_MEM_SIZE = 1024
        self.NUM_PROCESS_CONTEXTS = 5 # 0 for kernel, 1-4 for user
        self.MAX_USER_PROCESS_ID = self.NUM_PROCESS_CONTEXTS - 1 # Max user PID (e.g., 4)
        self.MIN_USER_PROCESS_ID = 1
        self.DEFAULT_PROCESS_STACK_SIZE = 32

    # --- Helper to format and raise/exit with error ---
    def _error(self, line_num, line_content, message):
        # Ensure line_num is displayed correctly, even if 0
        display_line_num = line_num if line_num is not None else '?'
        error_message = f"ERROR in '{self._current_filename}', Line ~{display_line_num}: {message}\n  > {line_content.strip()}"
        raise AssemblyError(error_message)
    # --- End Helper ---

    def _reset_process_context_for_new_block(self):
        """Resets state for a new .PROCES block. Clears local labels."""
        # self.current_kernel_pid is set by the new .PROCES directive
        self.current_process_block_start_addr = None
        self.current_process_initial_sp_val = None
        # self.current_process_stacksize_directive is set by .PROCES
        self.current_process_var_alloc_start_addr = None
        self.current_process_var_next_free_addr = None
        self.current_process_code_end_addr = 0

    def _perform_process_block_checks(self, line_num_for_error, line_content_for_error):
        """Performs memory layout checks for the completed process block."""
        if self.current_mode == 'process' and self.current_kernel_pid is not None:
            # Check 1: Code/Variable Collision
            # current_process_code_end_addr is the address *after* the last instruction.
            # current_process_var_alloc_start_addr is where variables start.
            if self.current_process_code_end_addr > self.current_process_var_alloc_start_addr:
                self._error(line_num_for_error, line_content_for_error,
                            f"Process {self.current_kernel_pid} code (ends at {self.current_process_code_end_addr - 1}) "
                            f"overflows into variable space (starts at {self.current_process_var_alloc_start_addr}). "
                            f"Reduce code size or increase stack size for process {self.current_kernel_pid}.")
            # Variable space overflow is checked during '. $var size' allocation.

    # --- read_source, include_source remain the same ---
    def read_source(self, sourcefile):
        try:
            # Assuming readFile prepends './asm/'
            self.source = readFile(sourcefile, 1)
        except FileNotFoundError:
             raise # Handled in assemble
        except Exception as e:
             raise AssemblyError(f"Could not read source file '{sourcefile}': {e}")


    def include_source(self, include_filename, included_from_line):
        try:
            # Assuming readFile prepends './asm/'
            return readFile(include_filename, 1)
        except FileNotFoundError:
            # Use _error helper, providing context about where INCLUDE was found
            self._error(included_from_line, f"INCLUDE {include_filename}", f"Include file not found: './asm/{include_filename}'")
        except Exception as e:
            self._error(included_from_line, f"INCLUDE {include_filename}", f"Could not read include file './asm/{include_filename}': {e}")


    # --- parse_source remains the same ---
    def parse_source(self):
        self.assembly = []
        raw_assembly_lines = [] # Store tuples of (line_content, original_line_num, filename)
        files_to_include = [] # Store tuples of (include_path, line_num_in_main_file)

        # --- First pass: Read main file and identify includes ---
        for line_num, line in enumerate(self.source, 1):
            stripped_line = line.strip()
            raw_assembly_lines.append((stripped_line, line_num, self._current_filename)) # Store original line info
            if not stripped_line or stripped_line.startswith("#") or stripped_line.startswith(";"):
                continue
            if stripped_line.upper().startswith("INCLUDE"):
                parts = stripped_line.split()
                if len(parts) == 2:
                    # Path relative to './asm/' as expected by readFile
                    include_path = f"incl/{parts[1]}.asm"
                    files_to_include.append((include_path, line_num)) # Store path and line number where included
                else:
                    # Use the stored raw line info for the error message
                    self._error(line_num, stripped_line, "INCLUDE instruction requires exactly one filename argument")

        # --- Process includes ---
        processed_assembly = []
        line_map = {} # Map final assembly index to (original_line_num, original_filename)
        final_assembly_index = 0

        for line_content, orig_line_num, filename in raw_assembly_lines:
            if line_content.upper().startswith("INCLUDE"):
                 # Find the include details
                 include_details = next((inc for inc in files_to_include if inc[1] == orig_line_num), None)
                 if include_details:
                     include_path, include_directive_line_num = include_details
                     try:
                         # Pass the line number where INCLUDE was found for error context
                         included_source = self.include_source(include_path, include_directive_line_num)
                         include_filename_simple = include_path.split('/')[-1] # Get simple name for mapping
                         for include_line_num, include_line in enumerate(included_source, 1):
                             stripped_include_line = include_line.strip()
                             # Skip comments/empty lines within included file
                             if not stripped_include_line or stripped_include_line.startswith("#") or stripped_include_line.startswith(";"):
                                 continue
                             processed_assembly.append(stripped_include_line)
                             line_map[final_assembly_index] = (include_line_num, include_filename_simple)
                             final_assembly_index += 1
                     except AssemblyError: # Catch errors from include_source
                          raise # Re-raise to be caught by assemble()
                     except Exception as e: # Catch unexpected errors during include processing
                          self._error(include_directive_line_num, line_content, f"Unexpected error processing include '{include_path}': {e}")

            else:
                 # Keep non-include lines (including comments/directives initially for line mapping)
                 processed_assembly.append(line_content)
                 line_map[final_assembly_index] = (orig_line_num, filename)
                 final_assembly_index += 1

        # Store the final processed assembly and the line map
        self.assembly = processed_assembly
        self._line_map = line_map # Store map for later use in errors

    def parse_symbols(self, prg_start_for_file):
        # pc is the current absolute program counter for code generation.
        # It's initialized to prg_start_for_file for kernel mode,
        # or updated by .PROCES directive for process mode.
        pc = prg_start_for_file

        # If already in process mode (e.g. from a previous .PROCES in the same file),
        # pc should be the start of that process block.
        if self.current_mode == 'process' and self.current_process_block_start_addr is not None:
            pc = self.current_process_block_start_addr
        else: # Ensure code_end_addr is initialized if in kernel mode from start
            self.current_process_code_end_addr = pc

        # current_pass_labels_in_scope is for detecting redefinition of labels/vars
        # within the *current scope* (file for kernel, block for process).
        current_pass_labels_in_scope = {}

        for idx, line in enumerate(self.assembly):
            orig_line_num, orig_filename = self._line_map.get(idx, (idx + 1, self._current_filename))
            current_line_content_for_error = line # Original line for error messages

            # Process line for parsing: strip inline comments, then strip leading/trailing whitespace
            line_for_parsing = line.split(';', 1)[0].strip()

            if not line_for_parsing or line_for_parsing.startswith("#"): # Handles empty lines or full-line comments
                continue
            parts = line_for_parsing.split(maxsplit=2) # Split max 3: directive/label, name/arg1, value/arg2
            directive = parts[0]
            directive_upper = directive.upper()
            if not self.is_first_directive_processed:
                self.is_first_directive_processed = True
                if directive_upper == ".PROCES":
                    self.is_process_definition_file = True
                    # The prog_start for a process definition file is the base for all user processes
                    self.current_process_base_prog_start_for_file = prg_start_for_file
                elif self.current_mode == 'process': # Should not happen
                     self._error(orig_line_num, current_line_content_for_error, "Internal error: Assembler in process mode before first directive.")

            try:
                if directive_upper == ".PROCES":
                    if not self.is_process_definition_file:
                        self._error(orig_line_num, current_line_content_for_error, ".PROCES directive can only be used if it's the first significant directive in the file.")

                    # Perform checks for the *previous* process block before starting a new one
                    if self.current_kernel_pid is not None:
                        self._perform_process_block_checks(orig_line_num, line)

                    # Reset process-specific memory pointers and clear current_pass_labels_in_scope
                    self._reset_process_context_for_new_block()
                    current_pass_labels_in_scope.clear() # Reset for the new process scope

                    self.current_mode = 'process'
                    if len(parts) < 2 or len(parts) > 3:
                        self._error(orig_line_num, current_line_content_for_error, ".PROCES directive requires <id> and optional [<stacksize>] (e.g., .PROCES 1 64)")
                    try:
                        pid = int(parts[1])
                        if not (self.MIN_USER_PROCESS_ID <= pid <= self.MAX_USER_PROCESS_ID):
                            self._error(orig_line_num, current_line_content_for_error, f"Process ID {pid} out of range ({self.MIN_USER_PROCESS_ID}-{self.MAX_USER_PROCESS_ID}). Kernel is PID 0.")
                        self.current_kernel_pid = pid
                    except ValueError:
                        self._error(orig_line_num, current_line_content_for_error, f"Invalid Process ID '{parts[1]}'. Must be an integer.")

                    stack_size = self.DEFAULT_PROCESS_STACK_SIZE
                    if len(parts) == 3:
                        try:
                            stack_size = int(parts[2])
                            if stack_size <= 0 or stack_size >= self.USER_PROCESS_MEM_SIZE: # Stack cannot consume whole block
                                 self._error(orig_line_num, current_line_content_for_error, f"Invalid stack size '{parts[2]}'. Must be positive and less than {self.USER_PROCESS_MEM_SIZE}.")
                        except ValueError:
                            self._error(orig_line_num, current_line_content_for_error, f"Invalid stack size '{parts[2]}'. Must be an integer.")
                    self.current_process_stacksize_directive = stack_size
                    self.current_process_block_start_addr = self.current_process_base_prog_start_for_file + \
                                                            (self.current_kernel_pid - 1) * self.USER_PROCESS_MEM_SIZE
                    self.current_process_initial_sp_val = self.current_process_block_start_addr + self.USER_PROCESS_MEM_SIZE
                    self.current_process_var_alloc_start_addr = self.current_process_initial_sp_val - self.current_process_stacksize_directive
                    self.current_process_var_next_free_addr = self.current_process_var_alloc_start_addr
                    
                    pc = self.current_process_block_start_addr # Set current PC to the start of this process block
                    self.current_process_code_end_addr = pc # Initialize code end for this new block
                    
                    # Ensure a dictionary exists for this PID in process_file_labels
                    if self.current_kernel_pid not in self.process_file_labels:
                        self.process_file_labels[self.current_kernel_pid] = {}
                    continue # Directive processed, move to next line

                elif directive_upper == "EQU":
                    if len(parts) != 3:
                        self._error(orig_line_num, current_line_content_for_error, "EQU directive requires a constant name and a value (e.g., EQU ~NAME 123)")
                    const_name = parts[1]
                    value_str = parts[2]

                    if not const_name.startswith("~"):
                        self._error(orig_line_num, current_line_content_for_error, f"Constant name '{const_name}' must start with '~'.")

                    if const_name in self.constants: # Constants are global
                        self._error(orig_line_num, current_line_content_for_error, f"Constant '{const_name}' already defined.")

                    # --- Resolve the constant's value ---
                    # Use a simplified version of get_value here, as full symbol/label resolution
                    # might not be ready or appropriate for constant definition.
                    # Allow numbers and character literals for now.
                    resolved_value = None
                    value_str_stripped = value_str.strip()
                    if value_str_stripped.isdigit() or (value_str_stripped.startswith(('-', '+')) and value_str_stripped[1:].isdigit()):
                        # TODO: Add range check if needed for constants
                        resolved_value = str(value_str_stripped) # Store as string
                    elif value_str_stripped.startswith("\\"):
                        char_name = value_str_stripped[1:]
                        if char_name in self.myASCII:
                            resolved_value = str(self.myASCII[char_name]) # Store ASCII value as string
                        else:
                            self._error(orig_line_num, current_line_content_for_error, f"Unknown character literal '{value_str_stripped}' for constant value.")
                    # Add support for other constants? e.g., EQU ~WIDTH ~BASE_WIDTH+10 (More complex)
                    # elif value_str_stripped.startswith("~"): ... look up in self.constants ...
                    else:
                        self._error(orig_line_num, current_line_content_for_error, f"Invalid value '{value_str}' for EQU. Only numbers (e.g., 123) and character literals (e.g., \\a) are currently supported.")
                    # --- End Resolve Value ---

                    if resolved_value is not None:
                        self.constants[const_name] = resolved_value
                    # EQU does not advance PC
                    continue # Move to next line

                elif directive.startswith("@"):
                    symbol_name = directive
                    if symbol_name in self.symbols: # Global symbols
                        self._error(orig_line_num, current_line_content_for_error, f"Symbol '{symbol_name}' already defined (at address {self.symbols[symbol_name]}) in a previous assembly pass.")
                    self.symbols[symbol_name] = pc
                elif directive.startswith(":"):
                    label_name = directive
                    # current_pass_labels_in_scope tracks redefinitions within that current scope.
                    if label_name in current_pass_labels_in_scope:
                         self._error(orig_line_num, current_line_content_for_error, f"Label '{label_name}' already defined in this file/pass.")
                    
                    if self.current_mode == 'kernel':
                        if label_name in self.kernel_file_labels: # Check for redefinition in file's kernel scope
                            self._error(orig_line_num, current_line_content_for_error, f"Kernel label '{label_name}' already defined.")
                        self.kernel_file_labels[label_name] = pc
                    elif self.current_mode == 'process':
                        proc_labels = self.process_file_labels[self.current_kernel_pid]
                        if label_name in proc_labels: # Check for redefinition in this process's scope
                            self._error(orig_line_num, current_line_content_for_error, f"Label '{label_name}' already defined in process {self.current_kernel_pid}.")
                        proc_labels[label_name] = pc
                    current_pass_labels_in_scope[label_name] = pc
                elif directive.startswith("."):
                    if self.current_mode == 'process' and self.current_kernel_pid is None:
                        self._error(orig_line_num, current_line_content_for_error, "Variable definition '.' found before a .PROCES directive in a process file.")
                    if len(parts) < 3:
                        self._error(orig_line_num, current_line_content_for_error, "Directive '.' requires a symbol name and size (e.g., . $myVar 1)")
                    symbol_name = parts[1]
                    size_str = parts[2]
                    try:
                        size = int(size_str)
                        if size <= 0: raise ValueError("Size must be positive")
                    except ValueError:
                         self._error(orig_line_num, current_line_content_for_error, f"Invalid size '{size_str}' for directive '.'. Must be a positive integer.")

                    if symbol_name.startswith("&"): # Shared symbol
                        if symbol_name in self.shared_symbols:
                            self._error(orig_line_num, current_line_content_for_error, f"Shared symbol '{symbol_name}' already defined (at heap address {self.shared_symbols[symbol_name]}).")
                        if self.NextSharedVarPointer + size > self.SHARED_HEAP_START_ADDRESS + self.SHARED_HEAP_SIZE:
                            self._error(orig_line_num, current_line_content_for_error,
                                        f"Shared symbol '{symbol_name}' allocation (size {size}) exceeds heap limit. "
                                        f"Next available: {self.NextSharedVarPointer}, Heap end: {self.SHARED_HEAP_START_ADDRESS + self.SHARED_HEAP_SIZE -1}.")
                        self.shared_symbols[symbol_name] = self.NextSharedVarPointer
                        self.NextSharedVarPointer += size
                    elif symbol_name.startswith("$"): # Kernel or Process local variable
                        if self.current_mode == 'kernel':
                            # Check global symbols (which includes kernel $vars)
                            if symbol_name in self.symbols:
                                self._error(orig_line_num, current_line_content_for_error, f"Kernel variable symbol '{symbol_name}' already defined (at address {self.symbols[symbol_name]}).")
                        if symbol_name in self.symbols: # Check global symbols
                            self._error(orig_line_num, current_line_content_for_error, f"Symbol '{symbol_name}' already defined globally (at address {self.symbols[symbol_name]}).")
                        self.symbols[symbol_name] = self.NextVarPointer
                        self.NextVarPointer += size
                    elif self.current_mode == 'process':
                        proc_vars_and_labels = self.process_file_labels[self.current_kernel_pid]
                        if symbol_name in proc_vars_and_labels or symbol_name in current_pass_labels_in_scope: # Check process-local scope
                            self._error(orig_line_num, current_line_content_for_error, f"Symbol '{symbol_name}' already defined in process {self.current_kernel_pid}.")
                        
                        var_addr = self.current_process_var_next_free_addr
                        proc_vars_and_labels[symbol_name] = var_addr # Store var in process-specific dict
                        current_pass_labels_in_scope[symbol_name] = var_addr
                        self.current_process_var_next_free_addr += size
                        if self.current_process_var_next_free_addr > self.current_process_initial_sp_val:
                            self._error(orig_line_num, current_line_content_for_error,
                                        f"Variable '{symbol_name}' allocation in process {self.current_kernel_pid} "
                                        f"(ends at {self.current_process_var_next_free_addr -1}) "
                                        f"exceeds 1KB block limit (top of block is {self.current_process_initial_sp_val -1}). Reduce variable sizes or stack size.")
                    else: # Should not happen
                        self._error(orig_line_num, current_line_content_for_error, f"Variable symbol '{symbol_name}' defined with '.' must start with '$' (for local/kernel) or '&' (for shared).")
 
                elif directive.startswith("%"):
                    continue # PC doesn't advance
                elif directive_upper == "INCLUDE":
                     continue # Already processed
                else:
                    # This line represents an actual instruction
                    if self.current_mode == 'process':
                        self.current_process_code_end_addr = pc + 1 # Next available address after this instruction
                    pc += 1
            except AssemblyError:
                 raise
            except Exception as e:
                 self._error(orig_line_num, line, f"Unexpected error during symbol parsing: {e}")
 # Original line for error messages
    def get_adres(self, label_or_sym: str, line_num: int, line_content: str, current_gen_mode: str, current_gen_pid: int) -> str:
        # --- Check for shared symbols first ---
        if label_or_sym.startswith("&") and label_or_sym in self.shared_symbols:
            return str(self.shared_symbols[label_or_sym])
        # Global symbols (@name, or $kernel_var)
        if label_or_sym.startswith(("@", "$")) and label_or_sym in self.symbols:
            return str(self.symbols[label_or_sym])

        if current_gen_mode == 'kernel':
            if label_or_sym.startswith(":") and label_or_sym in self.kernel_file_labels:
                return str(self.kernel_file_labels[label_or_sym])
            # Kernel $vars are in self.symbols, handled above.
        elif current_gen_mode == 'process' and current_gen_pid is not None:
            if current_gen_pid in self.process_file_labels:
                proc_specific_dict = self.process_file_labels[current_gen_pid]
                # Process-local :labels or $vars
                if label_or_sym.startswith((":", "$")) and label_or_sym in proc_specific_dict:
                    return str(proc_specific_dict[label_or_sym])
        
        # Fallback for global @symbols if not caught by initial check (e.g. if it didn't start with @ but was a symbol)
        # This case should ideally be covered by the first check if symbol naming is consistent.
        if label_or_sym in self.symbols: # Check global symbols again if not found in specific context
            return str(self.symbols[label_or_sym])

        self._error(line_num, line_content, f"Unknown Symbol or Label '{label_or_sym}' used as address in current context (mode: {current_gen_mode}, pid: {current_gen_pid}).")


    def get_value(self, value_str: str, line_num: int, line_content: str, current_gen_mode: str, current_gen_pid: int) -> str:
        value_str = value_str.strip()
        if not value_str:
             self._error(line_num, line_content, "Value cannot be empty.")

        # --- Handle Shared Symbols used as values ---
        if value_str.startswith("&"):
            if value_str in self.shared_symbols:
                return str(self.shared_symbols[value_str])
            else:
                self._error(line_num, line_content, f"Unknown shared symbol '{value_str}' used as value.")
        # --- Handle Constants ---
        if value_str.startswith("~"):
            if value_str in self.constants:
                return str(self.constants[value_str]) # Return the stored value
            else:
                self._error(line_num, line_content, f"Unknown constant '{value_str}'.")

        elif value_str.isdigit() or (value_str.startswith(('-', '+')) and value_str[1:].isdigit()):
            # TODO: Add range check
            return str(value_str)
        elif value_str.startswith("\\"):
            char_name = value_str[1:]
            if char_name in self.myASCII:
                return str(self.myASCII[char_name])
            else:
                self._error(line_num, line_content, f"Unknown character literal '\\{char_name}'.")
        elif value_str.startswith(("@", "$")):
            # Check process-local $vars first if in process mode
            if current_gen_mode == 'process' and current_gen_pid is not None and value_str.startswith("$"):
                if current_gen_pid in self.process_file_labels:
                    proc_specific_dict = self.process_file_labels[current_gen_pid]
                    if value_str in proc_specific_dict:
                        return str(proc_specific_dict[value_str])
            # Then check global symbols (kernel $vars or @symbols)
            if value_str in self.symbols:
                 return str(self.symbols[value_str])
            # Using a :label as an immediate value (its address)
            elif value_str.startswith(":"): # Could be kernel or process label
                # This will call get_adres, which now handles context.
                print(f"WARNING (Line ~{line_num}): Using label '{value_str}' as immediate value. Ensure this is intended.\n  > {line_content.strip()}", file=sys.stderr)
                return self.get_adres(value_str, line_num, line_content, current_gen_mode, current_gen_pid)
            self._error(line_num, line_content, f"Unknown symbol '{value_str}' used as value in current context (mode: {current_gen_mode}, pid: {current_gen_pid}).")
        else:
            self._error(line_num, line_content, f"Invalid value format '{value_str}'. Expected number, \\char, symbol (@,$,&), or constant (~).")
    
    def generate_binary(self, prg_start_for_file, output_file):
        self.binary = []
        # pc is the current absolute Program Counter for the instruction being generated.
        # It must be updated by .PROCES directives to ensure correct output addresses.
        pc = prg_start_for_file

        # Local state for generate_binary to track its context for PC calculation
        # This mirrors the state used in parse_symbols for PC management.
        # Symbol values are already resolved from parse_symbols. This is purely for PC.
        _gen_current_mode = 'kernel'
        # The prog_start for a process definition file (e.g., USER_PROCESSES_START_ADDRESS)
        _gen_current_pid = None # PID of the process block currently being generated
        # prg_start_for_file serves as the base if self.is_process_definition_file is true.

        # If the file starts with a process, pc should immediately jump.
        # We check the first actual directive.
        first_directive_checked = False
        for idx, line in enumerate(self.assembly):
            # Process line for parsing: strip inline comments, then strip leading/trailing whitespace
            line_for_first_check = line.split(';', 1)[0].strip()

            if not line_for_first_check or line_for_first_check.startswith("#"): # Handles empty lines or full-line comments
                continue
            if not first_directive_checked:
                first_directive_checked = True
                # Use the comment-stripped line for checking parts
                parts_check = line_for_first_check.split(maxsplit=1)
                if parts_check[0].upper() == ".PROCES":
                    # Temporarily parse (from original line for safety, though line_for_first_check should be fine)
                    proc_parts = line.split()
                    if len(proc_parts) >= 2:
                        try:
                            first_pid = int(proc_parts[1])
                            if self.MIN_USER_PROCESS_ID <= first_pid <= self.MAX_USER_PROCESS_ID: # prg_start_for_file is the base
                                pc = prg_start_for_file + (first_pid - 1) * self.USER_PROCESS_MEM_SIZE
                                _gen_current_mode = 'process' # Assume process mode for PC
                                _gen_current_pid = first_pid
                        except ValueError:
                            pass # Error will be caught later by full parsing
                break # Only need to check the first directive for initial PC

        # --- Second pass: Generate binary code ---
        for idx, line in enumerate(self.assembly):
            orig_line_num, orig_filename = self._line_map.get(idx, (idx + 1, self._current_filename))
            current_line_content_for_error = line # Original line for error messages

            # Process line for parsing: strip inline comments, then strip leading/trailing whitespace
            line_for_parsing = line.split(';', 1)[0].strip()

            instruction = line_for_parsing.split()
            if not instruction: continue

            op = instruction[0]
            op_upper = op.upper()
            # Handle .PROCES for PC adjustment in generate_binary
            if op_upper == ".PROCES":
                if not self.is_process_definition_file:
                    # This implies .PROCES is in a file not starting with .PROCES.
                    # parse_symbols should have caught this. If not, it's an internal error.
                    self._error(orig_line_num, current_line_content_for_error, "Internal Error: .PROCES directive in a non-process-definition file during binary generation. This should have been caught by parse_symbols.")

                _gen_current_mode = 'process' # Set mode for PC calculation
                if len(instruction) < 2:
                    self._error(orig_line_num, current_line_content_for_error, ".PROCES directive requires <id> (generate_binary pass)")
                try:
                    pid = int(instruction[1]) # We only need PID for PC calculation here
                    if not (self.MIN_USER_PROCESS_ID <= pid <= self.MAX_USER_PROCESS_ID): # prg_start_for_file is the base
                         self._error(orig_line_num, current_line_content_for_error, f"Process ID {pid} out of range ({self.MIN_USER_PROCESS_ID}-{self.MAX_USER_PROCESS_ID}) (generate_binary pass).")
                    _gen_current_pid = pid # Update current PID for this generation pass
                    pc = prg_start_for_file + (pid - 1) * self.USER_PROCESS_MEM_SIZE # Update pc
                except ValueError:
                    self._error(orig_line_num, current_line_content_for_error, f"Invalid Process ID '{instruction[1]}' (generate_binary pass).")
                continue

            # Skip other directives and comments
            if op.startswith(("@", ".", ":", "#", ";")) or op_upper == "INCLUDE" or op_upper == "EQU":
                continue

            # If this is a kernel file, and we encounter a .PROCES (which should not happen if parse_symbols worked)
            # Or if we are in process mode but _gen_current_pid is not set (should not happen if .PROCES was parsed)
            if not self.is_process_definition_file and _gen_current_mode == 'process':
                 self._error(orig_line_num, current_line_content_for_error, "Internal Error: Binary generation in process mode for a file not identified as a process definition file.")
            if _gen_current_mode == 'process' and _gen_current_pid is None:
                 self._error(orig_line_num, current_line_content_for_error, "Internal Error: Binary generation in process mode but no current PID is set.")

            # Note: current_line_num_for_error and current_line_content_for_error are already set from original line

            try:
                if op.startswith("%"):
                    if len(instruction) < 3:
                         self._error(orig_line_num, current_line_content_for_error, "Directive '%' requires a target symbol and at least one value (e.g., % $myVar 10 ~COUNT \\a)")
                    target_symbol = instruction[1]

                    if not (target_symbol.startswith("$") or target_symbol.startswith("&")):
                         self._error(orig_line_num, current_line_content_for_error, f"Target symbol '{target_symbol}' for '%' directive must be a '$' (local/kernel) or '&' (shared) variable.")
                    
                    # Use get_adres to resolve the variable's address, respecting scope.
                    # get_adres will raise an AssemblyError if the symbol is not found.
                    adres_str = self.get_adres(target_symbol, orig_line_num, current_line_content_for_error, _gen_current_mode, _gen_current_pid)
                    adres = int(adres_str)

                    values_to_write = instruction[2:]

                    for value_str in values_to_write:
                        # get_value now handles constants (~), numbers, chars, symbols (@,$)
                        value_to_write = self.get_value(value_str, orig_line_num, current_line_content_for_error, _gen_current_mode, _gen_current_pid)
                        # print(f"DEBUG ASSEMBLER: For % target '{target_symbol}', attempting to write value '{value_to_write}' (from '{value_str}') into memory address {adres}", file=sys.stderr)
                        newLine = (adres, value_to_write)
                        self.binary.append(newLine)
                        adres += 1
                    continue # Move to the next line

                # --- Handle actual instructions ---
                current_pc = pc # PC for *this* instruction
                # Error reporting uses current line's orig_line_num, current_line_content_for_error

                # --- Instruction Argument Validation (No changes needed here, relies on get_value/get_adres) ---
                num_args = len(instruction)
                expected_args = -1

                if op in ['nop', 'halt', 'ret', 'rti', 'ei', 'di']:
                    expected_args = 1
                    if num_args != expected_args: raise IndexError(f"takes no arguments")
                    newLine = (current_pc, self.instructions[op])

                elif op in ['ld', 'add', 'mul', 'sub', 'div', 'tste', 'tstg', 'dmod']:
                    expected_args = 3
                    if num_args != expected_args: raise IndexError(f"needs 2 register arguments")
                    reg1_str, reg2_str = instruction[1], instruction[2]
                    if reg1_str not in self.registers: raise ValueError(f"Invalid register '{reg1_str}'")
                    if reg2_str not in self.registers: raise ValueError(f"Invalid register '{reg2_str}'")
                    newLine = (current_pc, self.instructions[op] + self.registers[reg1_str] + self.registers[reg2_str])

                elif op in ['ldi', 'addi', 'muli', 'subi', 'divi', 'tst', 'subr', 'divr', 'andi']:
                    expected_args = 3
                    if num_args != expected_args: raise IndexError(f"needs register and value arguments")
                    reg_str, val_str = instruction[1], instruction[2]
                    if reg_str not in self.registers: raise ValueError(f"Invalid register '{reg_str}'")
                    # get_value handles constants here
                    value = self.get_value(val_str, orig_line_num, current_line_content_for_error, _gen_current_mode, _gen_current_pid)
                    newLine = (current_pc, self.instructions[op] + self.registers[reg_str] + value)

                elif op in ['ldm', 'sto', 'inc', 'dec', 'read', 'write', 'stx', 'ldx', 'xorx']:
                    expected_args = 3
                    if num_args != expected_args: raise IndexError(f"needs register and address/symbol arguments")
                    reg_str, addr_str = instruction[1], instruction[2]
                    if reg_str not in self.registers: raise ValueError(f"Invalid register '{reg_str}'")
                    # get_adres handles addresses/symbols
                    address = self.get_adres(addr_str, orig_line_num, current_line_content_for_error, _gen_current_mode, _gen_current_pid)
                    newLine = (current_pc, self.instructions[op] + self.registers[reg_str] + address)

                elif op in ['jmp', 'jmpt', 'jmpf', 'call', 'jmpx', 'callx']:
                    expected_args = 2
                    if num_args != expected_args: raise IndexError(f"needs one address/label/symbol argument")
                    addr_str = instruction[1]
                    address = self.get_adres(addr_str, orig_line_num, current_line_content_for_error, _gen_current_mode, _gen_current_pid)
                    newLine = (current_pc, self.instructions[op] + address)

                elif op in ['int', 'ctxsw']: # Added 'ctxsw'
                    expected_args = 2
                    if num_args != expected_args: raise IndexError(f"needs one integer value argument")
                    val_str = instruction[1]
                    value = self.get_value(val_str, orig_line_num, current_line_content_for_error, _gen_current_mode, _gen_current_pid)
                    newLine = (current_pc, self.instructions[op] + value)
                elif op in ['push', 'pop']:
                    expected_args = 2
                    if num_args != expected_args: raise IndexError(f"needs one register argument")
                    reg_str = instruction[1]
                    if reg_str not in self.registers: raise ValueError(f"Invalid register '{reg_str}'")
                    newLine = (current_pc, self.instructions[op] + self.registers[reg_str])
                else:
                    raise ValueError(f"Unknown instruction '{op}'")

                self.binary.append(newLine)
                pc += 1

            except (ValueError, IndexError, KeyError) as e:
                 error_detail = str(e)
                 if isinstance(e, IndexError) and expected_args != -1:
                      error_detail = f"Instruction '{op}' {error_detail}. Expected {expected_args-1}, got {num_args-1}."
                 self._error(orig_line_num, current_line_content_for_error, f"{error_detail}")
            except AssemblyError:
                 raise
            except Exception as e:
                 self._error(orig_line_num, current_line_content_for_error, f"Unexpected error during binary generation: {e}")

        # --- Write binary file ---
        try:
            writeBin(self.binary, output_file)
        except Exception as e:
             raise AssemblyError(f"Failed to write binary output to '{output_file}': {e}")


    def save_state(self):
        """Saves the current state of global symbols, constants, and the variable pointer."""
        self._saved_symbols = self.symbols.copy()
        self._saved_constants = self.constants.copy()
        self._saved_next_var_pointer = self.NextVarPointer
        self._saved_shared_symbols = self.shared_symbols.copy() # New
        self._saved_next_shared_var_pointer = self.NextSharedVarPointer # New
        # print(f"DEBUG ASSEMBLER: State saved. Symbols: {len(self._saved_symbols)}, Constants: {len(self._saved_constants)}, NextVarPointer: {self._saved_next_var_pointer}", file=sys.stderr)

    def restore_state(self):
        """
        Restores the global symbols, constants, and kernel variable pointer.
        Also resets process-specific state as it's file-scoped.
        """
        if self._saved_symbols is not None and \
           self._saved_constants is not None and \
           self._saved_next_var_pointer is not None and \
           self._saved_shared_symbols is not None and \
           self._saved_next_shared_var_pointer is not None:
            self.symbols = self._saved_symbols.copy()
            self.constants = self._saved_constants.copy()
            self.NextVarPointer = self._saved_next_var_pointer
            self.shared_symbols = self._saved_shared_symbols.copy() # New
            self.NextSharedVarPointer = self._saved_next_shared_var_pointer # New
            # kernel_file_labels and process_file_labels are cleared per assemble() call,
            # so they don't need to be part of the save/restore mechanism that persists
            # across multiple files if restore=False.
            # Reset process mode state as it's per-file/per-assembly call
            self.current_mode = 'kernel'
            self.current_kernel_pid = None
            self.is_first_directive_processed = False
            self.is_process_definition_file = False
            self._reset_process_context_for_new_block() # Full reset of process specific memory pointers
            # print(f"DEBUG ASSEMBLER: State restored. Symbols: {len(self.symbols)}, Constants: {len(self.constants)}, NextVarPointer: {self.NextVarPointer}", file=sys.stderr)
            # print(f"DEBUG ASSEMBLER: Shared Symbols: {len(self.shared_symbols)}, NextSharedVarPointer: {self.NextSharedVarPointer}", file=sys.stderr)
        else:
            # This case should ideally not be hit if save_state() is always called first in assemble()
            print("WARNING: Assembler restore_state() called but no state was saved. Current state remains unchanged.", file=sys.stderr)


    def assemble(self, filename, prog_start, output="out.bin", restore=False):
        try:
            # Save state at the beginning of every assembly attempt.
            # This state will be restored if restore=True.
            self.save_state()

            self._current_filename = filename # Store for error messages
            self.kernel_file_labels.clear() # Clear kernel labels for this new file
            self.process_file_labels.clear() # Clear all process labels for this new file
            # self.shared_symbols and self.NextSharedVarPointer are NOT cleared here.
            # They persist across calls to assemble() unless restore=True,
            # handled by save_state() and restore_state().

            # Reset assembler mode states for the new file
            self.current_mode = 'kernel' # Default to kernel mode
            self.current_kernel_pid = None
            self.is_first_directive_processed = False
            self.is_process_definition_file = False
            # current_process_base_prog_start_for_file will be set in parse_symbols if it's a process file
            self._reset_process_context_for_new_block() # Ensure all process memory pointers are nil

            self.read_source(filename)
            self.parse_source() # Parses includes, builds self.assembly and self._line_map
            self.parse_symbols(prog_start) # Parses symbols, labels, constants, and .PROCES

            # After parse_symbols, if a process was being assembled, do final checks for the last block
            if self.current_mode == 'process' and self.current_kernel_pid is not None:
                last_line_num = len(self.assembly) if self.assembly else 0
                last_line_content = self.assembly[-1] if self.assembly else "; EOF"
                self._perform_process_block_checks(last_line_num, last_line_content)

            self.generate_binary(prog_start, output)
            print(f"--- Successfully assembled {filename} -> {output} ---")
        except FileNotFoundError as e:
             print(f"ERROR: Assembly source file not found: './asm/{filename}'", file=sys.stderr)
             raise # Re-raise for the caller to handle exit
        except AssemblyError as e:
             print(str(e), file=sys.stderr)
             print(f"--- Assembly failed for {filename} ---")
             raise # Re-raise for the caller to handle exit
        except Exception as e:
             print(f"FATAL ERROR during assembly of {filename}: {e}", file=sys.stderr)
             # import traceback
             # traceback.print_exc()
             print(f"--- Assembly failed for {filename} ---")
             # Wrap unexpected errors in AssemblyError or re-raise a more specific one
             raise AssemblyError(f"Unexpected FATAL ERROR during assembly of {filename}: {e}") from e
        finally:
            if restore:
                self.restore_state()


# --- Example Usage (Illustrative) ---
if __name__ == "__main__":
    start_var_pointer = 1024 * 12
    assembler = Assembler(start_var_pointer)
    try:
        # You might define common constants in a separate file and include it
        # e.g., in constants.asm:
        # EQU ~SCREEN_WIDTH 64
        # EQU ~SCREEN_HEIGHT 32
        # EQU ~MAX_SPRITES 10
        # EQU ~KEYCODE_LEFT \Left

        # Then in your main files:
        # INCLUDE constants

        loader_start = 0
        # Assemble loader, changes persist (restore=False by default)
        assembler.assemble("loader3.asm", loader_start, "loader.bin") 
        kernel_start = 1024 # Example kernel start
        # Assemble kernel, changes persist
        assembler.assemble("kernel3.asm", kernel_start, "kernel.bin")

        program_start = 4096
        assembler.assemble("test.asm", program_start, "temp_processes.bin", restore=True)

        # Example: Assemble a test program, but restore state afterwards
        # print("\nAssembling a temporary program with state restoration...")
        # assembler.assemble("ChaosGame4.asm", program_start, "temp_chaos.bin", restore=True)
        # print(f"State after assembling temp_chaos.bin (and restoring): NextVarPointer = {assembler.NextVarPointer}")
        # Symbols/constants from ChaosGame4.asm should not be present in the main assembler state now.

        # Assemble main program, using restore=True so its symbols/constants don't affect subsequent hypothetical assemblies.
        # print("\nAssembling main program (ChaosGame4.asm)...")
        # assembler.assemble("ChaosGame4.asm", program_start, "program.bin", True)

        # Example: Assembling a process file
        user_processes_base_address = 4096 # This should match USER_PROCESSES_START_ADDRESS from cpu1.py
        print(f"\nAssembling process file (e.g., procs.asm) with base {user_processes_base_address}...")
        # assembler.assemble("procs.asm", user_processes_base_address, "processes.bin", restore=True)

        print("\nAssembly process completed.")
        print("Final Symbols Table:")
        for symbol, address in assembler.symbols.items():
            print(f"  {symbol}: {address}")
        print("Shared Symbols Table (&):")
        for symbol, address in assembler.shared_symbols.items():
            print(f"  {symbol}: {address}")
        print("Final Constants Table:") # <-- Print constants too
        for name, value in assembler.constants.items():
            print(f"  {name}: {value}")
        print(f"Next Available Kernel Variable Address: {assembler.NextVarPointer}")
        print(f"Next Available Shared Heap Address: {assembler.NextSharedVarPointer}")

    except (AssemblyError, FileNotFoundError):
        # Specific errors from assembler are already printed.
        print("\nAssembly process halted due to errors (caught in main).")
        sys.exit(1) # Ensure exit on assembly failure
    except Exception as e:
        print(f"\nAn unexpected error occurred during the assembly process: {e}")
        sys.exit(1) # Ensure exit on other unexpected failures
