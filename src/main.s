; you can add comments and leave empty lines

lli r1, 0b00100     ; load r1 with 0b00100
lli r2, 0b11011     ; load r2 with 0b11011
lli r3, 0b00010     ; load r3 with 0b00010
ada r3, r3, r3      ; add r3 to itself
beq r1, r3, 2       ; check if r1, r3 are equal and branch accordingly
adi r1, r1, 0b01    ; since r1 == r3, this inst is skipped
adi r2, r2, 0b100   ; this is the branch target, and will be executed

; after execution, the registers will be:
; r1 = 0b100
; r2 = 0b11111
; r3 = 0b100