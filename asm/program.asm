# MAIN program
# runs after init

call @init_stern
call @init_kernel


@program
    # drawing one pixel from 
    # left to right

    . $x_pixel_max 1
    . $y_pixel_max 1
    . $c_pixel 1

    % $x_pixel_max 64
    % $y_pixel_max 32

    % $c_pixel 1

    int 1

    ldi X 32
    ldi Y 16
    ldi C 1
    call @draw_pixel

    #refresh
    :end_less
        ldi Y 16
        ldi C 0
        call @draw_pixel

        tst X $x_pixel_max
        jmpf :draw_next
            ld X Z 
            jmp :end_less
        :draw_next
            ldi C 1
            addi X 1
            call @draw_pixel
        jmp :end_less
halt


# helper routines
. $pxl_mem_adres 1


@draw_pixel
    # expecting x
    # expecting Y
    # expecting c

    # calc the memory adres
    # to write in video

    ldm L $VIDEO_MEM

    ld M Y
    muli M 64
    add M X

    add M L
    sto M $pxl_mem_adres

    ld I Z 
    stx C $pxl_mem_adres

ret

