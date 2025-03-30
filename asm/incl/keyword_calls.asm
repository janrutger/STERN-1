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


@as_kw
    # expects next token is a string
    call @read_token
    jmpt :as_kw_error
    tst B \2
    jmpf :as_kw_error

    call @write_var
    jmp :as_kw_end

:as_kw_error
    call @fatal_error

:as_kw_end    
ret

@open_kw
    # expect next token is a string (filename)
    call @read_token
    jmpt :open_kw_error
    tst B \2
    jmpf :open_kw_error

    ld A C
    int 6
    jmp :open_kw_end
    
:open_kw_error
    call @fatal_error
    
:open_kw_end
ret



@load_kw_block_from_file
    # returns one block = one line
    # returns block in $block_from_file
    
    

ret



@stub
    # stub
ret


