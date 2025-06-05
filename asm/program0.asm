@main
call @stacks_runtime_init
. $previous 1
. $next 1
. $cfactor 1
. $r 1
ldi A 0
call @push_A
call @stacks_timer_set
ldi A 1
call @push_A
call @~conn_plotter_write_0
ldi A 1
call @push_A
call @~conn_plotter_write_0
ldi A 1
call @push_A
call @pop_A
sto A $previous
ldi A 2
call @push_A
call @pop_A
sto A $next
:_2_while_condition
ldm A $next
call @push_A
ldi A 700
call @push_A
call @ne
call @pop_A
tste A Z
jmpf :_2_while_end
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
jmpf :_3_do_end
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
:_3_do_end
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
call @~conn_plotter_write_0
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
call @~pauze
jmp :_2_while_condition
:_2_while_end
ldi A 0
call @push_A
call @stacks_timer_print
ret
INCLUDE  stacks_runtime
@~conn_plotter_write_0
  call @pop_B
  ldi A 1
  ldi C 0
  call @stacks_network_write
  ret
@~pauze
ldm A $next
call @push_A
ldi A 10
call @push_A
call @mod
ldi A 0
call @push_A
call @eq
call @pop_A
tste A Z
jmpf :_1_do_end
ldi A 50
call @push_A
call @stacks_sleep
:_1_do_end
ret
