# /home/janrutger/git/STERN-1/assembler.py
from FileIO import readFile, writeBin
from stringtable import makechars

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
        # --- Initialize symbols and labels here ---
        self.symbols = {} # Persists across assemble calls
        self.labels = {}  # Cleared for each assemble call
        # --- End Initialization ---
        self.assembly = []
        self.binary = []
        self.source = [] # Keep track of the source lines for the current file

    def read_source(self, sourcefile):
        # Read source for the current file
        self.source = readFile(sourcefile, 1)

    def include_source(self, filename):
        # Helper to read included files
        try:
            return readFile(filename, 1)
        except FileNotFoundError:
            # Provide more context in the error message
            print(f"ERROR: Include file not found: {filename}")
            exit(f"ERROR: Include file not found: {filename}")
        except Exception as e:
            print(f"ERROR: Could not read include file {filename}: {e}")
            exit(f"ERROR: Could not read include file {filename}: {e}")


    def parse_source(self):
        # Parse only the self.source read by read_source
        self.assembly = [] # Clear assembly lines for the current file
        files_to_include = []
        for line_num, line in enumerate(self.source, 1): # Add line numbers for errors
            line = line.strip() # Ensure leading/trailing whitespace is removed
            if not line or line.startswith("#") or line.startswith(";"):
                continue
            if line.upper().startswith("INCLUDE"): # Make case-insensitive
                parts = line.split()
                if len(parts) == 2:
                    # Assume includes are relative to an 'incl' subdir within 'asm'
                    include_path = f"./incl/{parts[1]}.asm"
                    files_to_include.append(include_path)
                else:
                    exit(f"ERROR (Line {line_num}): INCLUDE instruction requires exactly one filename argument")
            else:
                self.assembly.append(line)

        # Process includes after parsing the main file content
        for file_path in files_to_include:
            included_source = self.include_source(file_path)
            for include_line_num, line in enumerate(included_source, 1):
                line = line.strip()
                if not line or line.startswith("#") or line.startswith(";"):
                    continue
                # Prepend included lines to handle dependencies correctly? Or append?
                # Appending is usually safer unless includes define fundamental constants needed early.
                self.assembly.append(line)
                # TODO: Consider how to handle labels/symbols within included files if needed.
                # Current approach treats them as part of the main file's assembly pass.

    def parse_symbols(self, prg_start):
        # Parses symbols (@, .) and labels (:) for the current self.assembly
        # Labels are stored in self.labels (cleared per 'assemble' call)
        # Symbols are stored in self.symbols (persists across 'assemble' calls)
        pc = prg_start
        # Note: self.labels is cleared in the 'assemble' method before this is called

        current_pass_labels = {} # Track labels defined *only* in this pass to detect local duplicates

        for line_num, line in enumerate(self.assembly, 1): # Add line numbers for errors
            line = line.strip() # Should already be stripped, but belt-and-suspenders
            if not line: continue # Skip empty lines that might have crept in

            parts = line.split(maxsplit=2) # Split into max 3 parts: directive/label, name, value(s)
            directive = parts[0]

            if directive.startswith("@"): # Module/Entry Point Symbol
                symbol_name = directive
                if symbol_name in self.symbols:
                    # Allow redefinition ONLY if the address is the same? Or disallow completely?
                    # Safest is to disallow redefinition across files.
                    exit(f"ERROR (Line {line_num}): Symbol '{symbol_name}' already defined in a previous assembly pass.")
                self.symbols[symbol_name] = pc
                # Don't increment PC for symbols/labels themselves
            elif directive.startswith(":"): # Label
                label_name = directive
                if label_name in current_pass_labels:
                     exit(f"ERROR (Line {line_num}): Label '{label_name}' already defined in this file/pass.")
                if label_name in self.labels:
                     # This case should ideally not happen if self.labels is cleared correctly,
                     # but check just in case.
                     print(f"WARNING (Line {line_num}): Label '{label_name}' collision detected. Overwriting. Check clearing logic.")
                self.labels[label_name] = pc
                current_pass_labels[label_name] = pc # Track for local duplicates
                # Don't increment PC for symbols/labels themselves
            elif directive.startswith("."): # Variable/Data Definition Symbol
                if len(parts) < 3:
                    exit(f"ERROR (Line {line_num}): Directive '.' requires a symbol name and size (e.g., . myVar 1)")
                symbol_name = parts[1]
                try:
                    size = int(parts[2])
                    if size <= 0:
                         raise ValueError("Size must be positive")
                except ValueError:
                     exit(f"ERROR (Line {line_num}): Invalid size '{parts[2]}' for directive '.'. Must be a positive integer.")

                if not symbol_name.startswith("$"):
                     print(f"WARNING (Line {line_num}): Variable symbol '{symbol_name}' defined with '.' does not start with '$'. Is this intended?")
                     # Decide whether to enforce '$' prefix or just warn. Enforcing might be safer.
                     # exit(f"ERROR (Line {line_num}): Variable symbol '{symbol_name}' must start with '$'")

                if symbol_name in self.symbols:
                     exit(f"ERROR (Line {line_num}): Symbol '{symbol_name}' already defined (possibly in a previous pass).")

                self.symbols[symbol_name] = self.NextVarPointer
                self.NextVarPointer += size # Allocate memory space
                # Don't increment PC for variable definitions
            elif directive.startswith("%"): # Data Initialization Directive
                # This directive doesn't define a label/symbol at a PC location,
                # it specifies data to be written later. PC doesn't advance here.
                continue
            elif directive.upper() == "INCLUDE": # Skip include directives during symbol parsing
                 continue
            elif directive.startswith("#") or directive.startswith(";"): # Skip comments
                 continue
            else:
                # This line represents an actual instruction that will occupy memory
                pc += 1

        # print(f"Symbols after pass: {self.symbols}")
        # print(f"Labels for this pass: {self.labels}")
        # print(f"Next Variable Pointer: {self.NextVarPointer}")


    def get_adres(self, label: str, line_num: int) -> str:
        # Look for labels first (local to current pass)
        if label.startswith(":") and label in self.labels:
            return str(self.labels[label])
        # Then look for symbols (global across passes)
        elif label.startswith(("@", "$")) and label in self.symbols:
            return str(self.symbols[label])
        else:
            exit(f"ERROR (Line ~{line_num}): Unknown Symbol or Label '{label}'. Check spelling and definition.")

    def get_value(self, value_str: str, line_num: int) -> str:
        value_str = value_str.strip()
        if not value_str:
             exit(f"ERROR (Line ~{line_num}): Empty value string encountered.")

        # Handle immediate numbers (decimal)
        if value_str.isdigit() or (value_str.startswith(('-', '+')) and value_str[1:].isdigit()):
            # TODO: Add range check if your architecture has limits on immediate values
            return str(value_str)
        # Handle character literals (e.g., \a, \Return)
        elif value_str.startswith("\\"):
            char_name = value_str[1:]
            if char_name in self.myASCII:
                return str(self.myASCII[char_name])
            else:
                exit(f"ERROR (Line ~{line_num}): Unknown character literal '\\{char_name}'.")
        # Handle symbols representing addresses (used as values)
        elif value_str.startswith(("@", "$")):
             # Check if it's a defined symbol first
             if value_str in self.symbols:
                 return str(self.symbols[value_str])
             else:
                 # It might be intended as a label address, though less common as immediate value
                 if value_str.startswith(":") and value_str in self.labels:
                      print(f"WARNING (Line ~{line_num}): Using label '{value_str}' as immediate value. Ensure this is intended.")
                      return str(self.labels[value_str])
                 else:
                      exit(f"ERROR (Line ~{line_num}): Unknown symbol '{value_str}' used as value.")
        # Handle potential hex/binary literals if needed (e.g., 0xFF, 0b1010)
        # elif value_str.startswith("0x"): ...
        # elif value_str.startswith("0b"): ...
        else:
            exit(f"ERROR (Line ~{line_num}): Invalid value format '{value_str}'. Expected number, \\char, or symbol.")

    def generate_binary(self, prg_start, output_file):
        self.binary = []
        pc = prg_start
        line_num_map = {} # Map PC back to original source line approx

        # First pass to map PC to line numbers (approximate)
        temp_pc = prg_start
        current_line_idx = 0
        for line in self.assembly:
             current_line_idx += 1
             instr = line.split(maxsplit=1)[0] # Get the first part
             if not instr or instr.startswith(("@", ".", ":", "%", "#", ";")) or instr.upper() == "INCLUDE":
                 continue
             else:
                 line_num_map[temp_pc] = current_line_idx
                 temp_pc += 1


        # Second pass: Generate binary code
        for line_idx, line in enumerate(self.assembly, 1):
            instruction = line.split()
            if not instruction: continue # Skip empty lines

            op = instruction[0]

            # Skip directives and comments
            if op.startswith(("@", ".", ":", "#", ";")) or op.upper() == "INCLUDE":
                continue

            # Handle Data Initialization Directive '%'
            elif op.startswith("%"):
                if len(instruction) < 3:
                     exit(f"ERROR (Line {line_idx}): Directive '%' requires a target symbol and at least one value (e.g., % $myVar 10 20 \\a)")
                target_symbol = instruction[1]
                if not target_symbol.startswith("$") or target_symbol not in self.symbols:
                     exit(f"ERROR (Line {line_idx}): Invalid or undefined target symbol '{target_symbol}' for '%'. Must be a defined '$' variable.")

                adres = int(self.symbols[target_symbol])
                values_to_write = instruction[2:]

                # Check if enough space was allocated by '.'
                # This requires knowing the size allocated by '.', which we don't store directly.
                # We could potentially calculate it or store it alongside the symbol.
                # For now, we assume the user allocated enough space.

                for value_str in values_to_write:
                    try:
                        value_to_write = self.get_value(value_str, line_idx)
                        # TODO: Add check here if 'adres' exceeds allocated space for target_symbol
                        newLine = (adres, value_to_write)
                        self.binary.append(newLine)
                        adres += 1
                    except SystemExit as e: # Catch exit from get_value
                         print(f" --> Error occurred while processing data for '{target_symbol}'")
                         exit(e)
                    except Exception as e:
                         exit(f"ERROR (Line {line_idx}): Unexpected error processing value '{value_str}' for '%': {e}")
                continue # Move to the next line after processing '%'

            # --- Handle actual instructions ---
            current_pc = pc # PC for *this* instruction
            line_num_for_error = line_num_map.get(current_pc, line_idx) # Use mapped or current index

            try:
                if op in ['nop', 'halt', 'ret', 'rti', 'ei', 'di']:
                    if len(instruction) != 1: raise IndexError(f"Instruction '{op}' takes no arguments.")
                    newLine = (current_pc, self.instructions[op])
                    self.binary.append(newLine)
                    pc += 1
                elif op in ['ld', 'add', 'mul', 'sub', 'div', 'tste', 'tstg', 'dmod']:
                    if len(instruction) != 3: raise IndexError(f"Instruction '{op}' needs 2 register arguments.")
                    if instruction[1] not in self.registers: raise ValueError(f"Invalid register '{instruction[1]}'")
                    if instruction[2] not in self.registers: raise ValueError(f"Invalid register '{instruction[2]}'")
                    newLine = (current_pc, self.instructions[op] + self.registers[instruction[1]] + self.registers[instruction[2]])
                    self.binary.append(newLine)
                    pc += 1
                elif op in ['ldi', 'addi', 'muli', 'subi', 'divi', 'tst', 'subr', 'divr', 'andi']:
                    if len(instruction) != 3: raise IndexError(f"Instruction '{op}' needs register and value arguments.")
                    if instruction[1] not in self.registers: raise ValueError(f"Invalid register '{instruction[1]}'")
                    value = self.get_value(instruction[2], line_num_for_error)
                    newLine = (current_pc, self.instructions[op] + self.registers[instruction[1]] + value)
                    self.binary.append(newLine)
                    pc += 1
                elif op in ['ldm', 'sto', 'inc', 'dec', 'read', 'write', 'stx', 'ldx', 'xorx']:
                    if len(instruction) != 3: raise IndexError(f"Instruction '{op}' needs register and address/symbol arguments.")
                    if instruction[1] not in self.registers: raise ValueError(f"Invalid register '{instruction[1]}'")
                    address = self.get_adres(instruction[2], line_num_for_error)
                    newLine = (current_pc, self.instructions[op] + self.registers[instruction[1]] + address)
                    self.binary.append(newLine)
                    pc += 1
                elif op in ['jmp', 'jmpt', 'jmpf', 'call', 'jmpx', 'callx']:
                    if len(instruction) != 2: raise IndexError(f"Instruction '{op}' needs one address/label/symbol argument.")
                    address = self.get_adres(instruction[1], line_num_for_error)
                    newLine = (current_pc, self.instructions[op] + address)
                    self.binary.append(newLine)
                    pc += 1
                elif op in ['int']:
                    if len(instruction) != 2: raise IndexError(f"Instruction '{op}' needs one integer value argument.")
                    value = self.get_value(instruction[1], line_num_for_error) # Should resolve to a number
                    # Optional: Check if value is within valid interrupt range
                    newLine = (current_pc, self.instructions[op] + value)
                    self.binary.append(newLine)
                    pc += 1
                else:
                    raise ValueError(f"Unknown instruction '{op}'")

            except (ValueError, IndexError, KeyError, SystemExit) as e:
                 # Catch errors during generation and provide context
                 exit(f"ERROR (Line ~{line_num_for_error}: '{line}'): {e}")
            except Exception as e:
                 # Catch unexpected errors
                 exit(f"FATAL ERROR (Line ~{line_num_for_error}: '{line}'): Unexpected error during binary generation: {e}")


        # Write the generated binary to the output file
        try:
            writeBin(self.binary, output_file)
        except Exception as e:
            exit(f"ERROR: Failed to write binary output to '{output_file}': {e}")
        # print(f"Binary for {output_file}: {len(self.binary)} lines")

    def assemble(self, filename, prog_start, output="out.bin"):
        print(f"\n--- Assembling {filename} ---")
        # --- Clear labels for this specific assembly pass ---
        self.labels = {}
        # --- Symbols (self.symbols) and NextVarPointer persist ---

        try:
            self.read_source(filename)
            self.parse_source() # Parses includes as well
            self.parse_symbols(prog_start) # Parses symbols (@,$) and labels (:) for current assembly
            self.generate_binary(prog_start, output) # Generates code using current labels and all symbols
            print(f"--- Successfully assembled {filename} -> {output} ---")
        except FileNotFoundError:
             # Catch file not found specifically for the main assembly file
             exit(f"ERROR: Assembly source file not found: {filename}")
        except SystemExit as e:
             # Catch exits from sub-methods (which should print their own errors)
             print(f"--- Assembly failed for {filename} ---")
             exit(1) # Ensure the program exits on assembly error
        except Exception as e:
             # Catch any other unexpected errors during assembly
             print(f"FATAL ERROR during assembly of {filename}: {e}")
             # Consider printing traceback here for debugging
             # import traceback
             # traceback.print_exc()
             exit(1)


# Example usage (similar to main.py)
if __name__ == "__main__":
    # Initial pointer for variables (adjust as needed based on memory map)
    start_var_pointer = 1024 * 8

    # Create ONE assembler instance
    assembler = Assembler(start_var_pointer)

    try:
        # Assemble loader - defines its symbols and labels
        loader_start = 0
        assembler.assemble("loader2.asm", loader_start, "loader.bin")

        # Assemble kernel - defines its symbols/labels, can use loader's symbols
        kernel_start = 512 # Example start address
        assembler.assemble("kernel2.asm", kernel_start, "kernel.bin")

        # Assemble program - defines its symbols/labels, can use loader's & kernel's symbols
        program_start = 4096 + 512 # Example start address
        # assembler.assemble("spritewalker.asm", program_start, "program.bin")
        assembler.assemble("ChaosGame.asm", program_start, "program.bin")

        print("\nAssembly process completed.")
        print("Final Symbols Table:")
        for symbol, address in assembler.symbols.items():
            print(f"  {symbol}: {address}")
        print(f"Next Available Variable Address: {assembler.NextVarPointer}")

    except SystemExit:
        print("\nAssembly process halted due to errors.")
    except Exception as e:
        print(f"\nAn unexpected error occurred during the assembly process: {e}")

