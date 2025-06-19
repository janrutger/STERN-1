def decode(memValue: str) -> tuple:
    instruction      = int(memValue[:2])
    instruction_type = int(memValue[0])

    if instruction_type == 1:
        return((instruction, None, None))
    elif instruction_type == 2:
        operand = int(memValue[2:])
        return((instruction, operand, None))
    elif instruction_type in [3, 4, 5, 6, 7, 8]:
        operand1 = int(memValue[2])
        operand2 = int(memValue[3:])
        return((instruction, operand1, operand2))
    elif instruction_type == 9:
        operand = int(memValue[2:])
        return((instruction, operand, None))
    else:
        raise ValueError("Decoder error")
    