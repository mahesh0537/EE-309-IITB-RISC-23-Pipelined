lli r1, 5
adi r2, 1
blt r2, r1, -1
; first prediction might be incorrect
; but everything after that should be branch taken
; until iteration number 6, where the loop is
; supposed to end