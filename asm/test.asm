@program

ldi A 0
call @open_channel

ldi A 0
ldi B 42
call @write_channel

ldi A 0
ldi B 84
call @write_channel


#ldi A 0
#call @close_channel

ret

