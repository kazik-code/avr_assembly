.include "m328Pdef.inc"
; Fahrenheit to Celsius converter: C = 5/9 * (F - 32)
; 16-bit signed arithmetic, shift-add multiplication, restoring division,
; BCD conversion, sign LED (PB5), and overflow LED (PB4).

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
    ldi r20, low(14)
    ldi r21, high(14)

main:
    rcall fahrenheit_to_celsius
    rcall to_dec4
display_loop:
    rcall display
    rjmp display_loop

fahrenheit_to_celsius:
    clr r31 ; bit 0 = overflow flag

    ; x = F - 32
    subi r20, low(32)
    sbci r21, high(32)
    brvc ftc_sub_ok
    ori r31, 0x01
ftc_sub_ok:

    ; x * 5 = (x << 2) + x
    mov r24, r20
    mov r25, r21
    mov r18, r20
    mov r19, r21

    lsl r18
    rol r19
    brvc ftc_mul_s1_ok
    ori r31, 0x01
ftc_mul_s1_ok:
    lsl r18
    rol r19
    brvc ftc_mul_s2_ok
    ori r31, 0x01
ftc_mul_s2_ok:

    add r18, r24
    adc r19, r25
    brvc ftc_mul_add_ok
    ori r31, 0x01
ftc_mul_add_ok:

    mov r20, r18
    mov r21, r19

    rcall div16s_by9

    ; output sign on PB5 and convert to absolute value for display
    sbrc r21, 7
    rjmp ftc_negative
ftc_positive:
    cbi PORTB, 5
    rjmp ftc_overflow_led

ftc_negative:
    sbi PORTB, 5
    com r21
    com r20
    ldi r16, 1
    add r20, r16
    ldi r16, 0
    adc r21, r16

ftc_overflow_led:
    sbrs r31, 0
    rjmp ftc_no_overflow
    sbi PORTB, 4
    ret
ftc_no_overflow:
    cbi PORTB, 4
    ret

div16s_by9:
    ; Signed 16-bit restoring division by 9 (in/out: r21:r20)
    clr r30 ; bit 0 = input sign

    sbrs r21, 7
    rjmp div_abs_ready
    ori r30, 0x01
    com r21
    com r20
    ldi r16, 1
    add r20, r16
    ldi r16, 0
    adc r21, r16

div_abs_ready:
    clr r22 ; remainder low
    clr r23 ; remainder high
    ldi r17, 16

div_loop:
    lsl r20
    rol r21
    rol r22
    rol r23

    subi r22, 9
    sbci r23, 0
    brcc div_set_qbit

    ; restore remainder
    ldi r16, 9
    add r22, r16
    ldi r16, 0
    adc r23, r16
    rjmp div_next

div_set_qbit:
    ori r20, 0x01

div_next:
    dec r17
    brne div_loop

    sbrs r30, 0
    ret
    com r21
    com r20
    ldi r16, 1
    add r20, r16
    ldi r16, 0
    adc r21, r16
    ret

to_dec4:
    ; In: r21:r20 = unsigned value (0..32767)
    ; Out: r13..r10 = thousands, hundreds, tens, units
    clr r10
    clr r11
    clr r12
    clr r13

dec1000_loop:
    cpi r21, high(1000)
    brlo dec100_loop
    brne dec1000_sub
    cpi r20, low(1000)
    brlo dec100_loop
dec1000_sub:
    subi r20, low(1000)
    sbci r21, high(1000)
    inc r13
    rjmp dec1000_loop

dec100_loop:
    cpi r21, 0
    brne dec100_sub
    cpi r20, 100
    brlo dec10_loop
dec100_sub:
    subi r20, 100
    sbci r21, 0
    inc r12
    rjmp dec100_loop

dec10_loop:
    cpi r21, 0
    brne dec10_sub
    cpi r20, 10
    brlo dec1_done
dec10_sub:
    subi r20, 10
    sbci r21, 0
    inc r11
    rjmp dec10_loop

dec1_done:
    mov r10, r20
    ret

display:
    mov r16, r10
    ldi r17, 0xFE ; digit 0
    out PORTC, r17
    rcall show_digit
    rcall delay

    mov r16, r11
    ldi r17, 0xFD ; digit 1
    out PORTC, r17
    rcall show_digit
    rcall delay

    mov r16, r12
    ldi r17, 0xFB ; digit 2
    out PORTC, r17
    rcall show_digit
    rcall delay

    mov r16, r13
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
