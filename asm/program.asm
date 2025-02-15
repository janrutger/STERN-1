# MAIN program
# runs after init

call @init_stern
call @init_kernel


@program
    . $paddle_sprite 32
    . $paddle_pointer 1
    . $paddle_w 1
    . $paddle_h 1
    . $paddle_x 1
    . $paddle_y 1

    % $paddle_sprite 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 
    % $paddle_pointer $paddle_sprite
    % $paddle_w 1
    % $paddle_h 2
    % $paddle_x 3
    % $paddle_y 5

# ball pixel
    . $ball_sprite 1
    . $ball_pointer 1
    . $ball_w 1
    . $ball_h 1
    . $ball_x 1
    . $ball_y 1

    % $ball_sprite 1
    % $ball_pointer $ball_sprite
    % $ball_w 1
    % $ball_h 1
    % $ball_x 63
    % $ball_y 16

    . $ball_x_dir 1
    . $ball_y_dir 1

    # directions: 1 and -1
    # X=1 right,  X=-1 left
    # X Y=1 down, Y=-1 up 
    % $ball_x_dir -1
    % $ball_y_dir -1

    . $ball_update_counter 1
    % $ball_update_counter 300

#######
    call @draw_ball
    call @update_paddle
    :pong
        ldm M $ball_update_counter
        tst M 0
            subi M 1
            sto M $ball_update_counter
        jmpf :no_ball_update   

            call @update_ball
            call @check_collision

            ldi M 150
            sto M $ball_update_counter
        :no_ball_update

        call @handle_input
        

    jmp :pong

:end  
int 2
halt

## Helpers from Here 

@handle_input 
    call @KBD_READ

    tst A \Up
    jmpf :Down
        # Paddle UP
        call @update_paddle
        ldm M $paddle_y
        subi M 1
        sto M $paddle_y
        call @update_paddle
    ret

    :Down
    tst A \Down
    jmpf :return
        # Paddle down
        call @update_paddle
        ldm M $paddle_y
        addi M 1
        sto M $paddle_y
        call @update_paddle
    ret

    :return
    tst A \Return
    jmpf :no_input
        # exit program
        jmp :end
:no_input
ret

@update_paddle
    ldm A $paddle_w
    ldm B $paddle_h
    ldm C $paddle_pointer

    ldm X $paddle_x
    ldm Y $paddle_y

    int 5
ret

@draw_ball
    ldm A $ball_w
    ldm B $ball_h
    ldm C $ball_pointer

    ldm X $ball_x
    ldm Y $ball_y
    int 5
ret


@update_ball
    ldm A $ball_w
    ldm B $ball_h
    ldm C $ball_pointer

    ldm X $ball_x
    ldm Y $ball_y
    ;int 5

    # check directions
    call @check_directions

    # refresh ball
    int 5
    ldm X $ball_x
    ldm Y $ball_y
    int 5


ret


@check_directions
    # Check X for 'win' line
    tst X 1
    jmpf :test_top_line
        ldi M 64
        sto M $ball_x

        ldm M $ball_y_dir
        muli M -1
        sto M $ball_y_dir

        ;ldm L $ball_y
        ;addi L 1
        ;sto L $ball_y

    :test_top_line
    tst Y 0
    jmpf :test_low_line
        ldm M $ball_y_dir
        muli M -1
        sto M $ball_y_dir
    :test_low_line
    tst Y 31
    jmpf :update_xy
        ldm M $ball_y_dir
        muli M -1
        sto M $ball_y_dir

    :update_xy
        ldm K $ball_x
        ldm M $ball_x_dir
        add K M 
        sto K $ball_x

        ldm L $ball_y
        ldm M $ball_y_dir
        add L M 
        sto L $ball_y
            
ret


@check_collision

    ldm K $ball_x
    ldm M $paddle_x

    tste K M 
    jmpf :done

    # possible collision 
    # check the start of the paddle 
    ldm L $ball_y
    ldm M $paddle_y
    tstg M L
    jmpt :done

    #check the tail of the paddle
    ldm K $paddle_h
    add M K 
    ldi K 32
    dmod M K 
    ld M K 

    tstg L M 
    jmpt :done
    ;call @draw_ball
    call @collision

:done
ret

@collision
    call @draw_ball
    call @update_paddle
    ldm M $paddle_h
    addi M 1
    sto M $paddle_h
    ldi M 63
    sto M $ball_x
    call @draw_ball
    call @update_paddle
ret

