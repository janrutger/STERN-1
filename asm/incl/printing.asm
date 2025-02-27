@print_cursor
    ldi A \_ 
    call @print_char
ret

@cursor_on
    ldi A \_ 
    call @print_char
ret

@cursor_off
    ldi A \space
    call @print_char
ret

@print_char
# expexts $cursor_x and $cursor_y
# char to print in A 

    ldm X $cursor_x
    ldm Y $cursor_y

    # calc memory position, input_string_index
    ld I Y 
    muli I 64
    add I X

    # print on screen
    stx A $VIDEO_MEM
ret   