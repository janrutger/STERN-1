@main
call @stacks_runtime_init
. $previous 1
. $next 1
. $cfactor 1
. $r 1
ldi A 0
call @push_A
call @sio_channel_on
ldi A 0
call @push_A
call @stacks_timer_set
ldi A 1
call @push_A
call @plot
ldi A 1
call @push_A
call @plot
ldi A 1
call @push_A
call @pop_A
sto A $previous
ldi A 2
call @push_A
call @pop_A
sto A $next
:_0_while_condition
ldm A $next
call @push_A
ldi A 700
call @push_A
call @ne
call @pop_A
tste A Z
jmpf :_0_while_end
ldm A $previous
call @push_A
ldm A $next
call @push_A
call @stacks_gcd
call @pop_A
sto A $cfactor
ldi A 1
call @push_A
ldm A $cfactor
call @push_A
call @eq
call @pop_A
tste A Z
jmpf :_1_do_end
ldm A $previous
call @push_A
ldm A $next
call @push_A
ldi A 1
call @push_A
call @plus
call @plus
call @pop_A
sto A $r
jmp :nextnumber
:_1_do_end
ldm A $previous
call @push_A
ldm A $cfactor
call @push_A
call @divide
call @pop_A
sto A $r
:nextnumber
ldm A $r
call @push_A
call @plot
ldm A $r
call @push_A
call @pop_A
sto A $previous
ldm A $next
call @push_A
ldi A 1
call @push_A
call @plus
call @pop_A
sto A $next
jmp :_0_while_condition
:_0_while_end
ldi A 0
call @push_A
call @stacks_timer_print
ldi A 1
call @push_A
call @stacks_timer_print
ldi A 0
call @push_A
call @stacks_timer_print
ldi A 9
call @push_A
call @stacks_timer_print
ret
INCLUDE  stacks_runtime
