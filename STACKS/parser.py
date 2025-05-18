# parser.py
# Assuming your lexer is in 'stacks_lexer.py' and AST nodes in 'parser_ast.py'
from stacks_lexer import TokenType, Token # Make sure stacks_lexer.py is in the same directory or accessible via PYTHONPATH
from parser_ast import (
    ASTNode, ProgramNode, LiteralNode, IdentifierNode, OperatorNode,
    FunctionCallNode, ExpressionStatementNode, DefineBlockNode,
    ValueDefinitionNode, ArrayDefinitionNode, FunctionDefinitionNode,
    LabelNode, GotoNode
    # ... import other AST nodes as you define them
)

# Helper set for _parse_expression_parts (combine keywords and operators from lexer)
# This should be defined globally or as a class variable if preferred.
KEYWORDS_AND_OPERATORS_AS_TOKENTYPES = {
    # Operators
    TokenType.PLUS, TokenType.MINUS, TokenType.MULTIPLY, TokenType.DIVIDE, TokenType.MODULO,
    TokenType.EQ, TokenType.NE, TokenType.GT, TokenType.LT, TokenType.BANG,
    # Built-in words / commands from lexer's KEYWORDS that act as operators
    TokenType.GCD, TokenType.DUP, TokenType.SWAP, TokenType.OVER, TokenType.DROP, TokenType.DEPTH,
    # Commands from lexer's KEYWORDS
    TokenType.PRINT, TokenType.GET, TokenType.NOW, TokenType.NEW, TokenType.WITH,
    TokenType.EACH, TokenType.COPY, TokenType.PLOT, TokenType.WAIT, TokenType.AS,
    TokenType.SHOW, TokenType.RAWIN, TokenType.INPUT, TokenType.RATE, TokenType.USE,
    TokenType.DRAW, TokenType.TIMER, TokenType.SET
}

