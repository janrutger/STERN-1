@init_keywords
    # update list and dictonary
    # update len
    # first keyword

    # keyword exit
        ldi K $exit_kw
        ldi L @exit_kw

        call :init_keyword
        sto M $exit_hash

    # keyword print 
        ldi K $print_kw
        ldi L @print_kw

        call :init_keyword
        sto M $print_hash

     # keyword main
        ldi K $main_kw
        ldi L @main_kw
        
        call :init_keyword
        sto M $main_hash
    
    # keyword run 
        ldi K $run_kw
        ldi L @run_kw
        
        call :init_keyword
        sto M $run_hash

    # keyword stacks
        ldi K $stacks_kw
        ldi L @stacks_kw
        
        call :init_keyword
        sto M $stacks_hash
        
    # keyword begin
        ldi K $begin_kw
        ldi L @begin_kw
        
        call :init_keyword
        sto M $begin_hash
   
    # keyword end
        ldi K $end_kw
        ldi L @end_kw
        
        call :init_keyword
        sto M $end_hash
        
    # keyword quit
        ldi K $quit_kw
        ldi L @quit_kw
        
        call :init_keyword
        sto M $quit_hash
        
    # next keyword
ret