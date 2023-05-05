lli r1, 5
adi r2, 1
blt r2, r1, -1
; prediction should be strongly taken
; in 5th iter, should exit loop but pred will be
; branch taken. pipeline should be flushed
ada r2, r2, r1
; r1 = 0b0101
; r2 = 0b1010
