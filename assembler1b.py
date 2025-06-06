# /home/janrutger/git/STERN-1/assembler1a.py
from FileIO import readFile, writeBin
from stringtable import makechars
import sys # Import sys for stderr

# --- Optional: Define a custom exception for cleaner handling ---
class AssemblyError(Exception):
    """Custom exception for assembly errors."""
    pass
# --- End Optional ---

class Assembler:
    def __init__(self, var_pointer: int):
        self.NextVarPointer = var_pointer
        self.instructions = {
            "nop": '10', "halt": '11', "ret": '12', "ei": '13', "di": '14', "rti": '15',
            "jmpf": '20', "jmpt": '21', "jmp": '22', "jmpx": '23', "call": '24', "callx": '25', "int": '26',
            "ld": '30', "ldi": '31', "ldm": '32', "ldx": '33',
            "sto": '40', "stx": '41',
            "add": '50', "addi": '51', "sub": '52', "subi": '53', "subr": '54',
            "mul": '60', "muli": '61', "div": '62', "divi": '63', "divr": '64', "dmod": '65',
            "tst": '70', "tste": '71', "tstg": '72',
            "inc": '80', "dec": '81',
            "andi": '90', "xorx": '91', "read": '98', "write": '99'
        }
        self.registers = {
            "I": '0', "A": '1', "B": '2', "C": '3', "K": '4', "L": '5', "M": '6', "X": '7', "Y": '8', "Z": '9'
        }
        self.myASCII = makechars()
        self.symbols = {} # Global symbols (@, $)
        self.labels = {}  # Local labels (:) - cleared per file
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

    # --- Helper to format and raise/exit with error ---
    def _error(self, line_num, line_content, message):
        # Ensure line_num is displayed correctly, even if 0
        display_line_num = line_num if line_num is not None else '?'
        error_message = f"ERROR in '{self._current_filename}', Line ~{display_line_num}: {message}\n  > {line_content.strip()}"
        raise AssemblyError(error_message)
    # --- End Helper ---

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


    def parse_symbols(self, prg_start):
        pc = prg_start
        current_pass_labels = {}

        for idx, line in enumerate(self.assembly):
            orig_line_num, orig_filename = self._line_map.get(idx, (idx + 1, self._current_filename))

            if not line or line.startswith("#") or line.startswith(";"):
                continue

            parts = line.split(maxsplit=2) # Split max 3: directive/label, name/arg1, value/arg2
            directive = parts[0]

            try:
                # --- Handle EQU Directive ---
                if directive.upper() == "EQU":
                    if len(parts) != 3:
                        self._error(orig_line_num, line, "EQU directive requires a constant name and a value (e.g., EQU ~NAME 123)")
                    const_name = parts[1]
                    value_str = parts[2]

                    if not const_name.startswith("~"):
                        self._error(orig_line_num, line, f"Constant name '{const_name}' must start with '~'.")

                    if const_name in self.constants:
                        # Allow redefinition? Usually not for constants. Error if already defined.
                        self._error(orig_line_num, line, f"Constant '{const_name}' already defined.")

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
                            self._error(orig_line_num, line, f"Unknown character literal '{value_str_stripped}' for constant value.")
                    # Add support for other constants? e.g., EQU ~WIDTH ~BASE_WIDTH+10 (More complex)
                    # elif value_str_stripped.startswith("~"): ... look up in self.constants ...
                    else:
                        self._error(orig_line_num, line, f"Invalid value '{value_str}' for EQU. Only numbers (e.g., 123) and character literals (e.g., \\a) are currently supported.")
                    # --- End Resolve Value ---

                    if resolved_value is not None:
                        self.constants[const_name] = resolved_value
                    # EQU does not advance PC
                    continue # Move to next line

                # --- Existing Symbol/Label/Variable Handling ---
                elif directive.startswith("@"):
                    symbol_name = directive
                    if symbol_name in self.symbols:
                        self._error(orig_line_num, line, f"Symbol '{symbol_name}' already defined (at address {self.symbols[symbol_name]}) in a previous assembly pass.")
                    self.symbols[symbol_name] = pc
                elif directive.startswith(":"):
                    label_name = directive
                    if label_name in current_pass_labels:
                         self._error(orig_line_num, line, f"Label '{label_name}' already defined in this file/pass.")
                    self.labels[label_name] = pc
                    current_pass_labels[label_name] = pc
                elif directive.startswith("."):
                    if len(parts) < 3:
                        self._error(orig_line_num, line, "Directive '.' requires a symbol name and size (e.g., . $myVar 1)")
                    symbol_name = parts[1]
                    size_str = parts[2]
                    try:
                        size = int(size_str)
                        if size <= 0: raise ValueError("Size must be positive")
                    except ValueError:
                         self._error(orig_line_num, line, f"Invalid size '{size_str}' for directive '.'. Must be a positive integer.")

                    if not symbol_name.startswith("$"):
                         self._error(orig_line_num, line, f"Variable symbol '{symbol_name}' defined with '.' must start with '$'.")

                    if symbol_name in self.symbols:
                         self._error(orig_line_num, line, f"Symbol '{symbol_name}' already defined (at address {self.symbols[symbol_name]}, possibly in a previous pass).")

                    self.symbols[symbol_name] = self.NextVarPointer
                    self.NextVarPointer += size
                elif directive.startswith("%"):
                    continue # PC doesn't advance
                elif directive.upper() == "INCLUDE":
                     continue # Already processed
                else:
                    # This line represents an actual instruction
                    pc += 1
            except AssemblyError:
                 raise
            except Exception as e:
                 self._error(orig_line_num, line, f"Unexpected error during symbol parsing: {e}")


    # --- get_adres remains the same ---
    def get_adres(self, label: str, line_num: int, line_content: str) -> str:
        if label.startswith(":") and label in self.labels:
            return str(self.labels[label])
        elif label.startswith(("@", "$")) and label in self.symbols:
            return str(self.symbols[label])
        # --- Constants generally shouldn't be addresses, but you could add support if needed ---
        # elif label.startswith("~") and label in self.constants:
        #     # This implies the constant holds an address value. Use with caution.
        #     print(f"WARNING (Line ~{line_num}): Using constant '{label}' as address. Ensure this is intended.\n  > {line_content.strip()}", file=sys.stderr)
        #     return str(self.constants[label])
        else:
            self._error(line_num, line_content, f"Unknown Symbol, Label, or invalid Address reference '{label}'.")


    def get_value(self, value_str: str, line_num: int, line_content: str) -> str:
        value_str = value_str.strip()
        if not value_str:
             self._error(line_num, line_content, "Value cannot be empty.")

        # --- Handle Constants ---
        if value_str.startswith("~"):
            if value_str in self.constants:
                return str(self.constants[value_str]) # Return the stored value
            else:
                self._error(line_num, line_content, f"Unknown constant '{value_str}'.")
        # --- End Handle Constants ---

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
             if value_str in self.symbols:
                 return str(self.symbols[value_str])
             else:
                 if value_str.startswith(":") and value_str in self.labels:
                      print(f"WARNING (Line ~{line_num}): Using label '{value_str}' as immediate value. Ensure this is intended.\n  > {line_content.strip()}", file=sys.stderr)
                      return str(self.labels[value_str])
                 else:
                      self._error(line_num, line_content, f"Unknown symbol '{value_str}' used as value.")
        else:
            self._error(line_num, line_content, f"Invalid value format '{value_str}'. Expected number, \\char, symbol (@,$), or constant (~).")

    # --- generate_binary remains largely the same, but benefits from updated get_value/get_adres ---
    def generate_binary(self, prg_start, output_file):
        self.binary = []
        pc = prg_start
        pc_to_idx_map = {} # Map PC to index in self.assembly for error reporting

        # --- First pass: Build PC to assembly index map ---
        temp_pc = prg_start
        for idx, line in enumerate(self.assembly):
            # Skip non-instruction lines for PC mapping
            # Also skip EQU as it doesn't generate code at a PC
            if not line or line.startswith(("@", ".", ":", "%", "#", ";")) or line.upper() == "INCLUDE" or line.upper().startswith("EQU"):
                continue
            else:
                pc_to_idx_map[temp_pc] = idx
                temp_pc += 1

        # --- Second pass: Generate binary code ---
        for idx, line in enumerate(self.assembly):
            orig_line_num, orig_filename = self._line_map.get(idx, (idx + 1, self._current_filename))

            instruction = line.split()
            if not instruction: continue

            op = instruction[0]

            # Skip directives and comments (including EQU now)
            if op.startswith(("@", ".", ":", "#", ";")) or op.upper() == "INCLUDE" or op.upper() == "EQU":
                continue

            # Use current index/line info for directives like '%'
            current_line_num_for_error = orig_line_num
            current_line_content_for_error = line

            try:
                if op.startswith("%"):
                    if len(instruction) < 3:
                         self._error(current_line_num_for_error, current_line_content_for_error, "Directive '%' requires a target symbol and at least one value (e.g., % $myVar 10 ~COUNT \\a)")
                    target_symbol = instruction[1]
                    if not target_symbol.startswith("$") or target_symbol not in self.symbols:
                         self._error(current_line_num_for_error, current_line_content_for_error, f"Invalid or undefined target symbol '{target_symbol}' for '%'. Must be a defined '$' variable.")

                    adres = int(self.symbols[target_symbol])
                    values_to_write = instruction[2:]

                    for value_str in values_to_write:
                        # get_value now handles constants (~), numbers, chars, symbols (@,$)
                        value_to_write = self.get_value(value_str, current_line_num_for_error, current_line_content_for_error)
                        # print(f"DEBUG ASSEMBLER: For % target '{target_symbol}', attempting to write value '{value_to_write}' (from '{value_str}') into memory address {adres}", file=sys.stderr)
                        newLine = (adres, value_to_write)
                        self.binary.append(newLine)
                        adres += 1
                    continue # Move to the next line

                # --- Handle actual instructions ---
                current_pc = pc # PC for *this* instruction
                mapped_idx = pc_to_idx_map.get(current_pc)
                if mapped_idx is not None:
                     orig_line_num_instr, _ = self._line_map.get(mapped_idx, (orig_line_num, orig_filename))
                     line_content_instr = self.assembly[mapped_idx]
                     current_line_num_for_error = orig_line_num_instr
                     current_line_content_for_error = line_content_instr
                # else: Fallback (should be rare)

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
                    value = self.get_value(val_str, current_line_num_for_error, current_line_content_for_error)
                    newLine = (current_pc, self.instructions[op] + self.registers[reg_str] + value)

                elif op in ['ldm', 'sto', 'inc', 'dec', 'read', 'write', 'stx', 'ldx', 'xorx']:
                    expected_args = 3
                    if num_args != expected_args: raise IndexError(f"needs register and address/symbol arguments")
                    reg_str, addr_str = instruction[1], instruction[2]
                    if reg_str not in self.registers: raise ValueError(f"Invalid register '{reg_str}'")
                    # get_adres handles addresses/symbols
                    address = self.get_adres(addr_str, current_line_num_for_error, current_line_content_for_error)
                    newLine = (current_pc, self.instructions[op] + self.registers[reg_str] + address)

                elif op in ['jmp', 'jmpt', 'jmpf', 'call', 'jmpx', 'callx']:
                    expected_args = 2
                    if num_args != expected_args: raise IndexError(f"needs one address/label/symbol argument")
                    addr_str = instruction[1]
                    address = self.get_adres(addr_str, current_line_num_for_error, current_line_content_for_error)
                    newLine = (current_pc, self.instructions[op] + address)

                elif op in ['int']:
                    expected_args = 2
                    if num_args != expected_args: raise IndexError(f"needs one integer value argument")
                    val_str = instruction[1]
                    # get_value handles constants here too
                    value = self.get_value(val_str, current_line_num_for_error, current_line_content_for_error)
                    newLine = (current_pc, self.instructions[op] + value)

                else:
                    raise ValueError(f"Unknown instruction '{op}'")

                self.binary.append(newLine)
                pc += 1

            except (ValueError, IndexError, KeyError) as e:
                 error_detail = str(e)
                 if isinstance(e, IndexError) and expected_args != -1:
                      error_detail = f"Instruction '{op}' {error_detail}. Expected {expected_args-1}, got {num_args-1}."
                 self._error(current_line_num_for_error, current_line_content_for_error, f"{error_detail}")
            except AssemblyError:
                 raise
            except Exception as e:
                 self._error(current_line_num_for_error, current_line_content_for_error, f"Unexpected error during binary generation: {e}")

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
        # print(f"DEBUG ASSEMBLER: State saved. Symbols: {len(self._saved_symbols)}, Constants: {len(self._saved_constants)}, NextVarPointer: {self._saved_next_var_pointer}", file=sys.stderr)

    def restore_state(self):
        """Restores the global symbols, constants, and variable pointer to the last saved state."""
        if self._saved_symbols is not None and \
           self._saved_constants is not None and \
           self._saved_next_var_pointer is not None:
            self.symbols = self._saved_symbols.copy()
            self.constants = self._saved_constants.copy()
            self.NextVarPointer = self._saved_next_var_pointer
            print(f"DEBUG ASSEMBLER: State restored. Symbols: {len(self.symbols)}, Constants: {len(self.constants)}, NextVarPointer: {self.NextVarPointer}", file=sys.stderr)
        else:
            # This case should ideally not be hit if save_state() is always called first in assemble()
            print("WARNING: Assembler restore_state() called but no state was saved. Current state remains unchanged.", file=sys.stderr)


    def assemble(self, filename, prog_start, output="out.bin", restore=False):
        # print(f"\n--- Assembling {filename} ---")
        
        try:
            # Save state at the beginning of every assembly attempt.
            # This state will be restored if restore=True.
            self.save_state()

            self._current_filename = filename # Store for error messages
            self.labels = {} # Clear labels for this specific assembly pass
            # self.constants are handled by save_state/restore_state

            self.read_source(filename)
            self.parse_source() # Parses includes, builds self.assembly and self._line_map
            self.parse_symbols(prog_start) # Parses symbols, labels, AND constants
            self.generate_binary(prog_start, output)
            print(f"--- Successfully assembled {filename} -> {output} ---")

        except FileNotFoundError as e:
             print(f"ERROR: Assembly source file not found: {filename}", file=sys.stderr)
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
                # print(f"DEBUG ASSEMBLER: Restoring state after assembling {filename}", file=sys.stderr)
                self.restore_state()


