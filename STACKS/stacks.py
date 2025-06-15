from lexV3 import Lexer, LexerError
from emitV3 import Emitter
from parseV3 import Parser, ParserError
import os # Import os module for path manipulation
import sys

def main():
    print("STACKS RPN Compiler") # General name, can be adapted for STERN-1 later

    source_file_path = "/home/janrutger/git/STERN-1/STACKS/src/processes.stacks" # Default input file
    output_file_path = "/home/janrutger/git/STERN-1/asm/out.asm"               # Default output file (consistent with Emitter's original hardcoding)
    output_directory = "/home/janrutger/git/STERN-1/asm" # Target directory for output

    if len(sys.argv) != 2:
        # Use default input, construct default output filename
        base_name = os.path.basename(source_file_path)
        name_without_ext, _ = os.path.splitext(base_name)
        output_filename = name_without_ext + ".asm"
        output_file_path = os.path.join(output_directory, output_filename)
        print(f"Info: No source file provided. \nUsing default input '{source_file_path}' \nand  default output '{output_file_path}'.")
    else:
        source_file_path = sys.argv[1]
        # Use provided input, construct output filename based on input filename
        base_name = os.path.basename(source_file_path)
        name_without_ext, _ = os.path.splitext(base_name)
        output_filename = name_without_ext + ".asm"
        output_file_path = os.path.join(output_directory, output_filename) # Construct the full path
        print(f"Info: Compiling source file '{source_file_path}' to '{output_file_path}'.")

    try:
        with open(source_file_path, 'r') as inputFile:
            input_code = inputFile.read()

        # Initialize the lexer, emitter, and parser.
        lexer = Lexer(input_code)
        emitter = Emitter(output_file_path) # Pass the determined output path
        parser = Parser(lexer, emitter)

        parser.program() # Start the parser.
        emitter.writeFile() # Write the output to file.
        print(f"Compiling completed. Output written to {output_file_path}")

    except FileNotFoundError:
        sys.exit(f"Error: Source file not found: {source_file_path}")
    except (LexerError, ParserError) as e:
        sys.exit(f"Compilation Error: {e}")
    except Exception as e:
        # This will catch other unexpected errors, e.g., issues writing the output file.
        sys.exit(f"An unexpected error occurred: {e}")
main()
