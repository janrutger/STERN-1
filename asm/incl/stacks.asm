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

            # check for end of program
            ldm M $end_hash
            tste C M 
            jmpt :begin_kw_end

            # check for string (var)
            ldi M \2
            tste B M 
            jmpf :end_string
                ldi B \v 
                ld A C
            :end_string
        

            # if as-keyword is used
            ldm M $as_hash
            tste C M 
            jmpf :end_as_hash
                ldi B \w
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
        tste B Z  
        jmpt :run_kw_end

        # test for variable
        tst B \v 
        jmpf :check_word_type
            inc I $stacks_program_mem_indx
            ldx C $stacks_program_mem_pntr
            call @read_var
        jmp :run_code_loop

        # test for word type 
        :check_word_type
        tst B \w
        jmpf :run_token
            inc I $stacks_program_mem_indx
            ldx C $stacks_program_mem_pntr
            call @execute_word_type
        jmp :run_code_loop


        :run_token
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


@execute_word_type
    # expects the hash of word to execute
    # in C

    ldm M $as_hash
    tste C M 
    jmpf :end_as_word
        # check if the next argumnet is a \v type
        inc I $stacks_program_mem_indx
        ldx B $stacks_program_mem_pntr
        tst B \v 
        jmpt :exec_as
            call @fatal_error

        :exec_as
            inc I $stacks_program_mem_indx
            ldx C $stacks_program_mem_pntr
            call @write_var
            nop
    :end_as_word


ret


