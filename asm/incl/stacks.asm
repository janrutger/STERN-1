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
    sto Z $stacks_line_counter

    :inst_readline
        call @prompt_program
        call @get_input_line
        call @tokennice_input_buffer

        # store start line index (adres) as counter
        ldm M $stacks_program_mem_indx
        sto M $stacks_line_counter


        :instruction_read
            call @read_token
            jmpt :inst_readline

            ldm M $end_hash
            tste C M 
            jmpt :begin_kw_end

            # if as-keyword is used
            ldm M $as_hash
            tste C M 
            jmpf :end_as_hash
                ldi B \4
                ld A C
            :end_as_hash

            # keep track of the mem index (adres)
            inc I $stacks_program_mem_indx
            stx B $stacks_program_mem_pntr

            inc I $stacks_program_mem_indx
            stx A $stacks_program_mem_pntr

        jmp :instruction_read
        
:begin_kw_end
    inc I $stacks_program_mem_indx
    stx Z $stacks_program_mem_pntr

    sto Z $stacks_program_mem_indx
ret



@run_kw
    :run_code_loop
        inc I $stacks_program_mem_indx
        ldx B $stacks_program_mem_pntr

        # stop at end of program
        tste Z B 
        jmpt :run_kw_end

        # load A 
        inc I $stacks_program_mem_indx
        ldx A $stacks_program_mem_pntr

        # execute token
        # Needs tokentype in B 
        # expects value in A
        call @execute_token

    jmp :run_code_loop
:run_kw_end    
    sto Z $stacks_program_mem_indx        
ret


