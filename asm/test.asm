. $string 4

% $string \a \a \a \null
nop

jmp :test
ldi A 61
andi A 4
:test
halt
