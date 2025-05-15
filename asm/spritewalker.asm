# main program is loaded at adres 4608
# is called with rh rub command

@program
        ldi X 25
        ldi Y 16

        . $sprite 4
        % $sprite 1 1 1 1
 
        . $sprite1 64
        % $sprite1 0 1 0 1 1 0 1 0 0 1 0 0 0 0 1 0 1 0 0 0 0 0 0 1 1 0 1 0 0 1 0 1 1 0 0 0 0 0 0 1 1 1 0 1 1 0 1 1 0 1 0 0 0 0 1 0 0 0 1 1 1 1 0 0
        
        
    :loop
        # Draw the char
        ldi A 8
        ldi B 8
        ldi C $sprite1
        int 5

        :read_kbd
            call @KBD_READ
            tst A \null
        jmpt :read_kbd
            ldi M \z
            tstg A M 
        jmpf :read_kbd

        ld K A

        # un-Draw the char
        ldi A 8
        ldi B 8
        ldi C $sprite1
        int 5

        tst K \Up
        jmpf :Right
            # Up
            subi Y 1
        jmp :loop

        :Right
        tst K \Right
        jmpf :Down
            # Right
            addi X 1
        jmp :loop

        :Down
        tst K \Down
        jmpf :Left
            # Down
            addi Y 1
        jmp :loop

        :Left
        tst K \Return
        jmpt :Return
            # Left
            subi X 1
    jmp :loop

:Return  
ret







