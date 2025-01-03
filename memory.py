from typing import List

class Memory:
    def __init__(self, size: int):
        self.memory = [1] * size

    def write(self, address: int, value: str) -> None:
        self.validAddress(address)
        self.memory[address] = value

    def read(self, address: int) -> str:
        self.validAddress(address)
        return self.memory[address]

    def validAddress(self, address) -> bool:
        if address <= self.MEMmax() and address >= 0:
            return True
        else:
            exit("FATAL: Memory adress out of range")

    def MEMmax(self) -> int:
        return (len(self.memory)-1)