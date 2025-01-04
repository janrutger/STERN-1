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


# After init
# call the start routine
@program
    call @draw_char
    halt

# some exampels
@clear_screen
    :loop
        inc I $VIDEO_POINTER
        ldi M 1
        stx M $VIDEO_MEM

        ldm L $VIDEO_SIZE
        tste I L
    jmpf :loop
ret

# draw a char to the screen
@draw_char
    ldi Y 5
    ldi X 10

    ldm C $FONTS
    addi C \a

    call @do_draw

ret


. $row 1
. $pxl 1
@do_draw
    # Start of row loop
    sto Z $row
    :row_loop
    inc A $row
        ld I Y
        add I A 
        muli I 64
        add I X

        # start of pixel loop
        sto Z $pxl
        :pxl_loop
        inc B $pxl
 

        tst B 8
        jmpf :pxl_loop
    tst A 5
    jmpf :row_loop

ret


# def draw_mem(x, y, sprite, memory, rows):
#        print("Draw Sprite in memory")
#        for i in range(rows):
#            mem_pointer = (y+i) * 64 + x
#            for n in range(8):
#                memory[mem_pointer+n] = sprite[n + (i*8)]
#        return(memory)