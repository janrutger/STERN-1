# STACKS Runtime library
#
# Implements an "Empty Ascending Stack" using $datastack_pntr and $datastack_index
# from ./incl/math.asm.
# - $datastack_pntr: Base address of the stack memory area.
# - $datastack_index: A memory variable storing the index of the NEXT FREE SLOT.
#                     Initialized to 0. Stack grows upwards.
#
# Assumed behavior of specific STERN-1 instructions:
# inc I <addr>:
#   1. I = M[addr] (Register I gets current value from memory)
#   2. M[addr] = M[addr] + 1 (Value in memory is incremented)
#
# dec I <addr>:
#   1. I = M[addr] (Register I gets current value from memory)
#   2. I = I - 1   (Register I is decremented)
#   3. M[addr] = I (Decremented value from I is stored back to memory)



#################################
@stacks_runtime_init
    # when the lib must be initalized
ret

#################################
@push_A
    inc I $datastack_index
    stx A $datastack_pntr
ret


@pop_A
    dec I $datastack_index
    ldx A $datastack_pntr
ret

@pop_B
    dec I $datastack_index
    ldx B $datastack_pntr
ret



#################################
@plus
    call @pop_B
    call @pop_A
    add A B
    call @push_A
ret

@minus
    call @pop_B
    call @pop_A
    sub A B
    call @push_A
ret

@multiply
    call @pop_B
    call @pop_A
    mul A B
    call @push_A
ret

@divide
    call @pop_B
    call @pop_A
    div A B
    call @push_A
ret

#################################
@print
    call @pop_A
    call @print_to_BCD
ret



#################################
@eq
    call @pop_B
    call @pop_A
    tste A B
    call @set_true_false
ret

@ne
    call @pop_B
    call @pop_A
    tste A B
    jmpf :ne_false
        ldi A 1
        call @push_A
    jmp :ne_end
    :ne_false
        ldi A 0
        call @push_A
:ne_end
ret


@gt 
    call @pop_B
    call @pop_A
    tstg A B
    call @set_true_false
ret

@lt
    call @pop_A
    call @pop_B
    tstg A B
    call @set_true_false
ret

@set_true_false
    # Helper for comparison ops, assumes comparison instruction just ran.
    # Pushes 0 onto the stack if the preceding comparison was TRUE.
    # Pushes 1 (non-zero) onto the stack if the preceding comparison was FALSE.
    jmpf :set_false
        ldi A 0
        call @push_A
    jmp :set_end
    :set_false
        ldi A 1
        call @push_A
:set_end    
ret

#################################
