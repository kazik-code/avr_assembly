.include "m328Pdef.inc"

.org 0x00
    rjmp init

.org 0x32
hex_digits: .DB 0x7E, 0x30, 0x6D, 0x79, 0x33, 0x5B, 0x5F, 0x70, 0x7F, 0x7B, 0x77, 0x1F, 0x4E, 0x3D, 0x4F, 0x47

.org 0x100
init:
    ldi r16, high(ramend)
    out SPH, r16
    ldi r16, low(ramend)
    out SPL, r16

    ; PORTD = segments, PB0 = digit anode
    ldi r16, 0xFF
    out DDRD, r16
    ldi r16, 0b0001
    out DDRB, r16
    com r16
    out PORTB, r16

operation_reset:
    ldi r17, 16
    ldi zl, low(2*hex_digits)
    ldi zh, high(2*hex_digits)

prog_start:
    lpm r16, z+
    com r16
    out PORTD, r16
    call delay
    dec r17
    breq operation_reset
    rjmp prog_start

delay:
    push r18
    push r19
    push r20
    ldi r18, 41
d1:
    ldi r19, 255
d2:
    ldi r20, 255
d3:
    dec r20
    brne d3
    dec r19
    brne d2
    dec r18
    brne d1

    pop r20
    pop r19
    pop r18
    ret
