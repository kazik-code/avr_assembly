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

    ldi r16, 0xFF
    out DDRD, r16
    ldi r16, 0x0F
    out DDRB, r16
    out PORTB, r16

    clr r26
    clr r27
    ldi r21, 70

main_loop:
    rcall display

    dec r21
    brne main_loop

    ldi r21, 70

    ; 16-bit counter increment (r27:r26)
    ldi r16, 1
    add r26, r16
    ldi r16, 0
    adc r27, r16

    rjmp main_loop

display:
    mov r16, r26
    andi r16, 0x0F
    rcall show_digit
    ldi r17, 0b11111110
    out PORTB, r17
    rcall delay_fast

    mov r16, r26
    swap r16
    andi r16, 0x0F
    rcall show_digit
    ldi r17, 0b11111101
    out PORTB, r17
    rcall delay_fast

    mov r16, r27
    andi r16, 0x0F
    rcall show_digit
    ldi r17, 0b11111011
    out PORTB, r17
    rcall delay_fast

    mov r16, r27
    swap r16
    andi r16, 0x0F
    rcall show_digit
    ldi r17, 0b11110111
    out PORTB, r17
    rcall delay_fast

    ret

show_digit:
    ldi ZL, low(2*hex_digits)
    ldi ZH, high(2*hex_digits)
    add ZL, r16 ; offset Z pointer by digit index
    ldi r16, 0
    adc ZH, r16
    lpm r16, Z
    com r16
    out PORTD, r16
    ret

delay_fast:
    push r18
    push r19
    push r20
    ldi r18, 1
d1:
    ldi r19, 40
d2:
    ldi r20, 40
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
