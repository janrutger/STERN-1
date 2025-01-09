

class Interrupts:
    def __init__(self) -> None:
        self.pendingInterrupts = []
    


    def interrupt(self, int: int, value: int) -> None:
        self.pendingInterrupts.append((int, value))

    def get(self) -> tuple:
        return(self.pendingInterrupts.pop())
    
    def pending(self) -> bool:
        if len(self.pendingInterrupts) != 0:
            return(True)
        else:
            return(False)