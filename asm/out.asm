@main
call @stacks_runtime_init
ldi A 0
call @push_A
call @sio_channel_on
ldi A 12
call @push_A
call @plot
ldi A 24
call @push_A
call @plot
ret
INCLUDE  stacks_runtime
