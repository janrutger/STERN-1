@program


ldi A 1 
call @open_channel

ldi B 200
call @write_channel
ldi B 200
call @write_channel

ldi B 200
call @write_channel
ldi B 201
call @write_channel

ldi B 200
call @write_channel
ldi B 202
call @write_channel

ldi B 200
call @write_channel
ldi B 203
call @write_channel


ret

