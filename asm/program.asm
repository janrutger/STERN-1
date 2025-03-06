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

@program
    call @get_input_line
    call @tokennice_line
    call @parse_tokens
    jmp @program
halt



# start of keyword routines 
    . $keyword_indx 1
    % $keyword_indx 0

    . $keyword_list_len 1
    % $keyword_list_len 0

    . $keyword_list 10
    . $keyword_list_pntr 1
    % $keyword_list_pntr $keyword_list

    . $keyword_call_dict 10
    . $keyword_call_dict_pntr 1    
    % $keyword_call_dict_pntr $keyword_call_dict


    # define keywords
    . $exit_kw 5
    % $exit_kw \e \x \i \t \null

    . $print_kw 6
    % $print_kw \p \r \i \n \t \null

@init_keywords
    # update list and dictonary
    # update len
    # first keyword
        # keyword exit
        ldi K $exit_kw
        ldi L @exit_kw

        inc I $keyword_indx
        stx K $keyword_list_pntr
        stx L $keyword_call_dict_pntr

        inc I $keyword_list_len

    # next keyword
        # keyword print 
        ldi K $print_kw
        ldi L @print_kw

        inc I $keyword_indx
        stx K $keyword_list_pntr
        stx L $keyword_call_dict_pntr

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


# Find keyword starts here
. $search_indx 1
. $keyword_value_pntr 1
@find_keyword 
    # need $keyword_list_pntr for known keywords
    # need $token_last_string_value_pntr keyword to look for
    # returns index of keyword in A
    # returns status = 0 if not found
    # returns status = 1 if found

    
    sto Z $keyword_indx
    

    :search_loop
        # Get the adres of keyword
        inc I $keyword_indx
        ld C I 
        ldx A $keyword_list_pntr
        sto A $keyword_value_pntr

        sto Z $search_indx
        :compare_loop
            inc I $search_indx
            ldx A $keyword_value_pntr
            ldx B $token_last_string_value_pntr

            tste A B 
            jmpf :keyword_not_equal
            tst A \null
            jmpt :keyword_found
            jmp :compare_loop

        :keyword_not_equal 
            # check for last keyword
            # its just a string
            ;ldm K $keyword_indx
            ldm L $keyword_list_len
            ;tste K L
            tste L C  
            jmpt :keyword_not_found
            jmp :search_loop

    :keyword_found
        ld A C
        tste A A 
        jmp :end_find_keyword


    :keyword_not_found
        # must return status = 0 when not found
        # returns A = 0 as default
        ldi A 0
        ldi B \2
        tst A 1

:end_find_keyword
nop
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



