. $string 4
. $stringpointer 1
. $stringindex 1

call @init_stern
call @init_kernel

% $string 0 1
% $stringpointer $string
% $stringindex 0

inc I $stringindex
ldi K 0
xorx K $stringpointer
nop
inc I $stringindex
xorx K $stringpointer
nop


halt
