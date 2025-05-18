# /home/janrutger/git/STERN-1/STACKS/stacks_codegen.py
from parser_ast import (
    ASTNode, ProgramNode, LiteralNode, IdentifierNode, OperatorNode,
    FunctionCallNode, ExpressionStatementNode, DefineBlockNode,
    ValueDefinitionNode, ArrayDefinitionNode, FunctionDefinitionNode,
    LabelNode, GotoNode
    # ... import other AST nodes as you define/need them
)
from stacks_lexer import TokenType # For checking LiteralNode.type or OperatorNode.op_type

class CodeGenerator:
    def __init__(self):
        self.assembly_code = []  # Holds the main code instructions
        self.data_segment = []   # For variable/data definitions (e.g., .word, .block, .string)
        self.label_count = 0     # To generate unique labels for strings, etc.
        self.runtime_initialized = False # To track if basic runtime setup is done

        # Symbol table: In a more complex compiler, this would be built
        # during semantic analysis and passed in or accessed.
        # It would map variable/function names to addresses or other info.
        # For now, we'll often map names directly to assembly labels.
        self.symbol_table = {}

    def _generate_unique_label(self, prefix="L_"):
        """Generates a unique label."""
        self.label_count += 1
        return f"{prefix}{self.label_count}"

    def _add_code(self, instruction: str):
        """Adds a line of assembly code to the current code segment."""
        self.assembly_code.append(instruction)

    def _add_data(self, definition: str):
        """Adds a line to the data segment."""
        self.data_segment.append(definition)

    def generate(self, node: ProgramNode) -> str:
        """Generates assembly code for the entire program AST."""
        if not self.runtime_initialized:
            self._initialize_runtime_and_data_segment()

        self.visit(node) # Start visiting the root ProgramNode

        # Construct the final assembly string
        full_assembly = []
        if self.data_segment:
            full_assembly.append("; --- Data Segment ---")
            full_assembly.extend(self.data_segment)
            full_assembly.append("")

        full_assembly.append("; --- Code Segment ---")
        # A common practice is to have a clear entry point
        full_assembly.append("_start: ; Program entry point")
        # Optional: jump to a main function if your language defines one
        # full_assembly.append("    call main ; Assuming a 'main' function exists")
        full_assembly.extend(self.assembly_code)
        full_assembly.append("    halt        ; End of program")
        full_assembly.append("")

        # Append or ensure inclusion of the Stacks runtime library
        # For now, we assume these runtime routines are available or will be linked.
        # full_assembly.append(self._get_runtime_code())

        return "\n".join(full_assembly)

    def _initialize_runtime_and_data_segment(self):
        """Sets up essential data segment entries, like the stack pointer."""
        # Define stack pointer and stack memory area.
        # The actual start address of the stack might be a convention (e.g., end of RAM).
        # SP needs to be initialized to the *end* of the stack_memory block if stack grows downwards,
        # or to the *start* if it grows upwards. stern-1's `stacks.asm` implies it grows upwards.
        self._add_data("STACK_BOTTOM: .word 0 ; Label for bottom of stack memory (for reference)")
        self._add_data("            .block 100 ; Reserve 100 words for the data stack")
        self._add_data("STACK_TOP_ADDR_PLUS_1: ; Address *after* the top of the stack block")
        self._add_data("SP:         .word STACK_BOTTOM ; Stack Pointer, initialized to the start of stack memory")
        
        # Code to initialize SP at the beginning of the program
        # This should ideally be the very first thing in the executable code.
        # We can prepend it to self.assembly_code later or handle it in generate().
        # For now, let's add it to the data segment comments as a reminder.
        # Actual initialization:
        # _start:
        #    ldi STACK_BOTTOM
        #    sto SP ; Store initial stack pointer value into the SP variable

        self.runtime_initialized = True

    def _get_runtime_code(self) -> str:
        """
        Returns a string containing the assembly code for the Stacks runtime.
        This would include routines for stack manipulation (+, -, DUP, PRINT, etc.).
        For now, this is a placeholder. You'd typically include a pre-written .asm file.
        """
        # These are conceptual and need to match stern-1's capabilities
        # and your `kernel2.asm` includes (`stacks`, `math`, `printing`).
        runtime = [
            "; --- Stacks Runtime Library (Conceptual - to be implemented/included) ---",
            "@runtime_push_A: ; Pushes value in Accumulator A onto the Stacks data stack",
            "    lod M SP          ; M = current stack pointer value (address)",
            "    sto M A           ; Store A at the address M",
            "    inc M             ; Increment stack pointer (address)",
            "    sto SP M          ; Save new stack pointer value",
            "    ret",
            "",
            "@runtime_pop_A:  ; Pops value from Stacks data stack into Accumulator A",
            "    lod M SP          ; M = current stack pointer value",
            "    dec M             ; Decrement stack pointer to point to top item",
            "    sto SP M          ; Save new stack pointer",
            "    lod A M           ; A = value at new stack top",
            "    ret",
            "",
            "@runtime_print_tos_and_nl: ; Pops top of stack, prints it as number, then newline",
            "    call @runtime_pop_A ; A = value to print",
            "    call @print_number  ; Assumed kernel/library routine",
            "    call @print_nl      ; Assumed kernel/library routine (@print_char 10)",
            "    ret",
            "",
            "@runtime_add_op: ; Pops two values, adds them, pushes result",
            "    call @runtime_pop_A ; A = operand2",
            "    mov B A             ; Store operand2 in B (if B exists and mov is possible)",
            "                      ; Alternative: push A to a temporary hardware stack or temp memory",
            "    call @runtime_pop_A ; A = operand1",
            "    add A B             ; A = operand1 + operand2 (stern-1 specific add)",
            "    call @runtime_push_A; Push result",
            "    ret",
            "; ... and so on for SUB, MUL, DIV, DUP, SWAP, DROP, EQ, STORE etc. ...",
            "@runtime_store_op: ; Pops address, then pops value, stores value at address",
            "    call @runtime_pop_A ; A = address",
            "    mov B A             ; B = address",
            "    call @runtime_pop_A ; A = value",
            "    sto B A             ; Store value (A) at address (B)",
            "    ret"
        ]
        return "\n".join(runtime)

    # --- Visitor Methods ---
    def visit(self, node: ASTNode):
        """Dispatches to the appropriate visit_NodeType method."""
        method_name = f'visit_{node.__class__.__name__}'
        visitor = getattr(self, method_name, self.generic_visit)
        # print(f"Visiting: {node.__class__.__name__}") # For debugging
        return visitor(node)

    def generic_visit(self, node: ASTNode):
        """Called if no explicit visitor for a node type is found."""
        raise Exception(f'CodeGenerator: No visit_{node.__class__.__name__} method defined')

    def visit_ProgramNode(self, node: ProgramNode):
        # Prepend SP initialization if not handled by _start label structure
        self._add_code("    ldi STACK_BOTTOM  ; Initialize Stack Pointer variable")
        self._add_code("    sto SP")
        self._add_code("")

        for stmt in node.statements:
            self.visit(stmt)

    def visit_ExpressionStatementNode(self, node: ExpressionStatementNode):
        for part in node.parts:
            self.visit(part)
        # Expression statements in Stacks usually leave results on the stack
        # or perform actions like PRINT. If a result is unused, it might just stay there
        # or be implicitly dropped depending on the context (e.g. end of function).

    def visit_LiteralNode(self, node: LiteralNode):
        if node.type == TokenType.INTEGER:
            self._add_code(f"    ldi {node.value}          ; Load integer literal {node.value}")
            self._add_code(f"    call @runtime_push_A ; Push A onto Stacks data stack")
        elif node.type == TokenType.STRING:
            str_label = self._generate_unique_label("S_")
            # stern-1 .string directive might need null termination, check its assembler.
            self._add_data(f'{str_label}: .string "{node.value}"')
            self._add_code(f"    ldi {str_label}      ; Load address of string \"{node.value}\"")
            self._add_code(f"    call @runtime_push_A ; Push string address onto stack")
        # Add other literal types if any (e.g., boolean, float if Stacks supports them)

    def visit_IdentifierNode(self, node: IdentifierNode):
        # This is context-sensitive. Is it for loading a value, getting an address, or calling a function?
        # 1. Loading a value:
        self._add_code(f"    lod A {node.name}        ; Load value of variable '{node.name}' into A")
        self._add_code(f"    call @runtime_push_A   ; Push value onto stack")
        #
        # 2. Getting an address (e.g., for 'AS' or array operations):
        #    This would require a different AST node (e.g., AddressOfNode) or semantic info.
        #    If `myVar AS` is the syntax, and `myVar` is an IdentifierNode, it should push its address.
        #    self._add_code(f"    ldi {node.name}        ; Load address of variable '{node.name}' into A")
        #    self._add_code(f"    call @runtime_push_A   ; Push address onto stack")
        #
        # 3. Implicit function call (Forth style, if `node.name` is a function and not `BACKTICK name`):
        #    self._add_code(f"    call {node.name}       ; Implicitly call function/word '{node.name}'")
        #
        # For now, we assume it's loading a variable's value.
        # The `AS` operator will need careful handling based on your intended syntax.

    def visit_OperatorNode(self, node: OperatorNode):
        op_type = node.op_type
        op_val = node.op_value.lower() # For generating @runtime_op_name

        if op_type == TokenType.PRINT:
            self._add_code(f"    call @runtime_print_tos_and_nl")
        elif op_type in [TokenType.PLUS, TokenType.MINUS, TokenType.MULTIPLY, TokenType.DIVIDE, TokenType.MODULO,
                         TokenType.EQ, TokenType.NE, TokenType.GT, TokenType.LT,
                         TokenType.GCD, TokenType.DUP, TokenType.SWAP, TokenType.OVER, TokenType.DROP, TokenType.DEPTH]:
            self._add_code(f"    call @runtime_{op_val}_op ; Call runtime for {node.op_value}")
        elif op_type == TokenType.AS:
            # RPN for store is: `value address STORE_OPERATOR`
            # If your Stacks syntax is `value variable_name AS`, then `variable_name`
            # must have pushed its address onto the stack *before* `AS` is called.
            # The current parser for `X AS Y` generates AST `[X, AS, Y]`. This is not RPN.
            # If syntax is `X Y AS` (RPN), AST is `[X, Y, AS]`. This is what this codegen assumes for AS.
            self._add_code(f"    ; 'AS' expects address on top of stack, value below it.")
            self._add_code(f"    call @runtime_store_op")
        elif op_type == TokenType.BANG: # '!' often means store in Forth-like languages
             self._add_code(f"    ; '!' (BANG) typically means store: value address !")
             self._add_code(f"    call @runtime_store_op")
        # Add more operators...
        else:
            self._add_code(f"    ; Operator: {node.op_value} - TBD by @runtime_{op_val}_op")
            self._add_code(f"    call @runtime_{op_val}_op")


    def visit_FunctionCallNode(self, node: FunctionCallNode):
        # Explicit call like ` myFunc
        self._add_code(f"    call {node.function_name}     ; Explicit call to function '{node.function_name}'")

    def visit_DefineBlockNode(self, node: DefineBlockNode):
        # Definitions primarily affect the data segment or symbol table.
        # The visitor methods for individual definitions will handle adding to .data_segment.
        self._add_code(f"; Processing DEFINE block (declarations handled in data segment)")
        for definition in node.definitions:
            self.visit(definition)

    def visit_ValueDefinitionNode(self, node: ValueDefinitionNode):
        var_name = node.name
        initial_val_asm = "0" # Default initial value
        if node.initial_value_node:
            if isinstance(node.initial_value_node, LiteralNode) and node.initial_value_node.type == TokenType.INTEGER:
                initial_val_asm = str(node.initial_value_node.value)
            else:
                # Non-integer initializers would require evaluating an expression at compile time
                # or generating code to compute and store it at runtime.
                # For now, we only support direct integer literals.
                print(f"Warning: Non-integer literal initializer for VALUE {var_name} not directly supported, defaulting to 0.")
        self._add_data(f"{var_name}: .word {initial_val_asm}  ; VALUE {var_name}")
        self.symbol_table[var_name] = {'type': 'VALUE', 'address_label': var_name}


    def visit_ArrayDefinitionNode(self, node: ArrayDefinitionNode):
        arr_name = node.name
        size = 0
        if isinstance(node.size_node, LiteralNode) and node.size_node.type == TokenType.INTEGER:
            size = node.size_node.value
            if size <= 0:
                print(f"Warning: Array '{arr_name}' defined with non-positive size {size}. Defaulting to size 1.")
                size = 1
        else:
            print(f"Warning: Array '{arr_name}' size is not an integer literal. Defaulting to size 1.")
            size = 1
        self._add_data(f"{arr_name}: .block {size}     ; ARRAY {arr_name}[{size}]")
        self.symbol_table[arr_name] = {'type': 'ARRAY', 'address_label': arr_name, 'size': size}

    def visit_FunctionDefinitionNode(self, node: FunctionDefinitionNode):
        func_name = node.name
        self._add_code(f"\n{func_name}: ; FUNCTION {func_name}")
        self.symbol_table[func_name] = {'type': 'FUNCTION', 'address_label': func_name}
        # Optional: Function prologue (e.g., setting up a stack frame if you add local variables beyond the RPN stack)
        for stmt in node.body:
            self.visit(stmt)
        self._add_code(f"    ret                 ; End of FUNCTION {func_name}")

    def visit_LabelNode(self, node: LabelNode):
        self._add_code(f":{node.name} ; LABEL {node.name}")
        self.symbol_table[node.name] = {'type': 'LABEL', 'address_label': node.name}

    def visit_GotoNode(self, node: GotoNode):
        self._add_code(f"    jmp :{node.name}         ; GOTO {node.name}")

    # TODO: Implement visitors for MATCH, REPEAT, DO, THING, etc.
