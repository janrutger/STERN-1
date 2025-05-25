import sys
#from lexV2 import *
from lexV2 import Lexer, Token, TokenType
from emitV2 import Emitter # Assuming Emitter is in emitV2
from typing import Set, Optional

class ParserError(Exception):
    """Custom exception for parsing errors."""
    pass

# Parser object keeps track of current token and checks if the code matches the grammar.
class Parser:
    def __init__(self, lexer: Lexer, emitter: Emitter):
        self.lexer: Lexer = lexer
        self.emitter: Emitter = emitter

        self.symbols: Set[str] = set()    # All variables we have declared so far.
        self.functions: Set[str] = set()  # All functions we have declared so far.
        self.labelsDeclared: Set[str] = set() # Keep track of all labels declared
        self.labelsGotoed: Set[str] = set() # All labels goto'ed, so we know if they exist or not.

        self.curToken: Optional[Token] = None
        self.peekToken: Optional[Token] = None
        self.labelnumber: int = -1
        self._indent_level: int = 0
        self._indent_str: str = "  "
        self.nextToken()
        self.nextToken()    # Call this twice to initialize current and peek.

    def LabelNum(self) -> str:
        self.labelnumber = self.labelnumber + 1
        return(str(self.labelnumber))

    def _print_trace(self, message: str):
        print(f"{self._indent_str * self._indent_level}TRACE: {message}")

    def _print_info(self, message: str):
        print(f"{self._indent_str * self._indent_level}INFO: {message}")

    def _indent(self):
        self._indent_level += 1

    def _dedent(self):
        self._indent_level -= 1

    
    # Return true if the current token matches.
    def checkToken(self, kind: TokenType) -> bool:
        return self.curToken is not None and kind == self.curToken.kind

    # Return true if the next token matches.
    def checkPeek(self, kind: TokenType) -> bool:
        return self.peekToken is not None and kind == self.peekToken.kind

    # Try to match current token. If not, error. Advances the current token.
    def match(self, kind: TokenType) -> None:
        if not self.checkToken(kind):
            expected_name = kind.name
            got_name = self.curToken.kind.name if self.curToken else "None"
            self.abort(f"Expected {expected_name}, got {got_name}")
        self.nextToken()

    # Advances the current token.
    def nextToken(self) -> None:
        self.curToken = self.peekToken
        self.peekToken = self.lexer.getToken()
        # No need to worry about passing the EOF, lexer handles that.

    def abort(self, message: str) -> None:
        raise ParserError(message)


    # Production rules.

    # program    ::=	{statement}
    def program(self):
        self._print_trace("Entering program()")
        self._indent()
        self.emitter.headerLine("@main")
        #self.emitter.headerLine("INCLUDE  stacks_runtime")
        self.emitter.headerLine("call @stacks_runtime_init")

        # Since some newlines are required in our grammar, need to skip the excess.
        while self.checkToken(TokenType.NEWLINE):
            self.nextToken()

        # Parse all the statements in the program.
        while not self.checkToken(TokenType.EOF):
            self.statement()

        # Wrap things up.
        self.emitter.emitLine("ret")
        self.emitter.emitLine("INCLUDE  stacks_runtime")

        # end of program

        # Check that each label referenced in a GOTO is declared.
        for label in self.labelsGotoed:
            if label not in self.labelsDeclared:
                self.abort("Attempting to GOTO to undeclared label: " + label)
        self._dedent()
        self._print_trace("Exiting program()")

    # statement  ::=  
        # One of the following statements...
    def statement(self) -> None:
        self._print_trace("Entering statement()")
        self._indent()
        # print("STATEMENT") # Removed debug print
        # Check the first token to see what kind of statement this is.
        #   "LABEL" ident nl
        if self.checkToken(TokenType.LABEL):
            self.nextToken() # Consume LABEL

            # Make sure this label doesn't already exist.
            if self.curToken.text in self.labelsDeclared:
                self.abort("Label already exists: " + self.curToken.text)
            self.labelsDeclared.add(self.curToken.text) # Still need to track declared labels
            self.emitter.emitLine(":" + self.curToken.text)
            self._print_trace(f"Declaring label '{self.curToken.text}'.")
            self.match(TokenType.IDENT)
            self.nl() 

        # | "GOTO" ident nl
        elif self.checkToken(TokenType.GOTO):
            self.nextToken() # Consume GOTO
            self.labelsGotoed.add(self.curToken.text)
            self.emitter.emitLine("jmp " + ":" + self.curToken.text)
            self._print_trace(f"Unconditional GOTO '{self.curToken.text}'.")
            self.match(TokenType.IDENT)
            self.nl() 

        # | "TIMER" INTEGER("SET" | "PRINT" | "GET")
        elif self.checkToken(TokenType.TIMER):
            self.nextToken() # Consume TIMER
            var = self.curToken.text
            self.match(TokenType.NUMBER)
            if int(var) < 16:
                self.abort("User defined timers starts at number 16, not " + var)
            if self.checkToken(TokenType.SET):
                # self.emitter.emitLine("settimer " + var)
                self._print_info(f"SET TIMER {var} (old arch). STERN-1: Map to kernel call or custom routine.")
            elif self.checkToken(TokenType.PRINT):
                # self.emitter.emitLine("prttimer " + var)
                self._print_info(f"PRINT TIMER {var} (old arch). STERN-1: Map to kernel call or custom routine.")
            elif self.checkToken(TokenType.GET):
                # self.emitter.emitLine("gettimer " + var)
                self._print_info(f"GET TIMER {var} (old arch). STERN-1: Map to kernel call or custom routine, result on stack.")
            self.nextToken()
            self.nl()

        # | "DEFINE" ident nl {statement} nl "END" nl
        elif self.checkToken(TokenType.FUNCTION):
            self.nextToken() # Consume DEFINE
            if self.curToken.text not in self.symbols and self.curToken.text not in self.functions:
                self.functions.add(self.curToken.text)
            if self.curToken.text in self.functions:
                self.emitter.context = "functions"
                # self.emitter.emitLine("@~" + self.curToken.text)
                self._print_info(f"Defining function '{self.curToken.text}'. STERN-1: Emit '@~{self.curToken.text}'.")
                self.match(TokenType.IDENT)
                self.nl()
                while not self.checkToken(TokenType.END):
                    self.statement()
                self.match(TokenType.END)
                # self.emitter.emitLine("ret")
                self._print_info(f"End of function '{self.curToken.text}'. STERN-1: Emit 'ret'.")
                self.emitter.context = "program"
                self.nl()
            else:
                self.abort("Already in use as a Variable " + self.curToken.text)


        # | "{" ({expression} | st) "}"   "DO"   nl {statement} nl "END" nl	
        elif self.checkToken(TokenType.OPENC):
            num = self.LabelNum()
            self.emitter.emitLine(":_" + num + "_while_condition")
            self._print_trace(f"WHILE loop condition start (label :_{num}_while_condition).")
            self.nextToken()  # Consume OPENC {
            if self.checkToken(TokenType.DOT) or self.checkToken(TokenType.DDOT):
                self.st()
            else:
                self.expression()
            self.match(TokenType.CLOSEC)

            self.match(TokenType.DO)
            self.emitter.emitLine("call @pop_A")
            self.emitter.emitLine("tste A Z")
            self.emitter.emitLine("jmpf " + ":_" + num + "_while_end")
            self._print_trace(f"WHILE loop check. STERN-1: Pop condition, test if zero, jump to :_{num}_while_end if false.")

            self.nl()
            while not self.checkToken(TokenType.END):
                self.statement()
                
            self.emitter.emitLine("jmp " + ":_" + num + "_while_condition")
            self._print_trace(f"WHILE loop jump back to condition (jump :_{num}_while_condition).")
            self.emitter.emitLine(":_" + num + "_while_end")
            self._print_trace(f"WHILE loop end (label :_{num}_while_end).")

            self.match(TokenType.END) # Consume END
            self.nl()

        
        
        # | ({expression} | st) ( "PRINT" nl | "PLOT" nl | "AS" ident nl | "DO"   nl {statement} nl "END" nl | "GOTO" ident) nl | nl )
        else: #it must be an expression
            if self.checkToken(TokenType.DOT) or self.checkToken(TokenType.DDOT):
                self.st() # Consumes . or ..
            else:
                self.expression() # Consumes expression tokens
            
            # Check for optional action keywords after the expression or stack operation
            if self.checkToken(TokenType.PRINT):
                self.emitter.emitLine("call @print")
                self._print_trace("PRINT operation.")
                self.nextToken() # Consume PRINT
                self.nl()
            elif self.checkToken(TokenType.PLOT):
                # self.emitter.emitLine("call @plot")
                self._print_info("PLOT operation. STERN-1: Pop value, call plot routine (e.g. @plot_xy_pair or similar).")
                self.nextToken() # Consume PLOT
                self.nl()
            elif self.checkToken(TokenType.WAIT):
                # self.emitter.emitLine("call @sleep")
                self._print_info("WAIT operation. STERN-1: Pop value, call sleep/wait routine.")
                self.nextToken() # Consume WAIT
                self.nl()
            elif self.checkToken(TokenType.AS):
                self.nextToken() # Consume AS
                var_name = self.curToken.text
                if self.curToken.text not in self.symbols and self.curToken.text not in self.functions:
                    self.symbols.add(self.curToken.text)
                    self.emitter.headerLine(". $" + self.curToken.text + " 1")
                
                if self.curToken.text in self.symbols:
                    self.emitter.emitLine("call @pop_A")
                    self.emitter.emitLine("sto A " + "$" + self.curToken.text)
                    self._print_trace(f"AS (assign) to variable '{var_name}'.")
                    self.match(TokenType.IDENT)  
                    self.nl()
                else:
                    self.abort("Already in use as a Function " + self.curToken.text)

            elif self.checkToken(TokenType.DO):
                num = self.LabelNum()
                self.nextToken() # Consume DO
                self.emitter.emitLine("call @pop_A")
                self.emitter.emitLine("tste A Z")
                self.emitter.emitLine("jmpf " + ":_" + num + "_do_end")
                self._print_trace(f"DO block condition check. Test if zero, jump to :_{num}_do_end if false.")
                self.nl()

                while not self.checkToken(TokenType.END):
                    self.statement()

                self.match(TokenType.END) # Consume END
                self.emitter.emitLine(":_" + num + "_do_end")
                self._print_trace(f"DO block end (label :_{num}_do_end).")
                self.nl()

            elif self.checkToken(TokenType.GOTO):
                num = self.LabelNum()
                goto_target_label = self.peekToken.text # Peek to get the IDENT text for the GOTO target
                self.nextToken() # Consume GOTO
                self.labelsGotoed.add(self.curToken.text) # Add to gotoed before emitting
                # self.emitter.emitLine("loada")
                # self.emitter.emitLine("testz")
                # self.emitter.emitLine("clra")
                # self.emitter.emitLine("jumpf " + ":_" + num + "_goto_end")
                self._print_info(f"Conditional GOTO. STERN-1: Pop condition, test if zero, jump to :_{num}_goto_end if false.")

                # self.emitter.emitLine("jump " + ":" + self.curToken.text)
                self._print_info(f"Conditional GOTO actual jump to '{self.curToken.text}'. STERN-1: Emit 'jump :{self.curToken.text}'.")
                # self.emitter.emitLine(":_" + num + "_goto_end")
                self._print_info(f"Conditional GOTO skip label (label :_{num}_goto_end).")

                self.match(TokenType.IDENT)  
                self.nl()   
            else:
                # If no action keyword, just expect a newline (or it's already consumed by expression/st if they ended with one)
                self.nl()
        self._dedent()
        self._print_trace("Exiting statement()")

    # expression ::= INTEGER | STRING | "`" ident "`" | ident | word
    # An expression is a sequence of numbers, strings, identifiers (variable loads or function calls),
    # backticked assembly calls, or RPN operations/words.
    def expression(self):
        self._print_trace("Entering expression()")
        self._indent()
        # Loop to consume a sequence of items that can form an RPN expression.
        while True:
            if self.checkToken(TokenType.NUMBER):
                self.emitter.emitLine("ldi A " + self.curToken.text)
                self.emitter.emitLine("call @push_A") 
                self._print_trace(f"Pushing NUMBER {self.curToken.text}")
                self.nextToken()
            elif self.checkToken(TokenType.STRING):
                # self.emitter.emitLine("push " + "'" + self.curToken.text + "'")
                self._print_info(f"Pushing STRING '\"{self.curToken.text}\"'. STERN-1: Define string, push its address or handle directly.")
                self.nextToken()
            elif self.checkToken(TokenType.BT):
                self.nextToken()
                # self.emitter.emitLine("call " + "@" + self.curToken.text) # Uses IDENT's text
                self._print_info(f"Backtick call to '@{self.curToken.text}'. STERN-1: Emit 'call @{self.curToken.text}'.")
                self.match(TokenType.IDENT)
            elif self.checkToken(TokenType.IDENT):
                # ident() will print its own info
                self.ident()
            # Check for specific operator tokens OR general RPN words (lexed as TokenType.WORD)
            elif self.checkToken(TokenType.PLUS) or \
                 self.checkToken(TokenType.MINUS) or \
                 self.checkToken(TokenType.ASTERISK) or \
                 self.checkToken(TokenType.SLASH) or \
                 self.checkToken(TokenType.PCT) or \
                 self.checkToken(TokenType.EQEQ) or \
                 self.checkToken(TokenType.NOTEQ) or \
                 self.checkToken(TokenType.LT) or \
                 self.checkToken(TokenType.GT) or \
                 self.checkToken(TokenType.BANG) or \
                 self.checkToken(TokenType.WORD): # Catches DUP, SWAP, GCD, INPUT, RAWIN (as op) etc.
                # word() will print its own info
                self.word()
            else:
                # No more number, string, ident, bt, operator, or RPN word found. End of expression.
                break 
        self._dedent()
        self._print_trace("Exiting expression()")

    # word ::= (operator_token | rpn_command_word_token)
    # Handles tokens that represent operations in RPN.
    def word(self) -> None:
        self._print_trace(f"Entering word() for token '{self.curToken.text}' ({self.curToken.kind.name})")
        self._indent()
        # Handle specific operator tokens
        if self.checkToken(TokenType.PLUS):
            self.emitter.emitLine("call @plus") 
        elif self.checkToken(TokenType.MINUS):
            self.emitter.emitLine("call @minus")
        elif self.checkToken(TokenType.ASTERISK):
            self.emitter.emitLine("call @multiply")
        elif self.checkToken(TokenType.SLASH):
            self.emitter.emitLine("call @divide")
        elif self.checkToken(TokenType.PCT):
            # self.emitter.emitLine("call @mod")
            self._print_info("RPN MODULO. STERN-1: call @mod_op (pop 2, mod, push 1).")
        elif self.checkToken(TokenType.BANG): # Factorial '!'
            # self.emitter.emitLine("call @factorial")
            self._print_info("RPN FACTORIAL. STERN-1: call @factorial_op (pop 1, fact, push 1).")
        elif self.checkToken(TokenType.EQEQ):
            self.emitter.emitLine("call @eq")
        elif self.checkToken(TokenType.NOTEQ):
            self.emitter.emitLine("call @ne")
        elif self.checkToken(TokenType.LT):
            self.emitter.emitLine("call @lt")
        elif self.checkToken(TokenType.GT):
            self.emitter.emitLine("call @gt")

        # Handle named RPN words (which are lexed as TokenType.WORD)
        elif self.checkToken(TokenType.WORD):
            if self.curToken.text.upper() == 'GCD': # Using .upper() for robustness
                # self.emitter.emitLine("call @_gcd")
                self._print_info("RPN GCD. STERN-1: call @gcd_op (pop 2, gcd, push 1).")
            elif self.curToken.text.upper() == 'DUP':
                # self.emitter.emitLine("call @dup")
                self._print_info("RPN DUP. STERN-1: call @dup_op (peek 1, push 1).")
            elif self.curToken.text.upper() == 'OVER':
                # self.emitter.emitLine("call @over")
                self._print_info("RPN OVER. STERN-1: call @over_op (pop 1, peek 1, push 2).")
            elif self.curToken.text.upper() == 'DROP':
                # self.emitter.emitLine("pull") # This was 'pull' in old arch
                self._print_info("RPN DROP. STERN-1: call @drop_op (pop 1).")
            elif self.curToken.text.upper() == 'SWAP':
                # self.emitter.emitLine("call @swap")
                self._print_info("RPN SWAP. STERN-1: call @swap_op (pop 2, push 2 swapped).")
            elif self.curToken.text.upper() == 'INPUT':
                self.emitter.emitLine("call @input")
            elif self.curToken.text.upper() == 'RAWIN': # This is RAWIN used as an RPN operation
                self.emitter.emitLine("call @stacks_raw_input_string")
            else:
                self.abort("Unknown RPN word: " + self.curToken.text)
        else:
            # This case should ideally not be reached if expression() calls word() correctly
            self.abort("Expected an operator or RPN word, got: " + self.curToken.kind.name + " (" + self.curToken.text + ")")
        
        self.nextToken() # Consume the operator or RPN word token
        self._dedent()
        # self._print_trace("Exiting word()")

    # ident ::=	STRING
    def ident(self) -> None:
        self._print_trace(f"Entering ident() for token '{self.curToken.text}'")
        self._indent()
        ident_name = self.curToken.text
        if self.curToken.text in self.symbols:
            self.emitter.emitLine("ldm A " + "$" + self.curToken.text)
            self.emitter.emitLine("call @push_A")
            self._print_trace(f"Loading variable '{ident_name}' to stack.")
        elif self.curToken.text in self.functions:
            # self.emitter.emitLine("call " + "@~" + self.curToken.text)
            self._print_info(f"Calling function '{ident_name}'. STERN-1: call @~{ident_name}.")
        else:
            self.abort("Referencing variable before assignment: " + self.curToken.text)

        self.nextToken()
        self._dedent()
        self._print_trace("Exiting ident()")

    # st ::= ('.'|'..')
    def st(self) -> None:
        self._print_trace(f"Entering st() for token '{self.curToken.text}'")
        self._indent()
        if self.checkToken(TokenType.DDOT):
            # self.emitter.emitLine("call @dup") #duplicate Top Off Stack
            self._print_info("Stack op '..' (DUP). STERN-1: call @dup_op.")
        else:
            self._print_info("Stack op '.' (Use ToS). STERN-1: No explicit op, value is already on stack.")

        self.nextToken()
        self._dedent()
        self._print_trace("Exiting st()")

    
    # nl ::= '\n'+
    def nl(self) -> None:
        # self._print_trace("Entering nl()") # This might be too verbose, uncomment if needed
        # Require at least one newline.
        self.match(TokenType.NEWLINE)
        # But we will allow extra newlines too, of course.
        while self.checkToken(TokenType.NEWLINE):
            self.nextToken()