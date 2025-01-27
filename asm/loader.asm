. $FONTS 1
. $VIDEO_MEM 1
. $VIDEO_SIZE 1
. $INT_VECTORS 1

. $KBD_BUFFER 16
. $KBD_BUFFER_ADRES 1
. $KBD_READ_PNTR 1
. $KBD_WRITE_PNTR 1




@init_stern
    ldi Z 0

    # init keyboard buffer
    sto Z $KBD_READ_PNTR
    sto Z $KBD_WRITE_PNTR
    ldi M $KBD_BUFFER
    sto M $KBD_BUFFER_ADRES


    # init Fonts and Display memory pointer
    ldi M 2024
    sto M $FONTS

    ldi M 14336
    sto M $VIDEO_MEM

    # 2k - 1 = 2047
    ldi M 2047
    sto M $VIDEO_SIZE

    # init interrupt vectors
    # Memory location where int vectors are stored
    ldi M 4096
    sto M $INT_VECTORS

    # set the ISR vectors
    ldi I 0
    ldi M @KBD_WRITE
    stx M $INT_VECTORS

    ldi I 1
    ldi M @clear_screen
    stx M $INT_VECTORS

    ldi I 2
    ldi M @fill_screen
    stx M $INT_VECTORS

    ldi I 3
    ldi M @DRAW_CHAR
    stx M $INT_VECTORS

    ldi I 4
    ldi M @scroll_screen
    stx M $INT_VECTORS

    ## Done interrupt factors

    # don't forget to enable Interrupts
    # int 1, clears the screen, 
    # return from interrupt (rti)  enbles interrupts
    int 1
ret



# Interrupts ISR
## keyboard ISR handler
## Register A containts the keyboard value
@KBD_WRITE 
    # check for full buffer
    ldm M $KBD_WRITE_PNTR
    addi M 1
    andi M 15
    ldm L $KBD_READ_PNTR
    tste M L 

    # when true, the buffer is full, do nothing
    jmpt :end_kbd_write

    # otherwise store value in buffer
    inc I $KBD_WRITE_PNTR
    stx A $KBD_BUFFER_ADRES

    # check for last adres in buffer
    # check modulo 16, by andi 15
    ldm M $KBD_WRITE_PNTR
    andi M 15
    # cycle to 0 when mod = 0
    tste M Z
    jmpf :end_kbd_write
        sto Z $KBD_WRITE_PNTR
:end_kbd_write    
rti


@KBD_READ 
    # It's a subroutine
    # returns kbd value in A 
    # returns \null when empty
    di
    # check for empty buffer
    ldm I $KBD_READ_PNTR
    ldm M $KBD_WRITE_PNTR
    tste I M 
    jmpt :empty_kbd_buffer
        # when not empty, read buffer to a
        ldx A $KBD_BUFFER_ADRES

    addi I 1
    sto I $KBD_READ_PNTR

    # check for last adres in buffer
    # check modulo
    ldm M $KBD_READ_PNTR
    andi M 15
    # cycle to 0 when mod = 0
    tste M Z
    jmpf :end_kbd_read
        sto Z $KBD_READ_PNTR 
        jmp :end_kbd_read  
    

    :empty_kbd_buffer
        ldi A \null

:end_kbd_read 
ei   
ret

## END keyboard ISR



@fill_screen
. $video_pointer 1
sto Z $video_pointer
ldi M 1
    :loop
        inc I $video_pointer
        stx M $VIDEO_MEM

        ldm L $VIDEO_SIZE
        tste I L
    jmpf :loop
rti


@clear_screen
; $video_pointer 1
sto Z $video_pointer
ldi M 0
    :loop_clear
        inc I $video_pointer
        stx M $VIDEO_MEM

        ldm L $VIDEO_SIZE
        tste I L
    jmpf :loop_clear
rti


@DRAW_CHAR 
# Needs
. $font_pointer 1
. $row_pointer 1
. $pxl 1
#expects:
# Reg X = X-pos on screen
# Reg Y = Y-pos on screen
# Reg C =  char to draw
    ;di

    # calc the pointer to the font
    # a char = 20 pixels
    muli C 20
    sto C $font_pointer

# Start of row loop
    ldi A 0
    :row_loop

        ld M Y
        add M A 
        muli M 64
        add M X
        ldm L $VIDEO_MEM
        add M L
        sto M $row_pointer
       
        # start of pixel loop
        ldi I 0
        sto I $pxl
        :pxl_loop
            # draw pixels here

            # get value from FONT
            inc I $font_pointer
            ldx C $FONTS

            # draw pixel in video mem
            inc I $pxl              
            stx C $row_pointer
            
        # end of pxl loop
        tst I 3
        jmpf :pxl_loop

    # end of row loop
    addi A 1
    tst A 5
    jmpf :row_loop
rti




@scroll_screen
### MOVE memory block n positions
. $screen_start 1
. $read_pointer 1
. $pxls_to_shift 1
. $shifting 1

ldm M $VIDEO_MEM
sto M $screen_start

# n postions to move
# 6 lines x 64 pixels = 384
addi M 384
# pointer to read adres
sto M $read_pointer

# number of shifts
# total lenght of block - pixels to shift
ldm M $VIDEO_SIZE
subi M 384 
sto M $pxls_to_shift

ldi I 0
sto I $shifting

:shift_loop
    inc I $shifting
    ldx M $read_pointer
    stx M $screen_start

    ldm K $shifting
    ldm L $pxls_to_shift
    tste K L 
jmpf :shift_loop

# fill with zero 
ld M Z
:fill_zero
    inc I $shifting
    stx Z $screen_start

    addi M 1
    # 6 lines x 64 pixels = 384
    tst M 384
jmpf :fill_zero    

rti
;ret

