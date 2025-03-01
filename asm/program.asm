call @init_stern

. $input_buffer 64
. $input_buffer_pntr 1
. $input_buffer_indx 1
% $input_buffer_pntr $input_buffer
% $input_buffer_indx 0

. $cursor_x 1
. $cursor_y 1
% $cursor_x 0
% $cursor_y 0

. $BCDstring 16
. $BCDstring_pntr 1
. $BCDstring_index 1
% $BCDstring_pntr $BCDstring

@program
    call @get_input_line
    call @tokennice_line
    ;call @execute_tokens

    ldi A \a
    call @print_to_BCD
    call @cursor_on

    nop
halt


@do_addition
ret

@do_substraction
ret

@do_dot
ret

@do_bang
ret


## INCLUDE helpers

INCLUDE read_char
INCLUDE get_input_line
INCLUDE tokennice_line
INCLUDE check_char_type
INCLUDE get_number_token
INCLUDE get_operator_token
INCLUDE printing
INCLUDE errors