class Parser:
    def __init__(self, tokens: list[Token]):
        self.tokens = [t for t in tokens if t.type != TokenType.EOF] # Remove EOF for easier processing
        self.current_pos = 0
        # Initialize current_token, handling empty token list
        if self.tokens:
            self.current_token: Token = self.tokens[self.current_pos]
        else:
            # Create a dummy EOF token if token list is empty to prevent errors
            self.current_token: Token = Token(TokenType.EOF, None, 0, 0)


    def _advance(self):
        """Consumes the current token and moves to the next one."""
        self.current_pos += 1
        if self.current_pos < len(self.tokens):
            self.current_token = self.tokens[self.current_pos]
        else:
            # Use a sentinel EOF token when out of bounds
            self.current_token = Token(TokenType.EOF, None,
                                       self.tokens[-1].line if self.tokens else 0,
                                       self.tokens[-1].column if self.tokens else 0)

    def _peek(self, offset=1) -> Token:
        """Looks ahead at a future token without consuming."""
        peek_pos = self.current_pos + offset
        if peek_pos < len(self.tokens):
            return self.tokens[peek_pos]
        return Token(TokenType.EOF, None,
                     self.tokens[-1].line if self.tokens else 0,
                     self.tokens[-1].column if self.tokens else 0)

    def _consume(self, expected_type: TokenType, error_message: str) -> Token:
        """Consumes the current token if it matches expected_type, else raises error."""
        token = self.current_token
        if token.type == expected_type:
            self._advance()
            return token
        else:
            self._error(f"{error_message}. Expected {expected_type.name}, "
                        f"got {token.type.name} ('{token.value}')")

    def _error(self, message: str):
        """Raises a syntax error with line and column information."""
        err_token = self.current_token if self.current_token.type != TokenType.EOF else self.tokens[-1] if self.tokens else None
        line = err_token.line if err_token else 'N/A'
        col = err_token.column if err_token else 'N/A'
        raise SyntaxError(f"Parser Error: {message} at line {line}, col {col}")

    def parse(self) -> ProgramNode:
        """Main parsing method. Returns the root of the AST."""
        return self._parse_program()

    # --- Main Parsing Rules (based on Stacks-Grammer.txt) ---

    def _parse_program(self) -> ProgramNode:
        """program : { statement } ;"""
        statements = []
        while self.current_token.type != TokenType.EOF:
            # Skip any leading newlines between statements if they are not significant structural elements
            # Your grammar implies newlines are often terminators or separators.
            while self.current_token.type == TokenType.NL:
                self._advance()
                if self.current_token.type == TokenType.EOF: break

            if self.current_token.type == TokenType.EOF:
                break # End of file reached

            statements.append(self._parse_statement())
        return ProgramNode(statements)

    def _parse_statement(self) -> ASTNode:
        """
        statement : (DEFINE nl { definition } nl END nl) |
                    (FUNCTION ident nl { statement } nl END nl) |
                    (LABEL ident nl) | (GOTO ident nl) |
                    (MATCH expression nl { ON expression nl { statement } nl } [ NO nl { statement } nl ] END nl) |
                    ({expression} ("REPEAT" | "DO") nl {statement} nl "END" nl) |
                    expression nl ;
        """
        token_type = self.current_token.type

        if token_type == TokenType.DEFINE:
            return self._parse_define_block()
        elif token_type == TokenType.FUNCTION:
            return self._parse_function_definition()
        elif token_type == TokenType.LABEL:
            return self._parse_label_statement()
        elif token_type == TokenType.GOTO:
            return self._parse_goto_statement()
        # TODO: Add MATCH, REPEAT, DO here
        else:
            # Default to parsing an expression statement
            # `expression nl`
            expr_node = self._parse_expression_parts() # This will return a list of expression parts
            if not expr_node.parts: # If expression was empty (e.g. just a newline)
                 self._error("Expected an expression or statement, found empty line or unexpected token")
            self._consume(TokenType.NL, "Expected newline after expression statement")
            return expr_node


    def _parse_expression_parts(self) -> ExpressionStatementNode:
        """
        Parses the parts of an RPN expression until a statement terminator (like NL) or
        a keyword that cannot be part of an expression.
        expression : (INTEGER | STRING | ident | LBRACKET {expression} RBRACKET | word | command | BACKTICK ident)
                     { (INTEGER | STRING | ident | LBRACKET {expression} RBRACKET | word | command | BACKTICK ident) } ;
        """
        parts = []
        # Keywords that terminate an expression or start a new block/statement
        # This list will grow as you implement more statement types.
        terminating_tokens = [
            TokenType.NL, TokenType.END, TokenType.DEFINE, TokenType.FUNCTION,
            TokenType.LABEL, TokenType.GOTO, TokenType.MATCH, TokenType.ON,
            TokenType.NO, TokenType.DO # REPEAT is missing in TokenType, assuming DO is used for loops
            # Add other statement-starting keywords from your grammar
        ]
        # Add REPEAT if it exists in TokenType
        if hasattr(TokenType, 'REPEAT'):
            terminating_tokens.append(TokenType.REPEAT)


        while self.current_token.type not in terminating_tokens and self.current_token.type != TokenType.EOF:
            token = self.current_token
            if token.type == TokenType.INTEGER or token.type == TokenType.STRING:
                parts.append(LiteralNode(token))
                self._advance()
            elif token.type == TokenType.IDENT:
                # Could be a variable access or an implicitly called function in Forth style
                parts.append(IdentifierNode(token))
                self._advance()
            elif token.type == TokenType.BACKTICK:
                self._advance() # Consume `
                name_token = self._consume(TokenType.IDENT, "Expected identifier after backtick for function call")
                parts.append(FunctionCallNode(name_token))
            elif token.type in KEYWORDS_AND_OPERATORS_AS_TOKENTYPES: # Check if it's a known operator/command
                # Handle `AS ident` specifically if it's a command
                if token.type == TokenType.AS:
                    as_op_node = OperatorNode(token) # The 'AS' command itself
                    self._advance()
                    ident_for_as = self._consume(TokenType.IDENT, "Expected identifier after AS")
                    parts.append(as_op_node)
                    parts.append(IdentifierNode(ident_for_as))
                else:
                    parts.append(OperatorNode(token))
                    self._advance()
            # TODO: Handle LBRACKET {expression} RBRACKET (grouped expressions)
            else:
                self._error(f"Unexpected token '{token.value}' in expression")
                break 

        return ExpressionStatementNode(parts)


    # --- Parsing Specific Block Structures ---

    def _parse_define_block(self) -> DefineBlockNode:
        """(DEFINE nl { definition } nl END nl)"""
        start_token = self._consume(TokenType.DEFINE, "Expected DEFINE keyword")
        self._consume(TokenType.NL, "Expected newline after DEFINE")

        definitions = []
        while self.current_token.type != TokenType.END:
            while self.current_token.type == TokenType.NL:
                self._advance()
            if self.current_token.type == TokenType.END: break 
            if self.current_token.type == TokenType.EOF:
                self._error("Unexpected EOF inside DEFINE block. Missing END?")

            definitions.append(self._parse_definition())
            if self.current_token.type != TokenType.NL and self.current_token.type != TokenType.END:
                self._error(f"Expected newline or END after definition, got {self.current_token.type.name}")


        end_token = self._consume(TokenType.END, "Expected END keyword for DEFINE block")
        self._consume(TokenType.NL, "Expected newline after END of DEFINE block")
        return DefineBlockNode(definitions, start_token, end_token)

    def _parse_definition(self) -> ASTNode:
        """
        definition : (VALUE ident [INTEGER]) |
                     (ARRAY ident LBRACKET INTEGER RBRACKET) |
                     (THING ident nl { definition } nl [ INIT nl { statement } nl END nl ] { THIS ident nl { statement } nl END nl } END) ;
        """
        def_keyword_token = self.current_token

        if def_keyword_token.type == TokenType.VALUE:
            self._advance() # Consume VALUE
            name_token = self._consume(TokenType.IDENT, "Expected identifier for VALUE definition")
            initial_value_node = None
            if self.current_token.type == TokenType.INTEGER: # Optional integer
                initial_value_node = LiteralNode(self.current_token)
                self._advance()
            return ValueDefinitionNode(name_token, def_keyword_token, initial_value_node)

        elif def_keyword_token.type == TokenType.ARRAY:
            self._advance() # Consume ARRAY
            name_token = self._consume(TokenType.IDENT, "Expected identifier for ARRAY definition")
            self._consume(TokenType.LBRACKET, "Expected '[' after ARRAY name")
            size_token = self._consume(TokenType.INTEGER, "Expected INTEGER for ARRAY size")
            size_node = LiteralNode(size_token)
            self._consume(TokenType.RBRACKET, "Expected ']' after ARRAY size")
            return ArrayDefinitionNode(name_token, def_keyword_token, size_node)

        # TODO: THING definition
        else:
            self._error(f"Unexpected token '{def_keyword_token.value}' at start of a definition")
            return None # Should not be reached due to _error

    def _parse_function_definition(self) -> FunctionDefinitionNode:
        """(FUNCTION ident nl { statement } nl END nl)"""
        func_keyword_token = self._consume(TokenType.FUNCTION, "Expected FUNCTION keyword")
        name_token = self._consume(TokenType.IDENT, "Expected identifier for FUNCTION name")
        self._consume(TokenType.NL, "Expected newline after FUNCTION name and identifier")

        body_statements = []
        while self.current_token.type != TokenType.END:
            while self.current_token.type == TokenType.NL: # Skip newlines within function body
                self._advance()
            if self.current_token.type == TokenType.END: break
            if self.current_token.type == TokenType.EOF:
                self._error("Unexpected EOF inside FUNCTION definition. Missing END?")

            body_statements.append(self._parse_statement())

        end_token = self._consume(TokenType.END, "Expected END keyword for FUNCTION definition")
        self._consume(TokenType.NL, "Expected newline after END of FUNCTION definition")
        return FunctionDefinitionNode(name_token, func_keyword_token, body_statements, end_token)

    def _parse_label_statement(self) -> LabelNode:
        """(LABEL ident nl)"""
        label_keyword_token = self._consume(TokenType.LABEL, "Expected LABEL keyword")
        name_token = self._consume(TokenType.IDENT, "Expected identifier for LABEL name")
        self._consume(TokenType.NL, "Expected newline after LABEL statement")
        return LabelNode(name_token, label_keyword_token)

    def _parse_goto_statement(self) -> GotoNode:
        """(GOTO ident nl)"""
        goto_keyword_token = self._consume(TokenType.GOTO, "Expected GOTO keyword")
        name_token = self._consume(TokenType.IDENT, "Expected identifier for GOTO target")
        self._consume(TokenType.NL, "Expected newline after GOTO statement")
        return GotoNode(name_token, goto_keyword_token)

    # ... Implement _parse_match_statement, _parse_loop_statement, _parse_thing_definition etc. step-by-step

