. $FONTS 1
. $VIDEO_MEM 1
. $VIDEO_SIZE 1
. $VIDEO_POINTER 1

ldi Z 0

ldi M 1024
sto M $FONTS

ldi M 14336
sto M $VIDEO_MEM

ldi M 2048
sto M $VIDEO_SIZE

sto Z $VIDEO_POINTER

:loop
    inc I $VIDEO_POINTER
    ldi M 1
    stx M $VIDEO_MEM

    ldm L $VIDEO_SIZE
    tste I L

    jmpf :loop

    









halt