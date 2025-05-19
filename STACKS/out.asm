@main
settimer 0
speed 0
push 10
push 12
call @plus
prt
push 12
storem $a
push 10
storem $b
loadm $a
loadm $b
call @plus
prt
prttimer 0
ret
