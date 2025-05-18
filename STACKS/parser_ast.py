# parser_ast.py

class ASTNode:
    """Base class for all AST nodes."""
    def __init__(self, token=None): # Optional token for line/col info
        self.token = token

    def __repr__(self):
        return f"<{self.__class__.__name__}>"

class ProgramNode(ASTNode):
    """Root node for the entire program."""
    def __init__(self, statements):
        super().__init__()
        self.statements = statements # List of statement nodes

    def __repr__(self):
        return f"<ProgramNode statements={len(self.statements)}>"

# --- Expression-related Nodes ---
class LiteralNode(ASTNode):
    """Node for literals like integers and strings."""
    def __init__(self, token):
        super().__init__(token)
        self.value = token.value
        self.type = token.type # To distinguish INTEGER_LITERAL, STRING_LITERAL

    def __repr__(self):
        return f"<LiteralNode type={self.type.name} value={repr(self.value)}>"

class IdentifierNode(ASTNode):
    """Node for identifiers (variables, function names, labels)."""
    def __init__(self, token):
        super().__init__(token)
        self.name = token.value

    def __repr__(self):
        return f"<IdentifierNode name='{self.name}'>"

class OperatorNode(ASTNode):
    """Node for RPN operators and commands (e.g., +, PRINT, DUP)."""
    def __init__(self, token):
        super().__init__(token)
        self.op_type = token.type # e.g., TokenType.PLUS, TokenType.PRINT
        self.op_value = token.value # e.g., "+", "PRINT"

    def __repr__(self):
        return f"<OperatorNode op='{self.op_value}'>"

class FunctionCallNode(ASTNode):
    """Node for explicit function calls like \`my_func."""
    def __init__(self, name_token):
        super().__init__(name_token)
        self.function_name = name_token.value

    def __repr__(self):
        return f"<FunctionCallNode name='{self.function_name}'>"

# --- Statement Nodes ---
class ExpressionStatementNode(ASTNode):
    """A statement that is just an RPN expression."""
    def __init__(self, parts):
        super().__init__(parts[0].token if parts else None) # Token of the first part
        self.parts = parts # List of LiteralNode, IdentifierNode, OperatorNode, FunctionCallNode

    def __repr__(self):
        return f"<ExpressionStatementNode parts={len(self.parts)}>"

class DefineBlockNode(ASTNode):
    def __init__(self, definitions, start_token, end_token):
        super().__init__(start_token)
        self.definitions = definitions # List of ValueDefinitionNode, ArrayDefinitionNode, etc.
        self.end_token = end_token

class ValueDefinitionNode(ASTNode):
    def __init__(self, name_token, value_keyword_token, initial_value_node=None):
        super().__init__(value_keyword_token)
        self.name_token = name_token
        self.name = name_token.value
        self.initial_value_node = initial_value_node # Could be a LiteralNode

    def __repr__(self):
        return f"<ValueDefinitionNode name='{self.name}' value={self.initial_value_node}>"

class ArrayDefinitionNode(ASTNode):
    def __init__(self, name_token, array_keyword_token, size_node):
        super().__init__(array_keyword_token)
        self.name_token = name_token
        self.name = name_token.value
        self.size_node = size_node # Should be a LiteralNode (INTEGER)

    def __repr__(self):
        return f"<ArrayDefinitionNode name='{self.name}' size={self.size_node}>"

class FunctionDefinitionNode(ASTNode):
    def __init__(self, name_token, func_keyword_token, body_statements, end_token):
        super().__init__(func_keyword_token)
        self.name_token = name_token
        self.name = name_token.value
        self.body = body_statements # List of statement nodes
        self.end_token = end_token

    def __repr__(self):
        return f"<FunctionDefinitionNode name='{self.name}' statements={len(self.body)}>"

class LabelNode(ASTNode):
    def __init__(self, name_token, label_keyword_token):
        super().__init__(label_keyword_token)
        self.name_token = name_token
        self.name = name_token.value

    def __repr__(self):
        return f"<LabelNode name='{self.name}'>"

class GotoNode(ASTNode):
    def __init__(self, name_token, goto_keyword_token):
        super().__init__(goto_keyword_token)
        self.name_token = name_token
        self.name = name_token.value

    def __repr__(self):
        return f"<GotoNode target='{self.name}'>"