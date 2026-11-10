.include "m328Pdef.inc"

ldi r16, high(RAMEND)
out SPH, r16
ldi r17, low(RAMEND)
out SPL, r17

; PB0..PB4 as outputs (PB5 = LED0 excluded)
ldi r16, 0b011111
out DDRB, r16

led_on:
    ldi r16, 0xFF
    out PORTB, r16
    call delay
    ldi r16, 0x00
    out PORTB, r16
    call delay
    rjmp led_on

delay:
    push r16
    push r17
    push r18

    ldi r16, 80
d1:
    ldi r17, 255
d2:
    ldi r18, 255
d3:
    dec r18
    brne d3
    dec r17
    brne d2
    dec r16
    brne d1

    pop r18
    pop r17
    pop r16
    ret
