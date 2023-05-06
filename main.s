lli r1, 20  ; finding 20th fib
adi r1, r1, -3

; use r7 as stack pointer
; stack begin at 8
lli r7, 8

; use r6 as counter
lli r6, 0

; use r4 and r3 as fib(n-1) and fib(n-2)

lli r3, 0
lli r4, 1

; use r5 as ptr to array
ada r5, r7, r6

; store the first and second element
sw r3, r5, 0
sw r4, r5, 2

;main_loop:
    ada r5, r7, r6
    lw r3, r5, 0
    lw r4, r5, 2

    ada r4, r4, r3
    sw r4, r5, 4

    adi r6, r6, 2

    blt r6, r1, -6

; load result to r1

adi r1, r1, 3
ada r1, r1, r7
lw r1, r1, 0

; result should be in r1
; 20th fib is 6765 (0b1101001101101)