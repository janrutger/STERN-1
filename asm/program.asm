# MAIN program
# runs after init

call @init_stern
call @init_kernel

. $x_indx 1
% $x_indx 0

@program
        ldi X 25
        ldi Y 16
        
    :loop
        call @check_XY_bounderies
        call @calc_pxl_pntr
        call @toggle_pxl

        call @KBD_READ
        call @wait

        call @toggle_pxl

        addi X 1
        addi Y 1
    jmp :loop
       
halt


# helper routines
@wait
    ldi L 1000
    :lus
        subi L 1
        nop
        tst L 0
        jmpf :lus
ret



# calc pixel pointer
# expects X and Y register for pos pixel
# calculates the mem pointer pos for this X Y
@calc_pxl_pntr
    ld I Y 
    muli I 64
    add I X
ret


@toggle_pxl
    # Expects Reg I as pxl mem pointer
    # Toggle pixel Ri mem position

    # draw the pixel
    ldi C 1
    xorx C $VIDEO_MEM
    stx C $VIDEO_MEM
ret




@check_XY_bounderies
# checkd of the X an Y positions
# Fits on screen, 
# reset XY when out of bounderie
. $last_x_pos 1
. $last_y_pos 1

% $last_x_pos 64
% $last_y_pos 32

# check bounderies
    ldm M $last_x_pos
    dmod X M 
    ld X M
    ldm M $last_y_pos
    dmod Y M
    ld Y M
ret