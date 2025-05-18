import re
from enum import Enum, auto

# 1. Define Token Types
class TokenType(Enum):
    # Keywords
    DEFINE = auto()
    VALUE = auto()
    ARRAY = auto()
    THING = auto()
    INIT = auto()
    THIS = auto()
    END = auto()
    USE = auto()
    DRAW = auto()
    TIMER = auto()
    SET = auto()
    PRINT = auto()
    GET = auto()
    NOW = auto()
    NEW = auto()
    WITH = auto()
    EACH = auto()
    COPY = auto()
    PLOT = auto()
    DO = auto()
    MATCH = auto()
    ON = auto()
    NO = auto()
    WAIT = auto()
    AS = auto()
    GOTO = auto()
    LABEL = auto()
    FUNCTION = auto()
    SHOW = auto()
    RAWIN = auto()
    INPUT = auto()
    RATE = auto()

    # Operators / Built-in Words
    PLUS = auto()
    MINUS = auto()
    MULTIPLY = auto()
    DIVIDE = auto()
    MODULO = auto()
    EQ = auto() # ==
    NE = auto() # !=
    GT = auto() # >
    LT = auto() # <
    GCD = auto()
    BANG = auto() # !
    DUP = auto()
    SWAP = auto()
    OVER = auto()
    DROP = auto()
    DEPTH = auto()

    # Literals
    INTEGER = auto()
    STRING = auto()

    # Identifiers
    IDENT = auto()

    # Special Symbols
    LBRACKET = auto() # [
    RBRACKET = auto() # ]
    LBRACE = auto()   # {
    RBRACE = auto()   # }
    LPAREN = auto()   # (
    RPAREN = auto()   # )
    DOT = auto()      # .
    DOTDOT = auto()   # ..
    BACKTICK = auto() # `

    # Significant Whitespace / End of Input
    NL = auto()       # Newline
    EOF = auto()      # End of File

# Map of keywords and built-in words for easy lookup
KEYWORDS = {
    "DEFINE": TokenType.DEFINE, "VALUE": TokenType.VALUE, "ARRAY": TokenType.ARRAY,
    "THING": TokenType.THING, "INIT": TokenType.INIT, "THIS": TokenType.THIS,
    "END": TokenType.END, "USE": TokenType.USE, "DRAW": TokenType.DRAW,
    "TIMER": TokenType.TIMER, "SET": TokenType.SET, "PRINT": TokenType.PRINT,
    "GET": TokenType.GET, "NOW": TokenType.NOW, "NEW": TokenType.NEW,
    "WITH": TokenType.WITH, "EACH": TokenType.EACH, "COPY": TokenType.COPY,
    "PLOT": TokenType.PLOT,  "DO": TokenType.DO,
    "MATCH": TokenType.MATCH, "ON": TokenType.ON, "NO": TokenType.NO,
    "WAIT": TokenType.WAIT, "AS": TokenType.AS, "GOTO": TokenType.GOTO,
    "LABEL": TokenType.LABEL, "FUNCTION": TokenType.FUNCTION, "SHOW": TokenType.SHOW,
    "RAWIN": TokenType.RAWIN, "INPUT": TokenType.INPUT, "RATE": TokenType.RATE,

    # Built-in words (operators/commands)
    "GCD": TokenType.GCD, "DUP": TokenType.DUP, "SWAP": TokenType.SWAP,
    "OVER": TokenType.OVER, "DROP": TokenType.DROP, "DEPTH": TokenType.DEPTH,
    "INPUT": TokenType.INPUT, "RAWIN": TokenType.RAWIN # Already listed as keywords, but good to be explicit
}

# Map of operators/symbols for easy lookup (longer ones first!)
SYMBOLS = {
    "==": TokenType.EQ, "!=": TokenType.NE, ">": TokenType.GT, "<": TokenType.LT,
    "+": TokenType.PLUS, "-": TokenType.MINUS, "*": TokenType.MULTIPLY,
    "/": TokenType.DIVIDE, "%": TokenType.MODULO, "!": TokenType.BANG,
    "[": TokenType.LBRACKET, "]": TokenType.RBRACKET, "{": TokenType.LBRACE,
    "}": TokenType.RBRACE, "(": TokenType.LPAREN, ")": TokenType.RPAREN,
    "..": TokenType.DOTDOT, ".": TokenType.DOT, "`": TokenType.BACKTICK
}


