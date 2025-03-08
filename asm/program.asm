. $mem_start 1
% $mem_start 0

call @init_stern
call @init_keywords

@program
    call @get_input_line
    call @tokennice_input_buffer
    call @parse_tokens
    jmp @program
halt




## INCLUDE helpers


INCLUDE read_char
INCLUDE get_input_line
INCLUDE tokennice_input_buffer
INCLUDE check_char_type
INCLUDE get_number_token
INCLUDE get_operator_token
INCLUDE get_string_token
INCLUDE parse_tokens
INCLUDE keyword_handling
INCLUDE printing
INCLUDE math
INCLUDE keyword_calls
INCLUDE errors



