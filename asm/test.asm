@program

ldi A 0
call @open_channel

nop

ldi A 0
ldi B 42
call @write_channel

#nop

ldi A 0
ldi B 84
call @write_channel

nop

ldi A 0
#call @close_channel

ret

