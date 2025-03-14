. $var_list 32
% $var_list \null \null

. $var_list_pntr 1
. $var_list_index 1

% $var_list_pntr $var_list

@write_var
    # needs $var_list_pntr 
    # needs var (hash) to look for in A (or new)
    # expects the value on the datastack 
    # adds a new var to the list, default value=0
    # returns 

    sto Z $var_list_index

    :var_write_loop
        inc I $var_list_index
        ldx M $var_list_pntr

        tst M \null
        jmpt :new_var_write

        tste A M
        jmpt :found_var_write

        # extra inc to skip the value index
        inc I $var_list_index 
    jmp :var_write_loop

    :found_var_write
        nop


    :new_var_write
        nop

:end_write_var
ret