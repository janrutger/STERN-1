import enum
import sys
from typing import Optional

class LexerError(Exception):
    """Custom exception for lexing errors."""
    pass

class Lexer:
    def __init__(self, source_input: str):
        self.source: str = source_input + '\n' # Source code to lex as a string. Append a newline to simplify lexing/parsing the last token/statement.
        self.curChar: str = ''   # Current character in the string.
        self.curPos: int = -1    # Current position in the string.
        self.nextChar()

    # Process the next character.
    def nextChar(self) -> None:
        self.curPos += 1
        if self.curPos >= len(self.source):
            self.curChar = '\0'  # EOF
        else:
            self.curChar = self.source[self.curPos]

    # Return the lookahead character.
    def peek(self) -> str:
        if self.curPos + 1 >= len(self.source):
            return '\0'
        return self.source[self.curPos+1]

    # Invalid token found, print error message and exit.
    def abort(self, message: str) -> None:
        raise LexerError(message)
		
    # Skip whitespace except newlines, which we will use to indicate the end of a statement.
    def skipWhitespace(self) -> None:
        while self.curChar == ' ' or self.curChar == '\t' or self.curChar == '\r':
            self.nextChar()
		
    # Skip comments in the code.
    def skipComment(self): 
        if self.curChar == '#':
            while self.curChar != '\n':
                self.nextChar()

    # Return the next token.
    def getToken(self) -> 'Token':
        self.skipWhitespace()
        self.skipComment()
        token: Optional[Token] = None

        # Check the first character of this token to see if we can decide what it is.
        # If it is a multiple character operator (e.g., !=), number, identifier, or keyword then we will process the rest.
        if self.curChar == '+':
            token = Token(self.curChar, TokenType.PLUS)
        elif self.curChar == '-':
            token = Token(self.curChar, TokenType.MINUS)
        elif self.curChar == '*':
            token = Token(self.curChar, TokenType.ASTERISK)
        elif self.curChar == '/':
            token = Token(self.curChar, TokenType.SLASH)
        elif self.curChar == '%':
            token = Token(self.curChar, TokenType.PCT)
        elif self.curChar == '{':
            token = Token(self.curChar, TokenType.OPENC)
        elif self.curChar == '}':
            token = Token(self.curChar, TokenType.CLOSEC)
        elif self.curChar == '[':
            token = Token(self.curChar, TokenType.OPENBL)
        elif self.curChar == ']':
            token = Token(self.curChar, TokenType.CLOSEBL)
        elif self.curChar == '`':
            token = Token(self.curChar, TokenType.BT)

        elif self.curChar == '=':
            # Check whether this token is = or ==
            if self.peek() == '=':
                lastChar = self.curChar
                self.nextChar()
                token = Token(lastChar + self.curChar, TokenType.EQEQ)
            else:
                self.abort("Expected ==, got =" + self.peek())

        elif self.curChar == '>':
            # Check whether this is token is > or >=
            # if self.peek() == '=':
            #     lastChar = self.curChar
            #     self.nextChar()
            #     token = Token(lastChar + self.curChar, TokenType.GTEQ)
            # else:
            #     token = Token(self.curChar, TokenType.GT)
            token = Token(self.curChar, TokenType.GT)

        elif self.curChar == '<':
                # Check whether this is token is < or <=
                # if self.peek() == '=':
                #     lastChar = self.curChar
                #     self.nextChar()
                #     token = Token(lastChar + self.curChar, TokenType.LTEQ)
                # else:
                #     token = Token(self.curChar, TokenType.LT)
                token = Token(self.curChar, TokenType.LT)

        elif self.curChar == '!':
            if self.peek() == '=':
                lastChar = self.curChar
                self.nextChar()
                token = Token(lastChar + self.curChar, TokenType.NOTEQ)
            else:
                #self.abort("Expected !=, got !" + self.peek())
                token = Token(self.curChar, TokenType.BANG) # Factorial or other unary '!'
    
        elif self.curChar == '.':
            if self.peek() == '.':
                lastChar = self.curChar
                self.nextChar()
                token = Token(lastChar + self.curChar, TokenType.DDOT)
            else:
                token = Token(self.curChar, TokenType.DOT)

        elif self.curChar == "'": # Start of a string literal (single quotes)
            self.nextChar()
            startPos = self.curPos
            stringValue = ""
            while self.curChar != "'":
                if self.curChar == '\0': # Check for EOF
                    self.abort(f"Unterminated string literal starting at position {startPos-1}.")
                # Allow most characters, including spaces.
                # You might want to disallow specific control characters like newlines if needed:
                # if self.curChar == '\n' or self.curChar == '\r':
                #     self.abort("Newline/Carriage return not allowed in string literal.")
                stringValue += self.curChar
                self.nextChar()
            
            self.nextChar() # Consume closing quote
            token = Token(stringValue, TokenType.STRING) # TokenType.STRING is 3
        # The old double-quote string logic is now replaced by the single-quote logic above.
        # If you need to retain double-quoted strings with different behavior (e.g., space replacement),
        # you would need a different TokenType or further logic adjustments.

        elif self.curChar.isdigit():
            # Leading character is a digit, so this must be a number.
            # Get all consecutive digits and decimal if there is one.
            startPos = self.curPos
            while self.peek().isdigit():
                self.nextChar()
            # if self.peek() == '.': # Decimal!
            #     self.nextChar()

            #     # Must have at least one digit after decimal.
            #     if not self.peek().isdigit(): 
            #         # Error!
            #         self.abort("Illegal character in number.")
            #     while self.peek().isdigit():
            #         self.nextChar()

            tokText = self.source[startPos : self.curPos + 1] # Get the substring.
            token = Token(tokText, TokenType.NUMBER)
        elif self.curChar.isalpha():
            # Leading character is a letter, so this must be an identifier or a keyword.
            # Get all consecutive alpha numeric characters.
            startPos = self.curPos
            while self.peek().isalnum():
                self.nextChar()

            # Check if the token is in the list of keywords.
            tokText = self.source[startPos : self.curPos + 1] # Get the substring.
            structural_keyword_type = Token.checkIfKeyword(tokText) # Case-sensitive check against enum names

            # RPN operation words. These should be tokenized as TokenType.WORD.
            # Their .text attribute will be used by the parser's word() method.
            # Using .upper() for matching these specific words makes them case-insensitive if desired.
            rpn_operation_words = {'GCD', 'DUP', 'SWAP', 'OVER', 'DROP', 'INPUT', 'RAWIN', 'SHOW', 'HASH'}

            if tokText.upper() in rpn_operation_words:
                # If it's one of these RPN words, classify it as WORD.
                # This takes precedence over them potentially being structural keywords if their names overlap
                # and the parser expects them as WORD tokens in expressions.
                token = Token(tokText, TokenType.WORD)
            elif structural_keyword_type is not None:
                # It's a structural keyword (like LABEL, GOTO, DEFINE, AS, PRINT, etc.)
                token = Token(tokText, structural_keyword_type)
            else:
                # Not an RPN operation word, not a structural keyword. Must be an identifier.
                token = Token(tokText, TokenType.IDENT)

        elif self.curChar == '\n':
            token = Token(self.curChar, TokenType.NEWLINE)
        elif self.curChar == '\0':
            token = Token('', TokenType.EOF)
        else:
            # Unknown token!
            self.abort("Unknown token: " + self.curChar)
			
        self.nextChar()

        return token


