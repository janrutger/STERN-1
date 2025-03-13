@exit_kw
    int 2
    halt
ret

@print_kw
    call @datastack_pop
    call @print_to_BCD
ret


@main_kw
    ;call @print_cls
    ldm I $prog_start
    callx $mem_start 
ret



. $stacks_line_counter 1
% $stacks_line_counter 0

. $stacks_program_mem 32
. $stacks_program_mem_pntr 1
. $stacks_program_mem_indx 1
% $stacks_program_mem_pntr $stacks_program_mem
% $stacks_program_mem_indx 0


@begin_kw
    # reset mem index (adres)
    sto Z $stacks_program_mem_indx

    :inst_readline
        call @prompt_program
        call @get_input_line
        call @tokennice_input_buffer

        :inst_read
            call @read_token
            jmpt :inst_readline

            ldm M $end_hash
            tste C M 
            jmpt :begin_kw_end

            # Create label comes here
            # then inc line counter 
            inc I $stacks_line_counter

            # keep track of the mem index (adres)
            inc I $stacks_program_mem_indx
            stx B $stacks_program_mem_pntr

            inc I $stacks_program_mem_indx
            stx A $stacks_program_mem_pntr

        jmp :inst_read
        
:begin_kw_end
    inc I $stacks_program_mem_indx
    stx Z $stacks_program_mem_pntr

    sto Z $stacks_program_mem_indx
ret



@run_kw
    
    :run_code_loop
        inc I $stacks_program_mem_indx
        ldx B $stacks_program_mem_pntr

        tste Z B 
        jmpt :run_kw_end

        inc I $stacks_program_mem_indx
        ldx A $stacks_program_mem_pntr

        call @execute_token
    jmp :run_code_loop



:run_kw_end    
    sto Z $stacks_program_mem_indx        
ret

@stub
    # stub
ret


@end_kw
    # stub
ret

