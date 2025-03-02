call @init_stern

. $mem_start 1
% $mem_start 0

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

. $datastack 16
. $datastack_pntr 1
. $datastack_index 1
% $datastack_pntr $datastack
% $datastack_index 0

@program
    call @get_input_line
    call @tokennice_line
    call @parse_tokens
    jmp @program
halt





## INCLUDE helpers


INCLUDE read_char
INCLUDE get_input_line
INCLUDE tokennice_line
INCLUDE check_char_type
INCLUDE get_number_token
INCLUDE get_operator_token
INCLUDE get_string_token
INCLUDE parse_tokens
INCLUDE printing
INCLUDE math
INCLUDE errors



