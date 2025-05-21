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
    call @pop_A
    call @pop_B
    add A B
    call @push_A
ret

@minus
    call @pop_A
    call @pop_B
    sub A B
    call @push_A
ret

@multiply
    call @pop_A
    call @pop_B
    mul A B
    call @push_A
ret

@divide
    call @pop_A
    call @pop_B
    div A B
    call @push_A
ret

#################################




