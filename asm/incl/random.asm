# --- Pseudo-Random Number Generator (LCG) ---
# Inspired by simple generators like ZX81's.
# Formula: seed = (a * seed + c) % m

;. $random_seed 1
. $rand_a 1
. $rand_c 1
. $rand_m 1

# common values
# zx81 = 75, borland c++ = 205 
# 134775813 = glibc
;% $rand_a 75
% $rand_a 134775813

# default = 77, 1 = glibc
;% $rand_c 77
% $rand_c 1
% $rand_m 65536

@random
    ldm A $random_seed
    ldm B $rand_a
    mul A B

    ldm B $rand_c
    add A B
    
    ldm B $rand_m

    dmod A B 
    sto B $random_seed

    # returns a value [0 .. 99]
    ldi A 100
    dmod B A
ret