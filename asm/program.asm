# MAIN program
# runs after init

call @init_stern
call @init_kernel


@program
# print a sprite
# Reg A = sprite widht (X)
# Reg B = sprite height (Y)
# Reg C = pointer to sprite array
# Reg X = X pos of the first pixel
# Reg Y = Y pos of the first pixel

    . $sprite 4
    % $sprite 1 1 1 1

    ldi A 2
    ldi B 2
    ldi C $sprite

    ldi X 25
    ldi Y 16
        
    :loop

        . $start_x 1
        . $start_y 1
        sto X $start_x
        sto Y $start_y

        . $pixel_w_pntr 1
        . $pixel_h_pntr 1
        . $current_sprite 1
        . $sprite_pntr 1

        sto C $current_sprite

        sto Z $sprite_pntr
        sto Z $pixel_h_pntr
        :row_loop
            inc K $pixel_h_pntr
            sto Z $pixel_w_pntr
            ldm X $start_x
                :col_loop
                inc L $pixel_w_pntr

                    inc I $sprite_pntr
                    ldx C $current_sprite

                    add X L
                    ;call @check_XY_bounderies
                    call @calc_pxl_pntr
                    call @toggle_pxl
 
                ldm M $pixel_w_pntr
                tstg A M
                jmpt :col_loop
            
            ldm M $pixel_h_pntr
            tstg B M
            jmpt :row_loop     
    jmp :return


:return   
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