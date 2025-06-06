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
        self.functions: Set[str] = set()  # All functions declared.
        self.connections: Set[str] = set() # All network connections declared.
        self.connection_details: dict = {} # Stores details for connections (type, routine/params).
        self.labelsDeclared: Set[str] = set() # Keep track of all labels declared
        self.labelsGotoed: Set[str] = set() # All labels goto'ed, so we know if they exist or not.

        self.string_literal_counter: int = 0 # For generating unique labels for string literals
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

        # | channel_number CHANNEL (ON | OFF) nl
        elif self.checkToken(TokenType.NUMBER) and self.checkPeek(TokenType.CHANNEL):
            self._print_trace("Parsing CHANNEL ON/OFF statement.")
            self._indent()
            channel_num_token = self.curToken
            self.nextToken() # Consume NUMBER

            # Emit code to push channel_num_token.text onto the STACKS stack
            # The runtime routines @sio_channel_on/off will pop this.
            self.emitter.emitLine(f"ldi A {channel_num_token.text}")
            self.emitter.emitLine("call @push_A")

            self.match(TokenType.CHANNEL) # Consume CHANNEL

            if self.checkToken(TokenType.ON):
                self.nextToken() # Consume ON
                self.emitter.emitLine("call @sio_channel_on") 
                self._print_trace(f"Called ON for channel {channel_num_token.text}.")
            elif self.checkToken(TokenType.OFF):
                self.nextToken() # Consume OFF
                self.emitter.emitLine("call @sio_channel_off") 
                self._print_trace(f"called OFF for channel {channel_num_token.text}.")
            else:
                self.abort(f"Expected ON or OFF after CHANNEL, got {self.curToken.kind.name if self.curToken else 'None'}")
            self.nl()
            self._dedent()

        # | number TIMER (SET | PRINT | GET) nl
        elif self.checkToken(TokenType.NUMBER) and self.checkPeek(TokenType.TIMER):
            self._print_trace("Parsing TIMER statement (NUMBER TIMER ...).")
            self._indent()
            timer_id_token = self.curToken
            self.nextToken() # Consume NUMBER (timer_id)

            # Emit code to push timer_id_token.text onto the STACKS stack
            self.emitter.emitLine(f"ldi A {timer_id_token.text}")
            self.emitter.emitLine("call @push_A")
            self._print_info(f"Pushed timer ID {timer_id_token.text} to stack.")

            self.match(TokenType.TIMER) # Consume TIMER

            if self.checkToken(TokenType.SET):
                self.nextToken() # Consume SET
                self.emitter.emitLine("call @stacks_timer_set")
                self._print_info(f"TIMER SET for ID {timer_id_token.text}. Emitted: call @stacks_timer_set.")
            elif self.checkToken(TokenType.PRINT): # Uses general PRINT token (103)
                self.nextToken() # Consume PRINT
                self.emitter.emitLine("call @stacks_timer_print")
                self._print_info(f"TIMER PRINT for ID {timer_id_token.text}. Emitted: call @stacks_timer_print.")
            elif self.checkToken(TokenType.GET):
                self.nextToken() # Consume GET
                self.emitter.emitLine("call @stacks_timer_get")
                self._print_info(f"TIMER GET for ID {timer_id_token.text}. Emitted: call @stacks_timer_get.")
            else:
                self.abort(f"Expected SET, PRINT, or GET after TIMER, got {self.curToken.kind.name if self.curToken else 'None'}")
            
            self.nl() # Expect a newline after the command
            self._dedent()
            self._print_trace("Exiting TIMER statement.")

            
        # | "FUNCTION" ident nl {statement} nl "END" nl
        elif self.checkToken(TokenType.FUNCTION):
            self._print_trace("Parsing FUNCTION definition statement.")
            self._indent()
            self.nextToken() # Consume FUNCTION
            func_name = self.curToken.text

            # Check for name collisions
            if func_name in self.symbols or \
               func_name in self.functions or \
               func_name in self.connections:
                self.abort(f"Identifier '{func_name}' already declared as a variable, function, or connection.")
            
            self.functions.add(func_name) # Add to functions set
            
            # Proceed with function definition
            # The check 'if func_name in self.functions:' is now guaranteed true
            if func_name in self.functions: 
                self.emitter.context = "functions"
                self.emitter.emitLine("@~" + func_name)
                self._print_info(f"Defining function '{func_name}'. STERN-1: Emit '@~{func_name}'.")
                self.match(TokenType.IDENT)
                self.nl()
                while not self.checkToken(TokenType.END):
                    self.statement()
                self.match(TokenType.END)
                self.emitter.emitLine("ret")
                self._print_info(f"End of function '{func_name}'. STERN-1: Emit 'ret'.")
                self.emitter.context = "program"
                self.nl()
            self._dedent()


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

        # | ident CONNECTION (READ ident_routine | WRITE num_dst num_service_id) nl
        elif self.checkToken(TokenType.IDENT) and self.checkPeek(TokenType.CONNECTION):
            self._print_trace("Parsing CONNECTION definition statement.")
            self._indent()
            conn_name_token = self.curToken
            # conn_name = conn_name_token.text # Keep for clarity if needed later
            self.nextToken() # Consume IDENT (conn_name)
            
            self.match(TokenType.CONNECTION) # Consume CONNECTION (checks and advances)

            # Check for name collisions before adding to self.connections
            if conn_name_token.text in self.symbols or \
               conn_name_token.text in self.functions or \
               conn_name_token.text in self.connections: # Check if already in connections too (defensive)
                self.abort(f"Identifier '{conn_name_token.text}' already declared as a variable, function, or connection.")
            
            self.connections.add(conn_name_token.text)
            self._print_info(f"Declaring connection: {conn_name_token.text}")

            if self.checkToken(TokenType.READ):
                self.nextToken() # Consume READ
                if not self.checkToken(TokenType.IDENT):
                    self.abort(f"Expected identifier for service routine after CONNECTION READ, got {self.curToken.kind.name if self.curToken else 'None'}")
                
                service_routine_token = self.curToken
                self.connection_details[conn_name_token.text] = {
                    'type': 'READ',
                    'routine': "@" + service_routine_token.text # Prepend @ for STERN-1 call
                }
                self._print_info(f"  Type: READ, Calls: @{service_routine_token.text}")
                self.match(TokenType.IDENT) # Consume service_routine_name (checks and advances)
                self.nl()

            elif self.checkToken(TokenType.WRITE):
                self.nextToken() # Consume WRITE
                
                if not self.checkToken(TokenType.NUMBER):
                    self.abort(f"Expected destination address (NUMBER) after CONNECTION WRITE, got {self.curToken.kind.name if self.curToken else 'None'}")
                dst_addr_token = self.curToken
                self.nextToken() # Consume dst_addr (NUMBER)

                if not self.checkToken(TokenType.NUMBER):
                    self.abort(f"Expected service ID (NUMBER) after destination address, got {self.curToken.kind.name if self.curToken else 'None'}")
                service_id_token = self.curToken
                self.nextToken() # Consume service_id (NUMBER)

                # Generate a unique label for the assembly stub for this WRITE connection
                stub_label = f"@~conn_{conn_name_token.text}_write_{self.LabelNum()}"
                self.connection_details[conn_name_token.text] = {
                    'type': 'WRITE',
                    'dst': dst_addr_token.text,
                    'service_id': service_id_token.text,
                    'stub_label': stub_label # Store the label to call
                }
                self._print_info(f"  Type: WRITE, Dst: {dst_addr_token.text}, ServiceID: {service_id_token.text}, Stub: {stub_label}")

                # Emit the assembly stub for this specific WRITE connection
                original_context = self.emitter.context
                self.emitter.context = "functions" # Place stub in functions section for organization
                self.emitter.emitLine(f"{stub_label}")
                self.emitter.emitLine(f"  call @pop_B")         # Value to send is popped from STACKS stack into B
                self.emitter.emitLine(f"  ldi A {dst_addr_token.text}")  # Dst NIC ID into A
                self.emitter.emitLine(f"  ldi C {service_id_token.text}") # Service ID into C
                self.emitter.emitLine(f"  call @stacks_network_write") # Call generic runtime helper
                self.emitter.emitLine(f"  ret")
                self.emitter.context = original_context
                self.nl()
            else:
                self.abort(f"Expected READ or WRITE after CONNECTION, got {self.curToken.kind.name if self.curToken else 'None'}")
            self._dedent()
        
        
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
            elif self.checkToken(TokenType.PLOT): # PLOT is now active
                self.emitter.emitLine("call @plot") # Call the runtime routine
                self._print_trace("PLOT operation: Emitted call @plot.")
                self.nextToken() # Consume PLOT
                self.nl()
            elif self.checkToken(TokenType.WAIT):
                # self.emitter.emitLine("call @sleep")
                self._print_info("WAIT operation. STERN-1: Pop value, call sleep/wait routine.")
                self.nextToken() # Consume WAIT
                self.nl()

            elif self.checkToken(TokenType.AS):
                self.nextToken() # Consume AS
                target_name = self.curToken.text

                is_write_connection_target = False
                connection_stub_label = None

                # First, check if it's a function (cannot AS to a function)
                if target_name in self.functions:
                    self.abort(f"Cannot use AS with '{target_name}'. It is declared as a function.")

                # Next, check if it's a connection
                if target_name in self.connections:
                    connection_info = self.connection_details[target_name]
                    if connection_info['type'] == 'READ':
                        self.abort(f"Cannot use AS with '{target_name}'. It is a READ connection. AS is for assignment/sending.")
                    elif connection_info['type'] == 'WRITE':
                        is_write_connection_target = True
                        connection_stub_label = connection_info['stub_label']
                        self._print_info(f"AS: Target '{target_name}' is a WRITE connection. Value will be stored in ${target_name} AND sent via connection.")
                
                # Part 1: Variable assignment (always happens for AS)
                # If the target_name is not yet a declared variable symbol, declare it.
                if target_name not in self.symbols:
                    self.symbols.add(target_name)
                    self.emitter.headerLine(". $" + target_name + " 1") # STERN-1 variable declaration
                    self._print_info(f"AS: Declaring new variable storage '${target_name}'.")

                # These lines should be outside the 'if not in self.symbols' block,
                # as assignment happens whether the variable is new or existing.
                if target_name in self.symbols:
                    self.emitter.emitLine("call @pop_A") # Pop value from STACKS stack into CPU register A
                    self.emitter.emitLine("sto A $" + target_name) # Store value from A into variable $target_name
                    self._print_info(f"AS: Assigned stack top to variable '${target_name}'.")

                # Part 2: If it was a WRITE connection, also send the value
                if is_write_connection_target and connection_stub_label:
                    # The value is currently in register A (and also stored in $target_name).
                    # The connection stub expects the value on the STACKS stack.
                    self.emitter.emitLine("call @push_A") # Push value from register A back to STACKS stack
                    self.emitter.emitLine(f"call {connection_stub_label}") # Call the connection's write stub
                    self._print_info(f"AS: Emitted call to {connection_stub_label} to send value from '${target_name}'.")

                self.match(TokenType.IDENT) # Consume the target_name token
                self.nl()

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
                # goto_target_label = self.peekToken.text # Peek to get the IDENT text for the GOTO target
                self.nextToken() # Consume GOTO
                self.labelsGotoed.add(self.curToken.text) # Add to gotoed before emitting
                self.emitter.emitLine("call @pop_A")
                self.emitter.emitLine("tste A Z")
                self.emitter.emitLine("jmpf " + ":_" + num + "_goto_end")
                self._print_info(f"Conditional GOTO. STERN-1: Pop condition, test if zero, jump to :_{num}_goto_end if false.")

                self.emitter.emitLine("jmp " + ":" + self.curToken.text)
                self._print_info(f"Conditional GOTO actual jump to '{self.curToken.text}'. STERN-1: Emit 'jump :{self.curToken.text}'.")
                self.emitter.emitLine(":_" + num + "_goto_end")
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
                self._print_trace(f"EXPRESSION: STRING literal '{self.curToken.text}'")
                str_content = self.curToken.text
                
                self.emitter.emitLine(f"; --- String Literal '{str_content}' pushed to stack ---")
                
                # 1. Push null terminator (0)
                self.emitter.emitLine("ldi A 0")
                self.emitter.emitLine("call @push_A")
                
                # 2. Push characters of the string in reverse order of appearance
                for char_val_str in reversed(str_content): # Iterate in reverse
                    assembly_char_representation = char_val_str
                    if char_val_str == ' ':
                        assembly_char_representation = "space" # Use "\space" for the assembler
                    # Add other necessary character escapes if your assembler requires them
                    # e.g., for '\\' itself, or for quotes if they were allowed inside strings.
                    
                    self.emitter.emitLine(f"ldi A \\{assembly_char_representation}")
                    self.emitter.emitLine("call @push_A")
                
                self.emitter.emitLine(f"; --- End String Literal '{str_content}' on stack ---")
                self.nextToken() # Consume STRING token
            elif self.checkToken(TokenType.BT):
                self.nextToken()
                self.emitter.emitLine("call " + "@" + self.curToken.text) # Uses IDENT's text
                self._print_trace(f"Backtick call to '@{self.curToken.text}'. STERN-1: Emit 'call @{self.curToken.text}'.")
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
                self.emitter.emitLine("call @stacks_gcd")
            elif self.curToken.text.upper() == 'DUP':
                self.emitter.emitLine("call @dup")
            elif self.curToken.text.upper() == 'OVER':
                self.emitter.emitLine("call @over")
            elif self.curToken.text.upper() == 'DROP':
                self.emitter.emitLine("call @drop") # This was 'pull' in old arch
            elif self.curToken.text.upper() == 'SWAP':
                self.emitter.emitLine("call @swap")
            elif self.curToken.text.upper() == 'INPUT':
                self.emitter.emitLine("call @stacks_input")
            elif self.curToken.text.upper() == 'RAWIN': # This is RAWIN used as an RPN operation
                self.emitter.emitLine("call @stacks_raw_input_string")
            elif self.curToken.text.upper() == 'SHOW':
                self.emitter.emitLine("call @stacks_show_from_stack") # New: Assumes string chars are on stack
            elif self.curToken.text.upper() == 'HASH':
                self.emitter.emitLine("call @stacks_hash_from_stack") 
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
            self.emitter.emitLine("ldm A $" + self.curToken.text) # Use '$' for STERN-1 var access
            self.emitter.emitLine("call @push_A")
            self._print_info(f"Loading variable '{ident_name}' to stack.")
        elif self.curToken.text in self.functions:
            self.emitter.emitLine("call @~" + self.curToken.text) # Use '@~' for STACKS function call
            self._print_info(f"Calling function '{ident_name}'. STERN-1: call @~{ident_name}.")
        elif ident_name in self.connections:
            details = self.connection_details[ident_name]
            if details['type'] == 'READ':
                # The user-defined service routine (e.g., @myServiceRoutine) is called.
                # It's expected to push value and status onto STACKS stack.
                self.emitter.emitLine(f"call {details['routine']}")
                self._print_info(f"Executing READ connection '{ident_name}' by calling {details['routine']}.")
            elif details['type'] == 'WRITE':
                # The generated stub (e.g., @~conn_myNetWrite_write_X) is called.
                # It expects the value to write to be on TOS. It pops it, sets up params, and calls runtime.
                self.emitter.emitLine(f"call {details['stub_label']}")
                self._print_info(f"Executing WRITE connection '{ident_name}' by calling {details['stub_label']}.")
        else:
            self.abort(f"Referencing undeclared identifier (variable, function, or connection): '{ident_name}'")

        self.nextToken()
        self._dedent()
        self._print_trace("Exiting ident()")

    # st ::= ('.'|'..')
    def st(self) -> None:
        self._print_trace(f"Entering st() for token '{self.curToken.text}'")
        self._indent()
        if self.checkToken(TokenType.DDOT):
            self.emitter.emitLine("call @dup") #duplicate Top Off Stack
        else:
            # do ntothing, juest use TOS
            pass

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