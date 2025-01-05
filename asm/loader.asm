. $FONTS 1
. $VIDEO_MEM 1
. $VIDEO_SIZE 1


ldi Z 0

ldi M 1024
sto M $FONTS

ldi M 14336
sto M $VIDEO_MEM

# 2k - 1 = 2047
ldi M 2047
sto M $VIDEO_SIZE




# After init
# call the start routine
@program
    call @draw_char
    call @fill_screen
    halt


# some exampels

@fill_screen
. $VIDEO_POINTER 1

sto Z $VIDEO_POINTER

    :loop
        inc I $VIDEO_POINTER
        ldi M 1
        stx M $VIDEO_MEM

        ldm L $VIDEO_SIZE
        tste I L
    jmpf :loop
ret


# draw char example

@draw_char
    ldi Y 25
    ldi X 10
    ldi C \a
    call @do_draw

    ldi Y 25
    ldi X 15
    ldi C \b
    call @do_draw

    ldi Y 25
    ldi X 20
    ldi C \c 
    call @do_draw

    ldi Y 25
    ldi X 25
    ldi C \d 
    call @do_draw
ret


@do_draw
. $font_pointer 1
. $row_pointer 1

    # calc the pointer to the font
    # 1 char = 40 pixels + Font start adres
    muli C 40
    ldm M $FONTS
    add C M
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
       
        . $row 1
        # start of row pixel loop
        ldi I 0
        sto I $row
        :pxl_loop
            # draw pixel here
            ldi I 0
            ldx C $font_pointer
            inc I $font_pointer
            
            inc I $row              
            stx C $row_pointer
            
        # end of pxl loop
        tst I 7
        jmpf :pxl_loop

    # end of row loop
    addi A 1
    tst A 5
    jmpf :row_loop
ret