# --- Example Usage (Illustrative) ---
if __name__ == "__main__":
    start_var_pointer = 1024 * 12
    assembler = Assembler(12311)
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
        assembler.assemble("loader2.asm", loader_start, "loader.bin") 
        kernel_start = 512
        # Assemble kernel, changes persist
        assembler.assemble("kernel2.asm", kernel_start, "kernel.bin") 
        
        program_start = 4096 + 512

        # Example: Assemble a test program, but restore state afterwards
        # print("\nAssembling a temporary program with state restoration...")
        # assembler.assemble("ChaosGame4.asm", program_start, "temp_chaos.bin", restore=True)
        # print(f"State after assembling temp_chaos.bin (and restoring): NextVarPointer = {assembler.NextVarPointer}")
        # Symbols/constants from ChaosGame4.asm should not be present in the main assembler state now.

        # Assemble main program, using restore=True so its symbols/constants don't affect subsequent hypothetical assemblies.
        print("\nAssembling main program (out.asm)...")
        assembler.assemble("out.asm", program_start, "program.bin", True) 

        print("\nAssembly process completed.")
        print("Final Symbols Table:")
        for symbol, address in assembler.symbols.items():
            print(f"  {symbol}: {address}")
        print("Final Constants Table:") # <-- Print constants too
        for name, value in assembler.constants.items():
            print(f"  {name}: {value}")
        print(f"Next Available Variable Address: {assembler.NextVarPointer}")

    except (AssemblyError, FileNotFoundError):
        # Specific errors from assembler are already printed.
        print("\nAssembly process halted due to errors (caught in main).")
        sys.exit(1) # Ensure exit on assembly failure
    except Exception as e:
        print(f"\nAn unexpected error occurred during the assembly process: {e}")
        sys.exit(1) # Ensure exit on other unexpected failures
