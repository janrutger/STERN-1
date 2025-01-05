. $FONTS 1
. $VIDEO_MEM 1
. $VIDEO_SIZE 1


ldi Z 0

ldi M 1024
sto M $FONTS

ldi M 14336
sto M $VIDEO_MEM

ldi M 2048
sto M $VIDEO_SIZE




# After init
# call the start routine
@program
    call @draw_char
    halt


# some exampels

@clear_screen
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
. $font_pointer 1
@draw_char
    ldi Y 5
    ldi X 10


    #char x 40 pixels
    ldi C \a 
    muli C 40
    ldm M $FONTS
    add C M
    sto C $font_pointer

    call @do_draw
;ret

@draw_char2
    ldi Y 5
    ldi X 15


    #char x 40 pixels
    ldi C \b 
    muli C 40
    ldm M $FONTS
    add C M
    sto C $font_pointer

    call @do_draw

@draw_char3
    ldi Y 5
    ldi X 10


    #char x 40 pixels
    ldi C \3
    muli C 40
    ldm M $FONTS
    add C M
    sto C $font_pointer

    call @do_draw

ret


. $row_pointer 1
@do_draw
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
        . $pxl 1
        # start of pixel loop
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