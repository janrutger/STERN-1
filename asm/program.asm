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
        call @draw_pixel
        call @wait
        call @draw_pixel

        subi X 1
        addi Y 1
    jmp :loop
       
halt


# helper routines
@wait
    ldi L 1000

    :lus
        subi L 1
        tst L 0
        jmpf :lus
ret


@draw_pixel
    #expect Reg X for x-pos
    #expect Reg Y for Y-pos
    #expect Reg C for color (black = 0, white = 1)
    

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

# calc pixel pointer
    ld I Y 
    muli I 64
    add I X

# draw pixel
    ldi C 1
    xorx C $VIDEO_MEM
    stx C $VIDEO_MEM


ret


