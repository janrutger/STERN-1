. $VertexAX 1
. $VertexAY 1
. $VertexBX 1
. $VertexBY 1
. $VertexCX 1
. $VertexCY 1

. $CurrentPX 1
. $CurrentPY 1

. $TargetVX 1
. $TargetVY 1

. $Iterations 1

. $TempA 1
. $TempB 1

% $VertexAX 10
% $VertexAY 10

% $VertexBX 630
% $VertexBY 10

% $VertexCX 320
% $VertexCY 470

% $CurrentPX 10
% $CurrentPY 10

% $Iterations 500


ldi A 1
call @open_channel

ldi M 500
sto M $Iterations

:LoopStart
    ldm C $Iterations
    tste C Z
    jmpt :EndOfProgram
    subi C 1
    sto C $Iterations
    ld A C
    call @print_to_BCD

    call @random
    ldi B 3
    dmod A B 
    ld A B 

    tste A Z
    jmpt :SelectVertexA
    subi A 1
    tste A Z
    jmpt :SelectVertexB
    jmp :SelectVertexC

:SelectVertexA
    ldm A $VertexAX
    sto A $TargetVX
    ldm A $VertexAY
    sto A $TargetVY
    jmp :VertexSelected

:SelectVertexB
    ldm A $VertexBX
    sto A $TargetVX
    ldm A $VertexBY
    sto A $TargetVY
    jmp :VertexSelected

:SelectVertexC
    ldm A $VertexCX
    sto A $TargetVX
    ldm A $VertexCY
    sto A $TargetVY
    jmp :VertexSelected

:VertexSelected
    ldm A $CurrentPX
    ldm B $TargetVX
    add A B 
    divi A 2
    sto A $CurrentPX

    ldm A $CurrentPY
    ldm B $TargetVY
    add A B 
    divi A 2
    sto A $CurrentPY

    ldi A 1
    ldm B $CurrentPX
    call @write_channel

    ldi A 1
    ldm B $CurrentPY
    call @write_channel

    jmp :LoopStart



:EndOfProgram

ret