. $VertexAX 1
. $VertexAY 1
. $VertexBX 1
. $VertexBY 1
. $VertexCX 1
. $VertexCY 1
. $VertexDX 1
. $VertexDY 1

. $CurrentPX 1
. $CurrentPY 1

. $TargetVX 1
. $TargetVY 1

. $Iterations 1
. $PreviousVertexIndex 1 
; Store the index of the last chosen vertex


% $VertexAX 10
% $VertexAY 10

% $VertexBX 630
% $VertexBY 10

% $VertexCX 320
% $VertexCY 470

% $VertexDX 630
% $VertexDY 470

% $CurrentPX 10
% $CurrentPY 10

% $PreviousVertexIndex 4 
; Initialize to a value that won't match (0-3)


EQU ~Max_iterations 5000
;% $Iterations 500


ldi A 1
call @open_channel

ldi M ~Max_iterations
sto M $Iterations

:LoopStart
    ldm C $Iterations
    tste C Z
    jmpt :EndOfProgram
    subi C 1
    sto C $Iterations
    ld A C
    call @print_to_BCD

    ; Calculate next_vertex using: ( (rand() % 3) + 1 + previous_vertex ) % 4
    call @random
    ldi B 3      

    dmod A B     

    ld A B       
    addi A 1     

    ldm B $PreviousVertexIndex 
    add A B      

    ldi B 4      
    dmod A B     

    ld A B       
    ; A = next_vertex 

    ; Store the newly calculated index as the 'previous' for the *next* iteration
    sto A $PreviousVertexIndex

    tste A Z     
    ; Now proceed with selecting the vertex based on A
    jmpt :SelectVertexA
    subi A 1
    tste A Z
    jmpt :SelectVertexB
    subi A 1     
    ; Check if it's C (original value 2)
    tste A Z
    jmpt :SelectVertexC
    jmp :SelectVertexD 
    ; Otherwise it must be D (original value 3)

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

:SelectVertexD
    ldm A $VertexDX
    sto A $TargetVX
    ldm A $VertexDY
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