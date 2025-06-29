import sys
#from lexV2 import *
from lexV3 import Lexer, Token, TokenType
from emitV3 import Emitter # Assuming Emitter is in emitV2
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
        self.arrays: Set[str] = set()     # All arrays declared.
        self.array_details: dict = {}     # Stores details for arrays (label, max_size).
        self.labelsDeclared: Set[str] = set() # Keep track of all labels declared
        self.shared_symbols: Set[str] = set() # All shared variables/arrays declared globally.
        self.shared_array_details: dict = {} # Stores details for shared arrays (label, max_size).
        self.labelsGotoed: Set[str] = set() # All labels goto'ed, so we know if they exist or not.

        #self.string_literal_counter: int = 0 # For generating unique labels for string literals
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
        # self.emitter.headerLine("@main") # No longer a single @main
        # self.emitter.headerLine("call @stacks_runtime_init") # Runtime init is now part of stern_runtime or per-process

        # Since some newlines are required in our grammar, need to skip the excess.
        while self.checkToken(TokenType.NEWLINE):
            self.nextToken()

        # Parse all the process definitions in the program.
        while not self.checkToken(TokenType.EOF):
            if self.checkToken(TokenType.PROCESS):
                self.process_definition()
            else:
                self.abort(f"Expected PROCESS definition or EOF, got {self.curToken.kind.name if self.curToken else 'None'}")

        # Wrap things up.
        # self.emitter.emitLine("ret") # No global ret
        # self.emitter.emitLine("INCLUDE stern_runtime") # Runtime is part of the kernel, no need to include per program

        self._dedent()
        self._print_trace("Exiting program()")

    # process_definition ::= "PROCESS" INTEGER [INTEGER] nl {statement} nl "END" nl
    def process_definition(self):
        self._print_trace("Entering process_definition()")
        self._indent()
        self.match(TokenType.PROCESS)
        
        if not self.checkToken(TokenType.NUMBER):
            self.abort("Expected Process ID (INTEGER) after PROCESS keyword.")
        pid_token = self.curToken
        self.nextToken()

        stack_size_text = "64" # Default stack size
        if self.checkToken(TokenType.NUMBER):
            stack_size_token = self.curToken
            stack_size_text = stack_size_token.text
            self.nextToken()
        self.nl()

        # --- Reset/Scope Symbol Tables for this process ---
        self.symbols = set()
        self.functions = set() # Functions are defined within a process scope
        self.labelsDeclared = set()
        self.labelsGotoed = set()
        self.arrays = set()
        self.array_details = {}
        # Shared symbols/arrays are NOT reset per process, they are global to the compilation unit.
        # self.shared_symbols = set()
        self.connections = set() # Connections are also per-process
        self.connection_details = {}
        self._print_info(f"Starting new process scope for PID {pid_token.text}.")

        self.emitter.start_process_segment(pid_token.text, stack_size_text)
        # self.emitter.emitLine("call @stacks_runtime_init") # If runtime init is per-process

        while not self.checkToken(TokenType.END): # Process blocks end with END
            if self.checkToken(TokenType.EOF):
                self.abort(f"Unexpected EOF while parsing PROCESS {pid_token.text}. Expected END.")
            self.statement()
        
        self.match(TokenType.END) # Consume END for the process block
        self.nl()

        # Check that each label referenced in a GOTO is declared *for this process*.
        for label in self.labelsGotoed:
            if label not in self.labelsDeclared:
                self.abort(f"Process {pid_token.text}: Attempting to GOTO to undeclared label: {label}")
        
        # self.emitter.end_process_segment()
        self.emitter.end_process_segment(pid_token.text) # Pass PID for implicit stop
        self._dedent()
        self._print_trace(f"Exiting process_definition() for PID {pid_token.text}")

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
            self.emitter.emitLine("push A")

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
            self.emitter.emitLine("push A")
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

        # | "ARRAY" ident number nl
        elif self.checkToken(TokenType.ARRAY):
            self._print_trace("Parsing ARRAY definition statement.")
            self._indent()
            self.nextToken() # Consume ARRAY

            if not self.checkToken(TokenType.IDENT):
                self.abort(f"Expected identifier for array name after ARRAY, got {self.curToken.kind.name if self.curToken else 'None'}")
            array_name_token = self.curToken
            array_name = array_name_token.text
            self.nextToken() # Consume IDENT (array_name)

            if not self.checkToken(TokenType.NUMBER):
                self.abort(f"Expected number for array size after array name '{array_name}', got {self.curToken.kind.name if self.curToken else 'None'}")
            array_size_token = self.curToken
            array_size_val = int(array_size_token.text)
            self.nextToken() # Consume NUMBER (array_size)

            if array_size_val <= 0:
                self.abort(f"Array size for '{array_name}' must be positive, got {array_size_val}.")

            # Check for name collisions
            if array_name in self.symbols or \
               array_name in self.functions or \
               array_name in self.connections or \
               array_name in self.shared_symbols or \
               array_name in self.arrays:
                self.abort(f"Identifier '{array_name}' already declared as a variable, function, connection, or array.")
            
            self.arrays.add(array_name)
            self.array_details[array_name] = {'label': f"${array_name}", 'max_size': array_size_val}
            # Emit data definitions into the current code segment (process specific)
            self.emitter.emitLine(f". ${array_name} {array_size_val + 2}") # +2 for length and max_size
            self.emitter.emitLine(f"% ${array_name} 0 {array_size_val + 2}") # {length=0, total_allocated_size=user_size+2}

            self._print_info(f"Declared ARRAY '{array_name}' with user size {array_size_val} (total allocated: {array_size_val + 2}). STERN-1: . ${array_name} {array_size_val + 2}, % ${array_name} 0 {array_size_val + 2}")
            self.nl()
            self._dedent()

        # | "SHARED" "VAR" ident nl
        elif self.checkToken(TokenType.SHARED):
            self._print_trace("Parsing SHARED definition statement.")
            self._indent()
            self.nextToken() # Consume SHARED

            if self.checkToken(TokenType.VAR):
                self._print_trace("  Parsing SHARED VAR.")
                self.nextToken() # Consume VAR
                if not self.checkToken(TokenType.IDENT):
                    self.abort(f"Expected identifier for shared variable name after SHARED VAR, got {self.curToken.kind.name if self.curToken else 'None'}")
                shared_var_name_token = self.curToken
                shared_var_name = shared_var_name_token.text
                self.nextToken() # Consume IDENT (shared_var_name)

                # Check for name collisions across all symbol types
                if shared_var_name in self.symbols or \
                   shared_var_name in self.functions or \
                   shared_var_name in self.connections or \
                   shared_var_name in self.arrays or \
                   shared_var_name in self.shared_symbols: # Check against existing shared symbols too
                    self.abort(f"Identifier '{shared_var_name}' already declared as a variable, function, connection, array, or shared symbol.")

                self.shared_symbols.add(shared_var_name)
                self.emitter.emitSharedDataLine(f". &{shared_var_name} 1") # Emit to shared data section
                self._print_info(f"Declared SHARED VAR '{shared_var_name}'. STERN-1: . &{shared_var_name} 1")
                self.nl()

            elif self.checkToken(TokenType.ARRAY):
                self._print_trace("  Parsing SHARED ARRAY.")
                self.nextToken() # Consume ARRAY
                if not self.checkToken(TokenType.IDENT):
                    self.abort(f"Expected identifier for shared array name after SHARED ARRAY, got {self.curToken.kind.name if self.curToken else 'None'}")
                shared_array_name_token = self.curToken
                shared_array_name = shared_array_name_token.text
                self.nextToken() # Consume IDENT (shared_array_name)

                if not self.checkToken(TokenType.NUMBER):
                    self.abort(f"Expected number for shared array size after shared array name '{shared_array_name}', got {self.curToken.kind.name if self.curToken else 'None'}")
                shared_array_size_val = int(self.curToken.text)
                self.nextToken() # Consume NUMBER (shared_array_size)

                # Check for name collisions (same logic as SHARED VAR)
                if shared_array_name in self.symbols or shared_array_name in self.functions or shared_array_name in self.connections or shared_array_name in self.arrays or shared_array_name in self.shared_symbols:
                     self.abort(f"Identifier '{shared_array_name}' already declared as a variable, function, connection, array, or shared symbol.")
                
                self.shared_symbols.add(shared_array_name) # Add to general shared symbols
                self.shared_array_details[shared_array_name] = {
                    'label': f"&{shared_array_name}", # Store with '&' prefix
                    'max_size': shared_array_size_val # Store user-defined size
                }
                
                # Emit to shared data section
                # Allocate space for user elements + 2 metadata fields (current_length, total_allocated_size)
                total_allocated_size = shared_array_size_val + 2
                self.emitter.emitSharedDataLine(f". &{shared_array_name} {total_allocated_size}")
                # Initialize metadata: current_length = 0, total_allocated_size = total_allocated_size
                self.emitter.emitSharedDataLine(f"% &{shared_array_name} 0 {total_allocated_size}")

                self._print_info(f"Declared SHARED ARRAY '{shared_array_name}' with user size {shared_array_size_val} (total allocated: {total_allocated_size}). STERN-1: . &{shared_array_name} {total_allocated_size}, % &{shared_array_name} 0 {total_allocated_size}")
                self.nl()
            
        # | "FUNCTION" ident nl {statement} nl "END" nl
        elif self.checkToken(TokenType.FUNCTION):
            self._print_trace("Parsing FUNCTION definition statement.")
            self._indent()
            self.nextToken() # Consume FUNCTION
            func_name = self.curToken.text

            # Check for name collisions
            if func_name in self.symbols or \
               func_name in self.functions or \
               func_name in self.connections or \
               func_name in self.shared_symbols or \
               func_name in self.arrays:
                self.abort(f"Identifier '{func_name}' already declared as a variable, function, or connection.")
            
            self.functions.add(func_name) # Add to functions set
            
            # Proceed with function definition
            # The check 'if func_name in self.functions:' is now guaranteed true
            # Functions are emitted inline within the current process segment
            # The emitter's context switch might not be strictly necessary if all code goes to _code_lines
            # after a .PROCES directive.
            if func_name in self.functions:
                self.emitter.enter_function_definition_emission() # Signal start of function code
                self.emitter.emitLine("@~" + func_name)
                self._print_info(f"Defining function '{func_name}'. STERN-1: Emit '@~{func_name}'.")
                self.match(TokenType.IDENT)
                self.nl()
                while not self.checkToken(TokenType.END):
                    self.statement()
                self.match(TokenType.END)
                self.emitter.emitLine("ret")
                self.emitter.exit_function_definition_emission() # Signal end of function code
                self._print_info(f"End of function '{func_name}'. STERN-1: Emit 'ret' (function code collected).")
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
            self.emitter.emitLine("pop A")
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
               conn_name_token.text in self.connections or \
               conn_name_token.text in self.arrays or \
               conn_name_token.text in self.shared_symbols: # Check against shared symbols
                self.abort(f"Identifier '{conn_name_token.text}' already declared as a variable, function, connection, array, or shared symbol.")
            
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

                if not self.checkToken(TokenType.NUMBER):
                    self.abort(f"Expected reply PID (NUMBER) after service ID, got {self.curToken.kind.name if self.curToken else 'None'}")
                reply_pid_token = self.curToken
                self.nextToken() # Consume reply_pid (NUMBER)

                # Generate a unique label for the assembly stub for this WRITE connection
                stub_label = f"@~conn_{conn_name_token.text}_write_{self.LabelNum()}"
                self.connection_details[conn_name_token.text] = {
                    'type': 'WRITE',
                    'dst': dst_addr_token.text,
                    'service_id': service_id_token.text,
                    'stub_label': stub_label, # Store the label to call
                    'reply_pid': reply_pid_token.text, # Store the reply_pid
                }
                self._print_info(f"  Type: WRITE, Dst: {dst_addr_token.text}, ServiceID: {service_id_token.text}, ReplyPID: {reply_pid_token.text}, Stub: {stub_label}")

                # Emit the assembly stub out-of-line. This stub is called via a CPU 'call' instruction.
                # The stub's job is to set up registers for the runtime helper and call it.
                # The CPU's 'call'/'ret' pair handles the return address automatically.
                # The value to be sent is expected to be in register B when this stub is called.
                self.emitter.enter_function_definition_emission()
                self.emitter.emitLine(f"{stub_label}")
                self.emitter.emitLine(f"  ldi A {dst_addr_token.text}")         # Dst NIC ID into A
                self.emitter.emitLine(f"  ldi C {service_id_token.text}")       # Service ID into C
                self.emitter.emitLine(f"  ldi K {reply_pid_token.text}")        # NEW: Reply PID into K
                self.emitter.emitLine(f"  call @stacks_network_write")          # Call runtime helper. It expects value in B.
                self.emitter.emitLine(f"  ret")                                 # Return to caller.
                self.emitter.exit_function_definition_emission()
                self.nl()
            else:
                self.abort(f"Expected READ or WRITE after CONNECTION, got {self.curToken.kind.name if self.curToken else 'None'}")
            self._dedent()
        
        # | expression "STARTPROCESS" nl
        # | expression "STOPPROCESS" nl
        # | ({expression} | st) ( "PRINT" nl | "PLOT" nl | "AS" ident nl | "DO"   nl {statement} nl "END" nl | "GOTO" ident) nl | nl )
        else: #it must be an expression
            if self.checkToken(TokenType.DOT) or self.checkToken(TokenType.DDOT):
                self.st() # Consumes . or ..
            else:
                self.expression() # Consumes expression tokens
            
            # Check for optional action keywords after the expression or stack operation
            if self.checkToken(TokenType.STARTPROCESS):
                self._print_trace("Parsing STARTPROCESS statement.")
                self.nextToken() # Consume STARTPROCESS
                self.emitter.emitLine("pop A")  # PID from STACKS stack into A
                self.emitter.emitLine("int ~SYSCALL_START_PROCESS")
                self.emitter.emitLine("push A") # Push syscall status back onto STACKS stack
                self._print_info("STARTPROCESS: Emitted code to start process and push status.")
                self.nl()
            elif self.checkToken(TokenType.STOPPROCESS):
                self._print_trace("Parsing STOPPROCESS statement.")
                self.nextToken() # Consume STOPPROCESS
                self.emitter.emitLine("pop A")  # PID from STACKS stack into A
                self.emitter.emitLine("int ~SYSCALL_STOP_PROCESS")
                self.emitter.emitLine("push A") # Push syscall status back onto STACKS stack
                self._print_info("STOPPROCESS: Emitted code to stop process and push status.")
                self.nl()
            elif self.checkToken(TokenType.PRINT):
                #self.emitter.emitLine("call @print")
                self.emitter.emitLine("pop A") # Pop value from STACKS stack into A
                self.emitter.emitLine("int ~SYSCALL_PRINT_NUMBER")
                self.emitter.emitLine("int ~SYSCALL_PRINT_NL") # Add newline after printing number
                self._print_trace("PRINT operation.")
                self.nextToken() # Consume PRINT
                self.nl()
            elif self.checkToken(TokenType.PLOT): # PLOT is now active
                self.emitter.emitLine("call @plot") # Call the runtime routine
                self._print_trace("PLOT operation: Emitted call @plot.")
                self.nextToken() # Consume PLOT
                self.nl()
            elif self.checkToken(TokenType.WAIT):
                self.emitter.emitLine("call @stacks_sleep")
                self._print_trace("WAIT operation. STERN-1: Pop value, call sleep/wait routine.")
                self.nextToken() # Consume WAIT
                self.nl()

            elif self.checkToken(TokenType.AS):
                self._print_trace("Parsing AS statement.")
                self._indent()
                self.nextToken() # Consume AS

                # Case 1: value index AS [array_name] (local or shared)
                if self.checkToken(TokenType.OPENBL):
                    self.nextToken() # Consume [
                    if not self.checkToken(TokenType.IDENT):
                        self.abort("Expected array name after '[' in AS [array_name] statement.")

                    array_name_token = self.curToken
                    array_name = array_name_token.text

                    # Check if it's a local array or a shared array
                    if array_name in self.shared_array_details:
                        self._print_info(f"AS: Target '{array_name}' is a SHARED ARRAY (indexed write).")
                        self.emitter.emitLine(f"ldi A &{array_name}") # Load SHARED array base address
                    elif array_name in self.array_details: # Check local arrays
                        self._print_info(f"AS: Target '{array_name}' is a LOCAL ARRAY (indexed write).")
                        self.emitter.emitLine(f"ldi A ${array_name}") # Load LOCAL array base address
                    else:
                         self.abort(f"Undeclared array '{array_name}' in AS [array_name] statement.")
                    
                    # Common emission part for both shared and local indexed writes
                    self.emitter.emitLine("push A")         # Push array base address
                    self.emitter.emitLine("call @stacks_array_write") # Pops value, index, base
                    
                    self.match(TokenType.IDENT)   # Consume array_name (already consumed by array_name_token, but match advances)
                    self.match(TokenType.CLOSEBL) # Consume ]
                    self.nl()
                
                # Case 2: value AS target_name (where target_name can be local/shared array, connection, or local/shared variable)
                elif self.checkToken(TokenType.IDENT):
                    target_name = self.curToken.text

                    if target_name in self.functions:
                        self.abort(f"Cannot use AS with '{target_name}'. It is declared as a function.")

                    # Order of checks is important to distinguish between shared vars and shared arrays.
                    # Both shared vars and shared arrays are in self.shared_symbols.
                    # self.shared_array_details only contains shared arrays.

                    # 1. Is it a shared variable: value AS shared_var_name?
                    #    (Must be in shared_symbols but NOT in shared_array_details)
                    if target_name in self.shared_symbols and target_name not in self.shared_array_details:
                        self._print_info(f"AS: Target '{target_name}' is a SHARED VARIABLE.")
                        # Value is already on the stack from the expression.
                        # Push the address of the shared variable.
                        self.emitter.emitLine(f"ldi A &{target_name}") # Load shared variable address
                        self.emitter.emitLine("push A")         # Push shared variable address
                        self.emitter.emitLine("call @stacks_shared_var_write") # Pops value, address
                        self.match(TokenType.IDENT) # Consume shared_var_name token
                        self.nl()

                    # 2. Is it a local array append: value AS array_name?
                    elif target_name in self.arrays: # self.arrays only contains local arrays
                        self._print_info(f"AS: Target '{target_name}' is a LOCAL ARRAY (append).")
                        self.emitter.emitLine(f"ldi A ${target_name}") # Load local array base address
                        self.emitter.emitLine("push A")         # Push local array base address
                        self.emitter.emitLine("call @stacks_array_append") # Pops value, base
                        self.match(TokenType.IDENT) # Consume array_name
                        self.nl()

                    # 3. Is it a shared array append: value AS shared_array_name?
                    #    (Must be in shared_array_details)
                    elif target_name in self.shared_array_details:
                        self._print_info(f"AS: Target '{target_name}' is a SHARED ARRAY (append).")
                        self.emitter.emitLine(f"ldi A &{target_name}") # Load shared array base address
                        self.emitter.emitLine("push A")         # Push shared array base address
                        self.emitter.emitLine("call @stacks_array_append") # Pops value, base
                        self.match(TokenType.IDENT) # Consume shared_array_name
                        self.nl()

                    # 4. Is it a WRITE connection: value AS connection_name?
                    elif target_name in self.connections:
                        connection_info = self.connection_details[target_name]
                        if connection_info['type'] == 'READ':
                            self.abort(f"Cannot use AS with '{target_name}'. It is a READ connection. AS is for assignment/sending.")
                        # Value is on stack. Connection stub expects it there.
                        # Pop the value from the STACKS data stack into B before calling the stub.
                        self.emitter.emitLine("pop B") # Pop value from STACKS data stack (CPU stack) into B
                        
                        self.emitter.emitLine(f"call {connection_info['stub_label']}")
                        self._print_info(f"AS: Emitted call to {connection_info['stub_label']} to send value via WRITE connection '{target_name}'.")
                        self.match(TokenType.IDENT) # Consume connection_name
                        self.nl()
                    # 5. Is it a local variable (existing or new): value AS variable_name?
                    else: # Must be a local variable
                        if target_name not in self.symbols: # If new, declare it
                            self.symbols.add(target_name)
                            # Emit variable declaration into the current process segment
                            self.emitter.emitLine(f". ${target_name} 1")
                            self._print_info(f"AS: Declaring new variable storage '${target_name}'.")
                        
                        self.emitter.emitLine("pop A")
                        self.emitter.emitLine(f"sto A ${target_name}")
                        self._print_info(f"AS: Assigned stack top to local variable '${target_name}'.")
                        self.match(TokenType.IDENT) # Consume variable_name
                        self.nl()
                else:
                    self.abort(f"Expected '[' or IDENT after AS, got {self.curToken.kind.name if self.curToken else 'None'}")
                self._dedent()

            elif self.checkToken(TokenType.DO):
                num = self.LabelNum()
                #self.nl()
                self.nextToken() # Consume DO
                self.emitter.emitLine("pop A")
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
                self.emitter.emitLine("pop A")
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
                self.emitter.emitLine("push A") 
                self._print_trace(f"Pushing NUMBER {self.curToken.text}")
                self.nextToken()
            elif self.checkToken(TokenType.STRING):
                self._print_trace(f"EXPRESSION: STRING literal '{self.curToken.text}'")
                str_content = self.curToken.text
                
                self.emitter.emitLine(f"; --- String Literal '{str_content}' pushed to stack ---")
                
                # 1. Push null terminator (0)
                self.emitter.emitLine("ldi A 0")
                self.emitter.emitLine("push A")
                
                # 2. Push characters of the string in reverse order of appearance
                for char_val_str in reversed(str_content): # Iterate in reverse
                    assembly_char_representation = char_val_str
                    if char_val_str == ' ':
                        assembly_char_representation = "space" # Use "\space" for the assembler
                    # Add other necessary character escapes if your assembler requires them
                    # e.g., for '\\' itself, or for quotes if they were allowed inside strings.
                    
                    self.emitter.emitLine(f"ldi A \\{assembly_char_representation}")
                    self.emitter.emitLine("push A")
                
                self.emitter.emitLine(f"; --- End String Literal '{str_content}' on stack ---")
                self.nextToken() # Consume STRING token
            elif self.checkToken(TokenType.BT):
                self.nextToken() # Consume BT (`)
                self.emitter.emitLine("call " + "@" + self.curToken.text) # Uses IDENT's text
                self._print_trace(f"Backtick call to '@{self.curToken.text}'. STERN-1: Emit 'call @{self.curToken.text}'.")
                self.match(TokenType.IDENT)
            elif self.checkToken(TokenType.MYPID): # MYPID is a distinct token type
                self.emitter.emitLine("call @get_mypid") # Assuming @get_mypid pushes PID to STACKS stack
                self._print_trace("EXPRESSION: MYPID. Emitted call @get_mypid.")
                self.nextToken() # Consume MYPID
            elif self.checkToken(TokenType.IDENT): # Handles regular identifiers (variables, functions, etc.)
                # ident() handles variables, functions, connections, and array length reads
                self.ident()
            

            elif self.checkToken(TokenType.OPENBL): # Handle [array_name] for indexed read
                # This is for the syntax: index [array_name]
                # The 'index' part should have already been pushed onto the stack by a preceding expression item.
                self.nextToken() # Consume [
                if not self.checkToken(TokenType.IDENT):
                    self.abort("Expected array name after '[' in expression for indexed read.")
                array_name = self.curToken.text

                if array_name in self.shared_array_details:
                    self._print_trace(f"EXPRESSION: Indexed read from SHARED ARRAY '{array_name}'.")
                    self.emitter.emitLine(f"ldi A &{array_name}") # Load SHARED array base address
                elif array_name in self.array_details: # Check local arrays (self.arrays is just a set of names)
                    self._print_trace(f"EXPRESSION: Indexed read from LOCAL ARRAY '{array_name}'.")
                    self.emitter.emitLine(f"ldi A ${array_name}") # Load LOCAL array base address
                else:
                    self.abort(f"Undeclared array '{array_name}' in indexed read expression '[{array_name}]'.")

                self.emitter.emitLine("push A")         # Push array base address
                self.emitter.emitLine("call @stacks_array_read") # Pops index, base; pushes value
                
                self.match(TokenType.IDENT)   # Consume array_name
                self.match(TokenType.CLOSEBL) # Consume ]
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
            self.emitter.emitLine("call @mod")
            #self._print_trace("RPN MODULO. STERN-1: call @mod_op (pop 2, mod, push 1).")
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

        # Check if the identifier is a SHARED Array (used as `&array_name` to get length)
        if ident_name in self.shared_array_details:
            self._print_trace(f"IDENT: '{ident_name}' is a SHARED ARRAY (read length).")
            self.emitter.emitLine(f"ldi A &{ident_name}") # Load shared array base address
            self.emitter.emitLine("push A")         # Push shared array base address
            self.emitter.emitLine("call @stacks_array_length") # Pops base, pushes length
            self.match(TokenType.IDENT) # Consume array name

        # Check if the identifier is a Local Array (used as `array_name` to get length)
        # This must be elif to prevent fall-through if it was a shared_array
        elif ident_name in self.arrays:
            self._print_trace(f"IDENT: '{ident_name}' is an ARRAY (read length).")
            self.emitter.emitLine(f"ldi A ${ident_name}") # Load array base address
            self.emitter.emitLine("push A")         # Push array base address
            self.emitter.emitLine("call @stacks_array_length") # Pops base, pushes length
            self.match(TokenType.IDENT) # Consume array name

        # Check if the identifier is a SHARED Variable
        # It must be in shared_symbols but NOT in shared_array_details
        elif ident_name in self.shared_symbols and ident_name not in self.shared_array_details:
            self._print_trace(f"IDENT: '{ident_name}' is a SHARED VARIABLE.")
            self.emitter.emitLine(f"ldm A &{self.curToken.text}") # Use '&' for STERN-1 shared var access
            self.emitter.emitLine("push A")
            self._print_info(f"Loading shared variable '{ident_name}' to stack.")
            self.match(TokenType.IDENT) # Consume shared variable name

        # Check if the identifier is a Variable
        elif ident_name in self.symbols:
            self._print_trace(f"IDENT: '{ident_name}' is a VARIABLE.")
            self.emitter.emitLine(f"ldm A ${self.curToken.text}") # Use '$' for STERN-1 var access
            self.emitter.emitLine("push A")
            self._print_info(f"Loading variable '{ident_name}' to stack.")
            self.match(TokenType.IDENT) # Consume variable name

        # Check if the identifier is a Function
        elif ident_name in self.functions:
            self._print_trace(f"IDENT: '{ident_name}' is a FUNCTION.")
            self.emitter.emitLine("call @~" + self.curToken.text) # Use '@~' for STACKS function call
            self._print_info(f"Calling function '{ident_name}'. STERN-1: call @~{ident_name}.")
            self.match(TokenType.IDENT) # Consume function name

        # Check if the identifier is a Connection
        elif ident_name in self.connections:
            self._print_trace(f"IDENT: '{ident_name}' is a CONNECTION.")
            details = self.connection_details[ident_name]
            if details['type'] == 'READ':
                # The user-defined service routine (e.g., @myServiceRoutine) is called.
                # It's expected to push value and status onto STACKS stack.
                # Pass current PID in A to the service routine.
                self.emitter.emitLine(f"call @get_mypid") # Pushes current PID to STACKS stack
                self.emitter.emitLine(f"pop A")           # Pops PID from stack into A
                self.emitter.emitLine(f"call {details['routine']}")
                self._print_info(f"Executing READ connection '{ident_name}' by calling {details['routine']}.")
            elif details['type'] == 'WRITE':
                # The generated stub (e.g., @~conn_myNetWrite_write_X) is called.
                # It expects the value to write to be on TOS. It pops it, sets up params, and calls runtime.
                self.emitter.emitLine(f"call {details['stub_label']}")
                self._print_info(f"Executing WRITE connection '{ident_name}' by calling {details['stub_label']}.")
            self.match(TokenType.IDENT) # Consume connection name
        else:
            self.abort(f"Referencing undeclared identifier (variable, function, connection, array, or shared symbol): '{ident_name}'")

        self._dedent()
        # self._print_trace("Exiting ident()") # match() will be the last call, advancing token

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