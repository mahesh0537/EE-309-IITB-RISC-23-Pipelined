lli r1, 0b100
lli r2, 0b1001
sw r1, r2, 0b0010
lw r4, r3, 0b1011   ; reading from the address we previously wrote to
adi r4, r4, 0b001   ; immediate dependancy, there should be a bubble inserted

; r1 = 0b0100
; r2 = 0b1001
; r3 = 0b0000
; r4 = 0b1100