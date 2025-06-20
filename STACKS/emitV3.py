from typing import List
 
# Emitter object keeps track of the generated code and outputs it.
class Emitter:
    def __init__(self, outputPath: str):
        self.fullPath: str = outputPath
        self._header_lines: List[str] = []
        self._shared_data_lines: List[str] = [] # For shared variables/arrays (. &symbol size)
        self._code_lines: List[str] = [] # Main code stream, including per-process code
        # For collecting function code within the current process segment
        self._current_process_function_lines: List[str] = []
        self._is_emitting_function_code: bool = False

    def emit(self, code: str) -> None:
        # This method appends code without a newline.
        # For STACKS V3, prefer emitLine. This method is kept for potential future use.
        if self._is_emitting_function_code:
            self._current_process_function_lines.append(code)
        else:
            self._code_lines.append(code)

    def emitLine(self, code: str) -> None:
        # This method appends code followed by a newline.
        if self._is_emitting_function_code:
            self._current_process_function_lines.append(code + '\n')
        else:
            self._code_lines.append(code + '\n')

    def emitSharedDataLine(self, code: str) -> None:
        # This method appends code to the shared data section.
        self._shared_data_lines.append(code + '\n')

    def headerLine(self, code: str) -> None:
        self._header_lines.append(code + '\n')

    def writeFile(self) -> None:
        with open(self.fullPath, 'w') as outputFile:
            outputFile.write("".join(self._header_lines))
            outputFile.write("".join(self._code_lines)) # All code, including functions flushed per process
            outputFile.write("".join(self._shared_data_lines)) # Shared data definitions go after code

    def start_process_segment(self, pid: str, stack_size: str) -> None:
        # All subsequent code, data, and functions for this process
        # will be emitted into the main code lines.
        self._code_lines.append(f".PROCES {pid} {stack_size}\n")
        self._code_lines.append(f":~proc_entry_{pid} ; Default entry point for process {pid}\n")
        self._current_process_function_lines = [] # Reset for the new process
        self._is_emitting_function_code = False   # Ensure reset for the new process context

    def enter_function_definition_emission(self) -> None:
        self._is_emitting_function_code = True

    def exit_function_definition_emission(self) -> None:
        self._is_emitting_function_code = False

    def end_process_segment(self, pid: str) -> None:
        # Called when a PROCESS block naturally ends.
        # The process should stop itself. PID needs to be in A for the syscall.
        # This should come BEFORE the function code is appended.
        self._code_lines.append(f"ldi A {pid} ; PID of the current process ending\n")
        self._code_lines.append("int ~SYSCALL_STOP_PROCESS ; Implicit stop at end of process block\n")

        # Append any collected function code for this process to the main code stream
        self._code_lines.extend(self._current_process_function_lines)
        self._current_process_function_lines = [] # Clear after flushing