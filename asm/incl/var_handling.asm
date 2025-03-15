. $var_list 32
% $var_list \null \null

. $var_list_pntr 1
. $var_list_index 1

% $var_list_pntr $var_list

@write_var
    # needs $var_list_pntr 
    # expects the var (hash) to look for in C (or new)
    # expects the value on the datastack 
    # adds a new var to the list

    sto Z $var_list_index

    :var_write_loop
        inc I $var_list_index
        ldx M $var_list_pntr

        tst M \null
        jmpt :new_var_write

        tste C M
        jmpt :found_var_write

        # extra inc to skip the value index
        inc I $var_list_index 
    jmp :var_write_loop

    :found_var_write
        call @datastack_pop
        # inc to value index
        inc I $var_list_index
        stx A $var_list_pntr
        jmp :end_write_var


    :new_var_write
        # write new value hash 
        stx C $var_list_pntr

        call @datastack_pop
        # inc to value index
        inc I $var_list_index
        stx A $var_list_pntr

        # Terminate list
        inc I $var_list_index
        stx Z $var_list_pntr

    jmp :end_write_var



:end_write_var
ret