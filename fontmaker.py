
def makefont():
    font = {}

    generic = [
        1, 0, 1, 0, 
        0, 1, 0, 1, 
        1, 0, 1, 0, 
        0, 1, 0, 1, 
        1, 0, 1, 0 
    ]

    font[0] = generic # null
    font[1] = generic
    font[2] = ['0', '1', '0', '0', '0', '1', '0', '0', '0', '1', '0', '0', '0', '0', '0', '0', '0', '1', '0', '0']
    font[3] = generic
    font[4] = generic
    font[5] = generic
    font[6] = generic
    font[7] = generic
    font[8] = generic
    font[9] = generic
    font[10] = generic
    font[11] = generic
    font[12] = generic
    font[13] = generic
    font[14] = generic
    font[15] = generic  
    font[16] = generic
    font[17] = generic
    font[18] = generic
    font[19] = generic

    font[20] = generic
    font[21] = generic
    font[22] = generic
    font[23] = generic
    font[24] = generic
    font[25] = generic
    font[26] = generic
    font[27] = generic
    font[28] = generic
    font[29] = generic

    font[30] = [
        0, 0, 0, 0, 
        0, 0, 0, 0, 
        0, 0, 0, 0, 
        0, 0, 0, 0, 
        0, 0, 0, 0 
    ] # blank
    font[31] = [
        0, 1, 1, 0, 
        1, 0, 0, 1, 
        1, 1, 1, 1, 
        1, 0, 0, 1, 
        1, 0, 0, 1
    ] #  'A': [0x4, 0xa, 0xe, 0xa, 0xa]
    font[32] = [
        1,1,1,0,
        1,0,0,1,
        1,1,1,0,
        1,0,0,1,
        1,1,1,0
    ] # B
    font[33] = [
        1,1,1,1,
        1,0,0,0,
        1,0,0,0,
        1,0,0,0,
        1,1,1,1
    ] # C
    font[34] = ['1', '1', '1', '0', '1', '0', '0', '1', '1', '0', '0', '1', '1', '0', '0', '1', '1', '1', '1', '0'] # D
    font[35] = ['1', '1', '1', '1', '1', '0', '0', '0', '1', '1', '1', '0', '1', '0', '0', '0', '1', '1', '1', '1']
    font[36] = generic
    font[37] = generic
    font[38] = ['1', '0', '0', '1', '1', '0', '0', '1', '1', '1', '1', '1', '1', '0', '0', '1', '1', '0', '0', '1']
    font[39] = generic
    font[40] = generic
    font[41] = generic
    font[42] = ['1', '0', '0', '0', '1', '0', '0', '0', '1', '0', '0', '0', '1', '0', '0', '0', '1', '1', '1', '1']
    font[43] = generic
    font[44] = generic
    font[45] = ['0', '1', '1', '0', '1', '0', '0', '1', '1', '0', '0', '1', '1', '0', '0', '1', '0', '1', '1', '0']
    font[46] = generic
    font[47] = generic
    font[48] = ['1', '1', '1', '0', '1', '0', '0', '1', '1', '1', '1', '0', '1', '0', '1', '0', '1', '0', '0', '1']
    font[49] = generic
    font[50] = generic
    font[51] = generic
    font[52] = generic
    font[53] = [
        1,0,0,1,
        1,0,0,1,
        1,1,1,1,
        1,1,1,1,
        1,0,0,1
    ] # W
    font[54] = generic
    font[55] = generic
    font[56] = generic

    return font

font = makefont()

print(font)
fontData = []

for key in font.keys():
    fontData = []
    for n in font[key]:
        fontData.append(n)
    with open("./bin/standard.font", "a") as file:
        for data in fontData:
            file.write(str(data) + " ")
        file.write("\n")