# Token contains the original text and the type of token.
class Token:   
    def __init__(self, tokenText: str, tokenKind: 'TokenType'):
        self.text: str = tokenText   # The token's actual text. Used for identifiers, strings, and numbers.
        self.kind: 'TokenType' = tokenKind   # The TokenType that this token is classified as.

    @staticmethod
    def checkIfKeyword(tokenText: str) -> Optional['TokenType']:
        for kind in TokenType:
            # Relies on all keyword enum values being 1XX.
            if kind.name == tokenText and kind.value >= 100 and kind.value < 200:
                return kind
        return None


# TokenType is our enum for all the types of tokens.
class TokenType(enum.Enum):
    WORD = -2 # For RPN operators/words like DUP, SWAP, GCD, INPUT, RAWIN (as op), etc.
    EOF = -1
    NEWLINE = 0
    NUMBER = 1
    IDENT = 2
    STRING = 3
# Keywords.
    LABEL = 101
    GOTO = 102
    PRINT = 103
    INPUT = 104
    FUNCTION = 106
    AS = 107
    PLOT = 108
    WAIT = 109
    DO = 110
    REPEAT = 111
    END = 112
    OPENC = 113
    CLOSEC = 114
    OPENBL = 115
    CLOSEBL = 116
    RAWIN = 117
# Operators.
    DUP = 118
    SWAP = 119
    OVER = 120
    DROP = 121
    GCD = 122
    TIMER = 123
    SET = 124
    GET = 125
    BT = 126
    # SHOW = 127 # SHOW is now handled as TokenType.WORD via rpn_operation_words
    # Channels for serial
    CHANNEL = 128
    ON = 129
    OFF = 130
    # Connection for Network
    CONNECTION = 131
    READ = 132
    WRITE = 133

    PLUS = 201
    MINUS = 202
    ASTERISK = 203
    SLASH = 204
    BANG = 205
    DOT = 207
    DDOT =208
    EQEQ = 210
    NOTEQ = 211
    LT = 212
    GT = 213
    PCT = 214
    
