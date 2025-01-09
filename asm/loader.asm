. $FONTS 1
. $VIDEO_MEM 1
. $VIDEO_SIZE 1


ldi Z 0

ldi M 1024
sto M $FONTS

ldi M 14336
mil A B
sto M $VIDEO_MEM

# 2k - 1 = 2047
ldi M 2047
sto M $VIDEO_SIZE


# After init
# call the start routine
@program
    ldi Y 25
    ldi X 10
    ldi C \a
    call @draw_char

    ldi Y 25
    ldi X 15
    ldi C \b
    call @draw_char

    ldi Y 25
    ldi X 20
    ldi C \c 
    call @draw_char

    ldi Y 25
    ldi X 25
    ldi C \d 
    call @draw_char

    ldi Y 25
    ldi X 30
    ldi C \w 
    call @draw_char

    call @fill_screen
halt


# some example calls

@fill_screen
. $video_pointer 1

sto Z $video_pointer

    :loop
        inc I $video_pointer
        ldi M 1
        stx M $VIDEO_MEM

        ldm L $VIDEO_SIZE
        tste I L
    jmpf :loop
ret





@draw_char
# Needs
. $font_pointer 1
. $row_pointer 1
. $pxl 1
#expects:
# Reg X = X-pos on screen
# Reg Y = Y-pos on screen
# Reg C =  char to draw
    # calc the pointer to the font
    # a char = 40 pixels
    muli C 40
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
        tst I 7
        jmpf :pxl_loop

    # end of row loop
    addi A 1
    tst A 5
    jmpf :row_loop
ret