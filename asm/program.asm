# MAIN program
# runs after init

call @init_stern
call @init_kernel

. $x_indx 1
% $x_indx 0

@program
    ldi Y 10
    :loop
        inc X $x_indx
        ldi C \b 
        int 3

        ldm M $x_indx
        tst M 63
        jmpf :next
            sto Z $x_indx
        :next
            ;ldi C \space
            ;int 3
            int 1

        jmp :loop

halt


# helper routines
. $pxl_mem_pntr 1

@draw_sprite


ret

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
    sto M $pxl_mem_pntr

    ld I Z 
    stx C $pxl_mem_pntr

ret

