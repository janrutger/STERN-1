. $cursor_x 1
. $cursor_y 1
% $cursor_x 0
% $cursor_y 0

. $BCDstring 16
. $BCDstring_pntr 1
. $BCDstring_index 1
% $BCDstring_pntr $BCDstring


@prompt_system
    ldi A \-
    call @print_char
    inc X $cursor_x
    ldi A \-
    call @print_char
    inc X $cursor_x
    ldi A \>
    call @print_char
    inc X $cursor_x
ret



@prompt_program
    ldi A \space
    call @print_char
    inc X $cursor_x
    ldi A \space
    call @print_char
    inc X $cursor_x
    ldi A \>
    call @print_char
    inc X $cursor_x
ret

@prompt_stacks
    ldi A \space
    call @print_char
    inc X $cursor_x
    ldi A \space
    call @print_char
    inc X $cursor_x
    ldi A \>
    call @print_char
    inc X $cursor_x
ret

@prompt_stacks_err
    dec Y $cursor_y
    ldi A \<
    call @print_char
    inc X $cursor_x
    ldi A \e
    call @print_char
    inc X $cursor_x
    ldi A \>
    call @print_char
    inc X $cursor_x
ret

@cursor_on
    ldi A \_ 
    call @print_char
ret

@cursor_off
    ldi A \space
    call @print_char
ret

@print_char
# expexts $cursor_x and $cursor_y
# char to print in A 

    ldm X $cursor_x
    ldm Y $cursor_y

    # calc memory position, input_string_index
    ld I Y 
    muli I 64
    add I X

    # print on screen
    stx A $VIDEO_MEM
ret   

@print_nl
    inc Y $cursor_y
    sto Z $cursor_x

    tst Y 31
    jmpf :end
    ; int 4 
    call @_do_scroll_line
     # ldi Y 31
     sto Y $cursor_y
:end
ret

@print_cls
    sto Z $cursor_y
    sto Z $cursor_x

    int 1
ret


@print_to_BCD
    sto Z $BCDstring_index ; Initialize BCD string index/count to 0 (assuming Z holds 0)

    # expects the number value to print in A 
    # + signed numbers is the default M=1
    # Check is A has - sign, M=0
    # Multiply A * -1, to change sign
    ldi K 1 ; K will be our sign flag: 1 for positive, 0 for negative

    tstg Z A ; Is 0 > A? (i.e., is A negative?)
    jmpf :_ptb_positive_or_zero ; If not (A >= 0), jump.
        ; A is negative
        ldi K 0     ; Set sign flag to 0 for negative
        muli A -1   ; Make A positive for BCD conversion

:_ptb_positive_or_zero
    ; Handle the case where A is 0 initially
    tst A 0
    jmpf :_ptb_convert_loop ; If A is not 0, start conversion
        ; A is 0. Store '0' and proceed to sign/print.
        ldi C 0 ; Digit 0
        addi C 20 ; Convert to your ASCII '0'
        ldm I $BCDstring_index ; I = current count (0)
        stx C $BCDstring_pntr ; Store '0' at BCDstring[0]
        inc X $BCDstring_index ; Increment count to 1
        jmp :_ptb_handle_sign ; Skip conversion loop if number was 0

:_ptb_convert_loop
    ; A holds the number, K holds the sign flag (but K is reused here)
    ; C will hold the digit
        ldi C 10
        dmod A C ; A = A / 10 (quotient), C = A % 10 (remainder/digit)

        addi C 20 ; Convert digit in C to your ASCII character
        ldm I $BCDstring_index ; I = current number of digits stored
        stx C $BCDstring_pntr ; Store char at BCDstring[I]
        inc X $BCDstring_index ; Increment count of digits stored

        tst A 0 ; Is the remaining number (quotient in A) zero?
        jmpf :_ptb_convert_loop ; If not zero, loop to get next digit
        
:_ptb_handle_sign
    ; K (sign flag) is 1 if positive, 0 if negative.
    tst K 1 ; Was it positive?
    jmpt :_ptb_print_loop ; If positive, skip adding sign.
        ; Number was negative, add '-' sign
        ldi A \-
        ldm I $BCDstring_index ; I = current count of digits
        stx A $BCDstring_pntr ; Store '-' at BCDstring[I]
        inc X $BCDstring_index ; Increment total character count

    # print in reverse order
:_ptb_print_loop
    ldm K $BCDstring_index  ; K = count of characters currently in BCDstring
    tst K 0                ; If count is 0, nothing left to print
    jmpt :_ptb_done        ; If K == 0 (status=1), jump to done

    dec X $BCDstring_index ; Decrement count for next iteration. X now holds the new count.
                           ; K still holds the original count for this iteration.
    ld I K                 ; I = original count
    subi I 1               ; I = index of char to print (original count - 1)
    ldx A $BCDstring_pntr  ; A = $BCDstring[I] (character to print)

        call @print_char
        inc X $cursor_x
        call @check_nl
        jmp :_ptb_print_loop ; Loop until $BCDstring_index (tracked by K at loop start) becomes 0

:_ptb_done
    ldi A \space
    call @print_char
    inc X $cursor_x
    call @check_nl
ret



@check_nl
    tst X 63
    jmpf :skip
        call @print_nl        
    :skip
ret


@_do_scroll_line
### MOVE memory block n positions
. $screen_start 1   ; Define local static variable for the start of the screen area to modify
. $read_pointer 1   ; Define local static variable for the source address during copy
. $pxls_to_shift 1  ; Define local static variable for the number of pixels to shift
. $shifting 1       ; Define local static variable for the loop counter during shift/fill

ldm M $VIDEO_MEM
sto M $screen_start

# n postions to move
# 1 lines x 64 pixels = 64
addi M 64

# pointer to read adres
sto M $read_pointer

# number of shifts
# total lenght of block - 1 = 63
# pixels to shift
ldm M $VIDEO_SIZE
subi M 63
sto M $pxls_to_shift

ldi I 0
sto I $shifting

:shift_loop1
    inc I $shifting
    ldx M $read_pointer
    stx M $screen_start

    ldm K $shifting
    ldm L $pxls_to_shift
    tste K L 
jmpf :shift_loop1

# fill with \space
ldi K \space
ld M Z
:fill_zero1
    inc I $shifting
    stx K $screen_start

    addi M 1
    # 1 line x 64 pixels = 64
    # tst M 384
    tst M 64
jmpf :fill_zero1   

ret  
