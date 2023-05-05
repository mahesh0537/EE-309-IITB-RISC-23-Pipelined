lli r4, 4
lli r2, 4
lli r5, 1

adi r1, r1, 1
ndu r3, r2, r1   ; set everything except the last 2 bits to 1
ndu r3, r3, r3  

beq r3, r5, -3  ; this branch is taken every 4th iter, so prediction should always be not taken
blt r4, r1, -4   ; prediction should be taken, except in 1st iter