# 2. Define a Token Class
class Token:
    def __init__(self, type: TokenType, value: any, line: int, column: int):
        self.type = type
        self.value = value
        self.line = line
        self.column = column

    def __repr__(self):
        return f"Token({self.type.name}, {repr(self.value)}, line={self.line}, col={self.column})"

# 3. Implement the Lexer Function
def tokenize(source_code: str) -> list[Token]:
    tokens = []
    line = 1
    column = 1
    i = 0 # Current position in the source code string

    # Add a newline at the end to ensure the last line is processed correctly
    source_code += "\n"

    while i < len(source_code):
        char = source_code[i]

        # Handle Newlines
        if char == '\n':
            tokens.append(Token(TokenType.NL, '\n', line, column))
            line += 1
            column = 1
            i += 1
            continue # Go to the next character

        # Handle Whitespace (spaces, tabs - ignore)
        if char in ' \t\r':
            column += 1
            i += 1
            continue

        # Handle Comments
        if char == '#':
            # Read until the end of the line
            while i < len(source_code) and source_code[i] != '\n':
                i += 1
                column += 1
            continue # The newline will be handled by the NL case

        # Handle Symbols and Operators (check for multi-character symbols first)
        matched_symbol = None
        for symbol_str, symbol_type in SYMBOLS.items():
            if source_code[i:].startswith(symbol_str):
                tokens.append(Token(symbol_type, symbol_str, line, column))
                i += len(symbol_str)
                column += len(symbol_str)
                matched_symbol = True
                break # Found a symbol, move to the next character

        if matched_symbol:
            continue

        # Handle Strings
        if char == '"':
            start_col = column
            i += 1 # Consume the opening quote
            column += 1
            string_value = ""
            while i < len(source_code) and source_code[i] != '"':
                # TODO: Handle escape sequences if your grammar supports them
                if source_code[i] == '\n':
                     # Strings cannot contain raw newlines unless escaped
                     # Depending on your grammar, this might be an error
                     print(f"Error: Unexpected newline in string literal at line {line}, column {column}")
                     # Or handle it as an error token
                     return [] # Simple error handling: stop tokenizing
                string_value += source_code[i]
                i += 1
                column += 1

            if i >= len(source_code):
                 print(f"Error: Unterminated string literal starting at line {line}, column {start_col}")
                 return [] # Simple error handling

            i += 1 # Consume the closing quote
            column += 1
            tokens.append(Token(TokenType.STRING, string_value, line, start_col))
            continue

        # Handle Integers
        if char.isdigit():
            start_col = column
            integer_str = ""
            while i < len(source_code) and source_code[i].isdigit():
                integer_str += source_code[i]
                i += 1
                column += 1
            tokens.append(Token(TokenType.INTEGER, int(integer_str), line, start_col))
            continue

        # Handle Identifiers and Keywords
        if char.isalpha():
            start_col = column
            ident_str = ""
            while i < len(source_code) and (source_code[i].isalnum() or source_code[i] == '_'): # Allow underscore in ident? Grammar says [a-zA-Z][a-zA-Z0-9]*
                 # Let's stick to the grammar: letters and digits only after the first letter
                 if i > start_col -1 + len(ident_str) and not source_code[i].isalnum():
                      break # Stop if it's not alphanumeric after the first char

                 ident_str += source_code[i]
                 i += 1
                 column += 1

            # Check if it's a keyword or a general identifier
            token_type = KEYWORDS.get(ident_str, TokenType.IDENT)
            tokens.append(Token(token_type, ident_str, line, start_col))
            continue

        # If we reach here, it's an unexpected character
        print(f"Error: Unexpected character '{char}' at line {line}, column {column}")
        return [] # Simple error handling: stop tokenizing

    # Add EOF token at the end
    tokens.append(Token(TokenType.EOF, None, line, column))

    return tokens

# Example Usage:
if __name__ == "__main__":
    source = """
DEFINE
    VALUE myVar 10
    ARRAY myArr [5]
END

# This is a comment
myVar 20 AS myVar # Store 20 in myVar
myVar PRINT
"Hello, World!" PRINT

10 5 + PRINT
5 2 == PRINT # Should print 0 (false)
"""

    tokens = tokenize(source)
    for token in tokens:
        print(token)