lli r1, 0b110
lli r2, 0b111
lli r3, 0b1001
sw r1, r4, 0b100    ; store 0b110 into location 0b100
sw r2, r4, 0b110    ; store 0b111 into location 0b110
sw r3, r4, 0b111    ; store 0b1001 into location 0b111

lw r5, r5, 0b100    ; load from location 0b100 to r5 => r5 = 0b110
lw r5, r5, 0b000    ; load from location 0b100 to r5 => r5 = 0b111
lw r5, r5, 0b000    ; load from location 0b111 to r5 => r5 = 0b1001

; r1 = 0b110
; r2 = 0b111
; r3 = 0b1001
; r4 = 0b0000
; r5 = 0b1001