from lexV2 import Lexer, LexerError
from emitV2 import Emitter
from parseV2 import Parser, ParserError
import sys

def main():
    print("STACKS RPN Compiler") # General name, can be adapted for STERN-1 later

    source_file_path = "/home/janrutger/git/STERN-1/STACKS/program.stacks" # Default input file
    output_file_path = "/home/janrutger/git/STERN-1/STACKS/out.asm"      # Default output file (consistent with Emitter's original hardcoding)

    if len(sys.argv) != 2:
        print(f"Info: No source file provided. \nUsing default input '{source_file_path}' \nand  default output '{output_file_path}'.")
    else:
        source_file_path = sys.argv[1]
        # Create output filename by changing extension of source to .asm
        if '.' in source_file_path:
            output_file_path = source_file_path.rsplit('.', 1)[0] + ".asm"
        else:
            output_file_path = source_file_path + ".asm"
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
