. $stacks_line_counter 1
% $stacks_line_counter 0

. $stacks_program_mem 128
. $stacks_program_mem_pntr 1
. $stacks_program_mem_indx 1
% $stacks_program_mem_pntr $stacks_program_mem
% $stacks_program_mem_indx 0

@load_kw
    # reset mem index (adres)
    sto Z $stacks_program_mem_indx
    sto Z $stacks_line_counter

    int 7
    call @handle_file_input
    call @tokennice_input_buffer

    call @read_token

    # when no first token in buffer, 
    # the file was not correct
    jmpt :fatal_error_load

    # check for first token = begin
    # if not, its not a valid program
    ldm M $begin_hash
    tste C M 
    jmpf :fatal_error_load


    :load_program_instructions
        call @read_token
        # Must be an next token
        jmpt :read_next_line

        # check for end of program
        ldm M $end_hash
        tste C M 
        jmpt :end_load_kw

        call @store_stacks_line
        
    jmp :load_program_instructions
    
    :read_next_line
        int 7
        call @handle_file_input
        call @tokennice_input_buffer

        # store start line index (adres) as counter
        ldm M $stacks_program_mem_indx
        sto M $stacks_line_counter
        
    jmp :load_program_instructions
        

    :fatal_error_load
        call @fatal_error
        jmp :end_load_kw

:end_load_kw 
    inc I $stacks_program_mem_indx
    stx Z $stacks_program_mem_pntr

    sto Z $stacks_program_mem_indx
ret 

@handle_file_input
    # Reads $disk_read_buffer
    # Prints the input on screen
    # Write value to $input_buffer

    sto Z $disk_read_buffer_indx
    sto Z $input_buffer_indx
    #sto Z $input_buffer_pntr
    
    :read_buffer_loop
        inc I $disk_read_buffer_indx
        ldx A $disk_read_buffer_pntr

        inc I $input_buffer_indx
        stx A $input_buffer_pntr

        tst A \Return
        jmpt :end_file_input
        
        call @print_char
        # increase X position
        inc X $cursor_x
        ldm X $cursor_x
        
        jmp :read_buffer_loop

:end_file_input
    #sto Z $input_buffer_pntr
    sto Z $input_buffer_indx
    call @print_nl
ret

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

            call @store_stacks_line

        jmp :instruction_read
        
:begin_kw_end
    inc I $stacks_program_mem_indx
    stx Z $stacks_program_mem_pntr

    sto Z $stacks_program_mem_indx
ret

@store_stacks_line
    # when label-keyword is used
    ldm M $label_hash
    tste C M 
    jmpf :end_label_hash
        call @execute_label_type 
        ret
    :end_label_hash

    # check for string (var)
    ldi M \2
    tste B M 
    jmpf :end_string
        ldi B \v 
        ld A C
    :end_string

    # when goto-keyword is used
    ldm M $goto_hash
    tste C M 
    jmpf :end_goto_hash 
        ldi B \w 
        ld A C 
    :end_goto_hash

    # conditional execution
    # when open ( is used
    ldm M $open_(_hash
    tste C M 
    jmpf :end_open_(_hash
        ldi B \w 
        ld A C 
    :end_open_(_hash

    # when close ( is used
    ldm M $close_(_hash
    tste C M 
    jmpf :end_close_(_hash
        ldi B \w 
        ld A C 
    :end_close_(_hash

    
    # when as-keyword is used
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
    nop

ret

@execute_label_type
    # expects the next argumnet is a \v type
    call @read_token
    tst B \2 
    jmpt :exec_label
        call @fatal_error
    
    :exec_label        
        ldm A $stacks_line_counter
        call @datastack_push
        call @write_var
ret





@run_kw
    :run_code_loop
        inc I $stacks_program_mem_indx
        ldx B $stacks_program_mem_pntr

        # stop at end of program
        tste B Z  
        jmpt :run_kw_end

        # test/execute for variable type
        tst B \v 
        jmpf :check_word_type
            inc I $stacks_program_mem_indx
            ldx C $stacks_program_mem_pntr
            call @read_var
        jmp :run_code_loop

        # test/execute for word type 
        :check_word_type
        tst B \w
        jmpf :run_token
            inc I $stacks_program_mem_indx
            ldx C $stacks_program_mem_pntr
            call @execute_word_type
        jmp :run_code_loop

        # run execute number and operator tokens
        # expects tokentype in B 
        # expects value in A
        :run_token     
            inc I $stacks_program_mem_indx
            ldx A $stacks_program_mem_pntr
            call @execute_token
        jmp :run_code_loop

:run_kw_end    
    sto Z $stacks_program_mem_indx      
ret


@execute_word_type
    # expects the hash of word to execute
    # in C

    # if it is a as-word type
    ldm M $as_hash
    tste C M 
    jmpf :end_as_word
        # check if the next argumnet is a \string type
        inc I $stacks_program_mem_indx
        ldx B $stacks_program_mem_pntr
        tst B \v 
        jmpt :exec_as
            call @fatal_error

        :exec_as
            inc I $stacks_program_mem_indx
            ldx C $stacks_program_mem_pntr
            call @write_var
    :end_as_word

    # if it is a goto-word type
    ldm M $goto_hash
    tste C M 
    jmpf :end_goto_word
        # check if the next argumnet is a \string type
        inc I $stacks_program_mem_indx
        ldx B $stacks_program_mem_pntr
        tst B \v 
        jmpt :exec_goto
            call @fatal_error

        :exec_goto
            inc I $stacks_program_mem_indx
            ldx C $stacks_program_mem_pntr
            
            call @read_var
            call @datastack_pop
            
            sto A $stacks_program_mem_indx
    :end_goto_word

    # if it is a open ( word type
    ldm M $open_(_hash
    tste C M 
    jmpf :end_open_(
        # check if TOS 0 (0=true)
        # when true, execute 
        # when false, skip to ) 
        call @datastack_pop
        tst A 0
        jmpt :end_open_(
        :close_(_loop
            inc I $stacks_program_mem_indx
            ldx B $stacks_program_mem_pntr
            
            inc I $stacks_program_mem_indx
            ldx C $stacks_program_mem_pntr

            tst B \w
            jmpf :close_(_loop 

            # check if Value is closing (
            ldm M $close_(_hash
            tste C M 
            jmpf :close_(_loop
        ret
    :end_open_(
        

ret





