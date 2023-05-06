lli r1, 5
adi r2, r2, 1
blt r2, r1, -1
lli r5, 10
; first prediction might be incorrect
; but everything after that should be branch taken
; until iteration number 6, where the loop is
; supposed to end
; r1 = 0b101
; r2 = 0b101
