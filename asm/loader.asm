. $FONTS 1
. $VIDEO_MEM 1
. $VIDEO_SIZE 1
. $INT_VECTORS 5
di
ldi Z 0

ldi M 1024
sto M $FONTS

ldi M 14336
sto M $VIDEO_MEM

ldi M 4096
sto M $INT_VECTORS

# 2k - 1 = 2047
ldi M 2047
sto M $VIDEO_SIZE

# set the ISR vectors
;ldi M @fill_screen
ldi M @draw_interrupt
ldi I 0
stx M $INT_VECTORS

ldi M @draw_char
ldi I 1
stx M $INT_VECTORS

ldi M @clear_screen
ldi I 2
stx M $INT_VECTORS

ei

# After init
# call the start routine
@program
    int 2
    :endless

    jmp :endless

:done 
    halt

# Interrupts
@draw_interrupt
di
    tst A 99
    jmpt :end
    tst A \q
    jmpt :done
    ldi Y 25
    ldi X 10
    ld C A
    int 1
:end
    ei
    rti



# some example calls

@fill_screen
. $video_pointer 1
di
sto Z $video_pointer
ldi M 1
    :loop
        inc I $video_pointer
        ;ldi M 1
        stx M $VIDEO_MEM

        ldm L $VIDEO_SIZE
        tste I L
    jmpf :loop
;ret
ei
rti


@clear_screen
; $video_pointer 1
di
sto Z $video_pointer
ldi M 0
    :loop_clear
        inc I $video_pointer
        ;ldi M 0
        stx M $VIDEO_MEM

        ldm L $VIDEO_SIZE
        tste I L
    jmpf :loop_clear
;ret
ei
rti





@draw_char
# Needs
. $font_pointer 1
. $row_pointer 1
. $pxl 1
#expects:
# Reg X = X-pos on screen
# Reg Y = Y-pos on screen
# Reg C =  char to draw
    di

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
;ret
ei
rti