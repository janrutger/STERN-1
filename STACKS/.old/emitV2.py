from typing import List

# Emitter object keeps track of the generated code and outputs it.
class Emitter:
    def __init__(self, outputPath: str):
        self.fullPath: str = outputPath
        self._header_lines: List[str] = []
        self._code_lines: List[str] = []
        self._function_lines: List[str] = []
        self.context: str = "program"  # Can be "program" or "functions"

    def emit(self, code: str) -> None:
        # This method appends code without a newline.
        # parseV2.py currently does not use this method, only emitLine.
        if self.context == "program":
            self._code_lines.append(code)
        else:
            self._function_lines.append(code)

    def emitLine(self, code: str) -> None:
        # This method appends code followed by a newline.
        if self.context == "program":
            self._code_lines.append(code + '\n')
        else:
            self._function_lines.append(code + '\n')

    def headerLine(self, code: str) -> None:
        self._header_lines.append(code + '\n')

    def writeFile(self) -> None:
        with open(self.fullPath, 'w') as outputFile:
            outputFile.write("".join(self._header_lines))
            outputFile.write("".join(self._code_lines))
            outputFile.write("".join(self._function_lines))