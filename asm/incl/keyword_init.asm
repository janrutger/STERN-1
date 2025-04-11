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
        
    # keyword begin
        ldi K $begin_kw
        ldi L @begin_kw
        
        call :init_keyword
        sto M $begin_hash
   
    # keyword end
        ldi K $end_kw
        ldi L @stub 
        
        call :init_keyword
        sto M $end_hash
    
    # keyword run 
        ldi K $run_kw
        ldi L @run_kw
        
        call :init_keyword
        sto M $run_hash
        
    # keyword as
        ldi K $as_kw
        ldi L @as_kw
        
        call :init_keyword
        sto M $as_hash

    # keyword goto
        ldi K $goto_kw
        ldi L @stub
        
        call :init_keyword
        sto M $goto_hash

    # kewyord label
        ldi K $label_kw
        ldi L @stub
        
        call :init_keyword
        sto M $label_hash

    # keyword open ( 
        ldi K $open_(_kw
        ldi L @stub
        
        call :init_keyword
        sto M $open_(_hash

    # keyword close (
        ldi K $close_(_kw 
        ldi L @stub
        
        call :init_keyword
        sto M $close_(_hash

    # keyword open (file)
        ldi K $open_kw
        ldi L @open_kw
        
        call :init_keyword
        sto M $open_hash

    # keyword load (file)
        ldi K $load_kw
        ldi L @load_kw
        
        call :init_keyword
        sto M $load_hash

  
ret