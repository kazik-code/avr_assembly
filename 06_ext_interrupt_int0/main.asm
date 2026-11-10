; Toggle onboard LED0 (PB5) on external interrupt INT0 (PD2, falling edge)

.include "m328Pdef.inc"
.org 0
    rjmp main
.org INT0addr
    rjmp portD_isr

main:
    ldi r16, HIGH(RAMEND)
    out SPH, r16
    ldi r16, LOW(RAMEND)
    out SPL, r16

    sbi DDRB, 5  ; PB5 as output (LED0)
    sbi PORTD, 2 ; enable pull-up on PD2 (INT0)

    ldi r20, (1<<INT0)
    out EIMSK, r20

    ldi r20, (1<<ISC01) ; falling edge trigger
    sts EICRA, r20

    sei

stop:
    rjmp stop

portD_isr:
    push r21
    in r21, SREG
    push r21
    push r22

    in r21, PINB
    ldi r22, (1<<5)
    eor r21, r22 ; toggle PB5
    out PORTB, r21

    pop r22
    pop r21
    out SREG, r21
    pop r21
    reti
