. $stacks_line_counter 1
% $stacks_line_counter 0

. $stacks_program_mem 32
. $stacks_program_mem_pntr 1
. $stacks_program_mem_indx 1
% $stacks_program_mem_pntr $stacks_program_mem
% $stacks_program_mem_indx 0



@stacks
    :stacks_loop
        call @prompt_command
        call @read_stacks_line

        ;sto Z $token_buffer_indx
        :read_loop
            call @read_token
            jmpt :stacks_loop
            
            ldm M $begin_hash
            tste C M
            jmpt :execute_command

            ldm M $quit_hash
            tste C M 
            jmp :end_stacks

        jmp :read_loop

        :execute_command
            ld I A 
            ldx A $keyword_call_dict_pntr
            ld I A 
            callx $mem_start
        jmp :read_loop
        
    ;jmp :stacks_loop
:end_stacks 
ret






@read_stacks_line
    call @get_input_line
    call @tokennice_input_buffer
ret