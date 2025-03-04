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

call @init_keywords
nop

@program
    call @get_input_line
    call @tokennice_line
    call @parse_tokens
    jmp @program
halt



# start of init keywords 
    . $keyword_indx 1
    % $keyword_indx 0

    . $keyword_list_len 1
    % $keyword_list_len 0

    . $keyword_list 10
    . $keyword_call_dict 10

    # define keywords
    . $exit_kw 5
    % $exit_kw \e \x \i \t \null

    . $print_kw 6
    % $print_kw \p \r \i \n \t \null

@init_keywords
    # update list and dictonary
    # update len
nop
        # keyword exit
        inc I $keyword_indx

        ldi M $exit_kw
        stx M $keyword_list

        ldi M @exit_kw
        stx M $keyword_call_dict

    inc I $keyword_list_len
    # next keyword
        # keyword print 
        inc I $keyword_indx

        ldi M $print_kw
        stx M $keyword_list

        ldi M @print_kw
        stx M $keyword_call_dict

    inc I $keyword_list_len
    # next keyword

ret

@exit_kw
    int 2
    halt
ret

@print_kw
    ;call @printing
ret





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



