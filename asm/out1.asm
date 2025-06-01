@main
call @stacks_runtime_init
. $result 1
ldi A 0
call @push_A
call @stacks_timer_set
; --- String Literal '1234567890abcdef gh i j k l m n o p q r s t u v w x y z' pushed to stack ---
ldi A 0
call @push_A
ldi A \z
call @push_A
ldi A \space
call @push_A
ldi A \y
call @push_A
ldi A \space
call @push_A
ldi A \x
call @push_A
ldi A \space
call @push_A
ldi A \w
call @push_A
ldi A \space
call @push_A
ldi A \v
call @push_A
ldi A \space
call @push_A
ldi A \u
call @push_A
ldi A \space
call @push_A
ldi A \t
call @push_A
ldi A \space
call @push_A
ldi A \s
call @push_A
ldi A \space
call @push_A
ldi A \r
call @push_A
ldi A \space
call @push_A
ldi A \q
call @push_A
ldi A \space
call @push_A
ldi A \p
call @push_A
ldi A \space
call @push_A
ldi A \o
call @push_A
ldi A \space
call @push_A
ldi A \n
call @push_A
ldi A \space
call @push_A
ldi A \m
call @push_A
ldi A \space
call @push_A
ldi A \l
call @push_A
ldi A \space
call @push_A
ldi A \k
call @push_A
ldi A \space
call @push_A
ldi A \j
call @push_A
ldi A \space
call @push_A
ldi A \i
call @push_A
ldi A \space
call @push_A
ldi A \h
call @push_A
ldi A \g
call @push_A
ldi A \space
call @push_A
ldi A \f
call @push_A
ldi A \e
call @push_A
ldi A \d
call @push_A
ldi A \c
call @push_A
ldi A \b
call @push_A
ldi A \a
call @push_A
ldi A \0
call @push_A
ldi A \9
call @push_A
ldi A \8
call @push_A
ldi A \7
call @push_A
ldi A \6
call @push_A
ldi A \5
call @push_A
ldi A \4
call @push_A
ldi A \3
call @push_A
ldi A \2
call @push_A
ldi A \1
call @push_A
; --- End String Literal '1234567890abcdef gh i j k l m n o p q r s t u v w x y z' on stack ---
call @~sndString
ldi A 0
call @push_A
call @stacks_timer_print
ldi A 1
call @push_A
call @pop_A
sto A $result
:_4_while_condition
ldm A $result
call @push_A
ldi A 0
call @push_A
call @ne
call @pop_A
tste A Z
jmpf :_4_while_end
call @~rcv
jmp :_4_while_condition
:_4_while_end
ldi A 0
call @push_A
call @stacks_timer_print
ret
INCLUDE  stacks_runtime
@~conn_echo_write_0
  call @pop_B
  ldi A 0
  ldi C 1
  call @stacks_network_write
  ret
@~conn_echo2_write_1
  call @pop_B
  ldi A 0
  ldi C 1
  call @stacks_network_write
  ret
@~sndString
:_2_while_condition
call @dup
ldi A 0
call @push_A
call @ne
call @pop_A
tste A Z
jmpf :_2_while_end
call @~conn_echo_write_0
jmp :_2_while_condition
:_2_while_end
call @~conn_echo2_write_1
ret
@~rcv
:_3_while_condition
call @readService0
ldi A 1
call @push_A
call @eq
call @pop_A
tste A Z
jmpf :_3_while_end
jmp :_3_while_condition
:_3_while_end
call @dup
call @pop_A
sto A $result
call @print
ret
