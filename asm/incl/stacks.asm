. $stacks_line_counter 1
% $stacks_line_counter 0

. $stacks_program_mem 32
. $stacks_program_mem_pntr 1
. $stacks_program_mem_indx 1
% $stacks_program_mem_pntr $stacks_program_mem
% $stacks_program_mem_indx 0



@stacks
    :stacks_loop
        call @read_stacks_line

        sto Z $token_buffer_indx
        :read_loop
            call @read_token
            jmpt :stacks_loop
            
            ldm M $begin_hash
            tste C M
        jmpf :read_loop
        nop



    jmp :stacks_loop
    
ret



@read_stacks_line
    call @get_input_line
    call @tokennice_input_buffer
ret