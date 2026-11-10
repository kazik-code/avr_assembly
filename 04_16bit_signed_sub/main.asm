.include "m328Pdef.inc"
; 16-bit signed subtraction with absolute value on 7-seg display,
; sign indicator on PB5, and two's complement overflow indicator on PB4.

.org 0x00
    rjmp hardware_init

.org 0x100
hex_digits: .DB 0x7E, 0x30, 0x6D, 0x79, 0x33, 0x5B, 0x5F, 0x70, 0x7F, 0x7B, 0x77, 0x1F, 0x4E, 0x3D, 0x4F, 0x47

hardware_init:
    ldi r16, high(ramend)
    out SPH, r16
    ldi r16, low(ramend)
    out SPL, r16

    ldi r16, 0xFF
    out DDRD, r16 ; PORTD = segments
    ldi r16, 0x30 ; PB5 = sign LED, PB4 = overflow LED
    out DDRB, r16
    cbi PORTB, 5
    cbi PORTB, 4
    ldi r16, 0x0F ; PC0..PC3 = digit anodes
    out DDRC, r16

values_init:
    ldi r20, 0xCD
    ldi r21, 0x7A ; r21:r20 (minuend)

    ldi r22, 0xFF
    ldi r23, 0xFF ; r23:r22 (subtrahend)

main:
    rcall subtract
display_loop:
    rcall display
    rjmp display_loop

subtract:
    ; r21:r20 = r21:r20 - r23:r22
    sub r20, r22
    sbc r21, r23
    brvc no_overflow
    sbi PORTB, 4
    rjmp sign_check
no_overflow:
    cbi PORTB, 4
sign_check:
    brlt result_negative ; check signed flag S (N xor V)
    rjmp result_positive

result_negative:
    sbi PORTB, 5
    ; two's complement negation for absolute value
    com r21
    com r20
    ldi r16, 1
    add r20, r16
    ldi r16, 0
    adc r21, r16
    ret

result_positive:
    cbi PORTB, 5
    ret

display:
    mov r16, r20
    andi r16, 0x0F
    ldi r17, 0xFE ; digit 0
    out PORTC, r17
    rcall show_digit
    rcall delay

    mov r16, r20
    swap r16
    andi r16, 0x0F
    ldi r17, 0xFD ; digit 1
    out PORTC, r17
    rcall show_digit
    rcall delay

    mov r16, r21
    andi r16, 0x0F
    ldi r17, 0xFB ; digit 2
    out PORTC, r17
    rcall show_digit
    rcall delay

    mov r16, r21
    swap r16
    andi r16, 0x0F
    ldi r17, 0xF7 ; digit 3
    out PORTC, r17
    rcall show_digit
    rcall delay

    ret

show_digit:
    ldi ZL, low(2*hex_digits)
    ldi ZH, high(2*hex_digits)
    add ZL, r16
    ldi r16, 0
    adc ZH, r16
    lpm r16, Z
    com r16
    out PORTD, r16
    ret

delay:
    push r18
    push r19
    ldi r18, 30
df1:
    ldi r19, 255
df2:
    dec r19
    brne df2
    dec r18
    brne df1
    pop r19
    pop r18
    ret
