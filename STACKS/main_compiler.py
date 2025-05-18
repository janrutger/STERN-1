# main_compiler.py
from stacks_lexer import tokenize
from parser import Parser # Assuming parser.py
from parser_ast import (
    ProgramNode, ExpressionStatementNode, DefineBlockNode, FunctionDefinitionNode,
    LiteralNode, IdentifierNode, OperatorNode, FunctionCallNode,
    ValueDefinitionNode, ArrayDefinitionNode, LabelNode, GotoNode, ASTNode
)
from stacks_codegen import CodeGenerator
import sys # For sys.exit and sys.stderr


def print_ast_recursive(node: ASTNode, indent=""):
    """Recursively prints the AST nodes with indentation."""
    if node is None:
        print(f"{indent}None")
        return

    node_type_name = node.__class__.__name__
    details = ""

    if isinstance(node, LiteralNode):
        details = f"type={node.type.name}, value={repr(node.value)}"
    elif isinstance(node, IdentifierNode):
        details = f"name='{node.name}'"
    elif isinstance(node, OperatorNode):
        details = f"op='{node.op_value}' (type={node.op_type.name})"
    elif isinstance(node, FunctionCallNode):
        details = f"name='{node.function_name}'"
    elif isinstance(node, ValueDefinitionNode):
        details = f"name='{node.name}', initial_value="
        print(f"{indent}<{node_type_name} {details}>")
        print_ast_recursive(node.initial_value_node, indent + "  ")
        return # Handled recursion for initial_value_node
    elif isinstance(node, ArrayDefinitionNode):
        details = f"name='{node.name}', size="
        print(f"{indent}<{node_type_name} {details}>")
        print_ast_recursive(node.size_node, indent + "  ")
        return # Handled recursion for size_node
    elif isinstance(node, LabelNode):
        details = f"name='{node.name}'"
    elif isinstance(node, GotoNode):
        details = f"target='{node.name}'"
    elif isinstance(node, FunctionDefinitionNode):
        details = f"name='{node.name}'"

    print(f"{indent}<{node_type_name} {details}>")

    if hasattr(node, 'statements') and node.statements: # For ProgramNode
        for stmt in node.statements:
            print_ast_recursive(stmt, indent + "  ")
    elif hasattr(node, 'parts') and node.parts: # For ExpressionStatementNode
        for part in node.parts:
            print_ast_recursive(part, indent + "    ")
    elif hasattr(node, 'definitions') and node.definitions: # For DefineBlockNode
        for definition in node.definitions:
            print_ast_recursive(definition, indent + "  ")
    elif hasattr(node, 'body') and node.body: # For FunctionDefinitionNode
        for stmt in node.body:
            print_ast_recursive(stmt, indent + "  ")

def main():
    source_file_path = "./STACKS/program.stacks" # Fixed source file name
    output_file_path = "./STACKS/output.asm"   # Fixed output file name

    try:
        with open(source_file_path, "r") as f:
            source_code = f.read()
    except FileNotFoundError:
        print(f"Error: Source file not found: {source_file_path}", file=sys.stderr)
        sys.exit(1)
    except IOError as e:
        print(f"Error reading source file {source_file_path}: {e}", file=sys.stderr)
        sys.exit(1)

    tokens = tokenize(source_code)
    if not tokens: # The lexer already prints an error, so just exit.
        print("Lexing failed.", file=sys.stderr)
        sys.exit(1)
    
    parser = Parser(tokens)
    try:
        ast = parser.parse()
        print("--- Abstract Syntax Tree (AST) ---") # Optional: for debugging
        print_ast_recursive(ast)

        codegen = CodeGenerator()
        assembly_code = codegen.generate(ast)
        # print("\n--- Generated Assembly ---") # Optional: print to console
        # print(assembly_code)

        with open(output_file_path, "w") as f:
            f.write(assembly_code)
        print(f"\nCompilation successful. Assembly code saved to {output_file_path}")

    except SyntaxError as e:
        print(f"Parsing Error: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"An unexpected error occurred: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
