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
        sto M $exit_hash

    # keyword run 
        ldi K $run_kw
        ldi L @run_kw
        
        call :init_keyword
        sto M $exit_hash
        
    # next keyword
ret