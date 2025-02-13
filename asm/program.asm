# MAIN program
# runs after init

call @init_stern
call @init_kernel


@program
    . $paddle_sprite 4
    . $paddle_pointer 1
    . $paddle_w 1
    . $paddle_h 1
    . $paddle_x 1
    . $paddle_y 1

    % $paddle_sprite 1 1 1 1
    % $paddle_pointer $paddle_sprite
    % $paddle_w 1
    % $paddle_h 4
    % $paddle_x 3
    % $paddle_y 14

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
    % $ball_x 60
    % $ball_y 10



    call @update_paddle
    :pong

        call @update_ball
        call @handle_input

    jmp :pong

:end  
int 2
halt


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

@update_ball
    ldm A $ball_w
    ldm B $ball_h
    ldm C $ball_pointer

    

    ldm X $ball_x
    ldm Y $ball_y

    int 5
ret

