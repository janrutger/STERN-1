@program

ldi A 0
call @open_channel

ldi A 3 
call @open_channel

ldi A 0
call @close_channel

ldi A 3
ldi B 42
call @write_channel




ret