from typing import List

class Memory:
    def __init__(self, size: int):
        self.memory = ["9999"] * size

    def write(self, address: int, value: str) -> None:
        self.validAddress(address)
        self.memory[address] = value

    def read(self, address: int) -> str:
        self.validAddress(address)
        return self.memory[address]

    # def validAddress(self, address) -> bool:
    #     if address <= self.MEMmax() and address >= 0:
    #         return True
    #     else:
    #         exit("FATAL: Memory adress out of range")

    def validAddress(self, address) -> bool:
        # Use len() directly, MEMmax() was just len()-1
        if 0 <= address < len(self.memory):
            return True
        else:
            # Consider raising an exception instead of exiting directly
            # exit(f"FATAL: Memory address {address} out of range")
            raise IndexError(f"Memory address {address} out of range (0-{len(self.memory)-1})")


    def MEMmax(self) -> int:
        return (len(self.memory)-1)