# Example usage (you'd typically call this from your main compiler script)
if __name__ == '__main__':
    from stacks_lexer import tokenize # Assuming your lexer is in stacks_lexer.py

    sample_code_1 = """
    10 PRINT
    "hello" PRINT
    """
    sample_code_2 = """
    DEFINE
        VALUE x 100
        ARRAY myArr [20]
    END

    FUNCTION main
        x PRINT
        `anotherFunc
    END

    FUNCTION anotherFunc
        "in another func" PRINT
    END

    LABEL myLabel
    GOTO myLabel
    """

    print("--- Parsing Sample Code 1 ---")
    tokens1 = tokenize(sample_code_1)
    parser1 = Parser(tokens1)
    try:
        ast1 = parser1.parse()
        print(ast1)
        for stmt in ast1.statements:
            print(f"  {stmt}")
            if hasattr(stmt, 'parts'):
                for part in stmt.parts:
                    print(f"    {part}")
    except SyntaxError as e:
        print(f"Error parsing sample_code_1: {e}")

    print("\n--- Parsing Sample Code 2 ---")
    tokens2 = tokenize(sample_code_2)
    parser2 = Parser(tokens2)
    try:
        ast2 = parser2.parse()
        print(ast2)
        for stmt in ast2.statements:
            print(f"  {stmt}")
            if isinstance(stmt, DefineBlockNode):
                for defi in stmt.definitions:
                    print(f"    {defi}")
            elif isinstance(stmt, FunctionDefinitionNode):
                for f_stmt in stmt.body:
                    print(f"    Body Stmt: {f_stmt}")
                    if hasattr(f_stmt, 'parts'):
                        for part in f_stmt.parts:
                            print(f"      {part}")

    except SyntaxError as e:
        print(f"Error parsing sample_code_2: {e}")