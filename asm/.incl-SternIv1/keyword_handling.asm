# start of keyword routines 
    . $keyword_indx 1
    % $keyword_indx 0

    . $keyword_list_len 1
    % $keyword_list_len 0

    . $keyword_list 24
    . $keyword_list_pntr 1
    % $keyword_list_pntr $keyword_list

    . $keyword_call_dict 24
    . $keyword_call_dict_pntr 1    
    % $keyword_call_dict_pntr $keyword_call_dict




:init_keyword  
    call @calc_kw_hash

    inc I $keyword_indx
    stx K $keyword_list_pntr
    stx L $keyword_call_dict_pntr

    inc I $keyword_list_len
ret

@calc_kw_hash
    # expect point to string in K 
    . $string_to_hash 1
    sto K $string_to_hash
    # returns hash in M 
    ld M Z

    sto Z $search_indx
    :loop_calc_hash
        inc I $search_indx
        ldx A $string_to_hash

        tst A \null
        jmpt :end_hash_calc
            muli M 7
            add M A
        jmp :loop_calc_hash

:end_hash_calc
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
            ldm L $keyword_list_len
            tste L C  
            jmpt :keyword_not_found_return_string
            jmp :search_loop

    :keyword_found
        ld A C
        tste A A 
        jmp :end_find_keyword


    :keyword_not_found_return_string
        # must return status = 0 when not found
        # returns token_last_string_value 
        ldi A $token_last_string_value
        ldi B \2
        tst A 1

:end_find_keyword

ret