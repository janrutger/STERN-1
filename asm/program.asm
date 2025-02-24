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

@program
    call @get_input_line

    call @tokennice_line
    
halt


@tokennice_line
    . $token_buffer 64
    . $token_buffer_pntr 1
    . $token_buffer_indx 1
    % $token_buffer_pntr $token_buffer
    % $token_buffer_indx 0

    sto Z $input_buffer_indx  

    :tokennice
        call @read_char
        jmpt :end_tokens

        call @is_char

    jmp :tokennice


    :end_tokens
        inc I $token_buffer_indx
        stx Z $token_buffer_pntr
        inc I $token_buffer_indx
        stx Z $token_buffer_pntr
ret
    



## INCLUDE helpers

INCLUDE read_char
INCLUDE get_input_line
INCLUDE check_char_type
INCLUDE errors
INCLUDE printing


