; 2x4 matrix keypad scanner on Port C using Pin Change Interrupt (PCINT1)

.include "m328Pdef.inc"

.cseg
.org 0
    jmp start
.org PCI1addr
    jmp keypad_ISR

start:
    ldi r16, high(RAMEND)
    out SPH, r16
    ldi r16, low(RAMEND)
    out SPL, r16

    ; PB0..PB5 as LED outputs
    ldi r16, 0x3F
    out DDRB, r16

    ; Port C keypad: PC0..PC3 columns (outputs, low), PC4..PC5 rows (inputs, pull-up)
    ldi r20, 0x0F
    out DDRC, r20
    ldi r20, 0x30
    out PORTC, r20

    ; Enable PCINT12 (PC4) and PCINT13 (PC5)
    ldi r20, (1<<PCINT12)|(1<<PCINT13)
    sts PCMSK1, r20

    ldi r20, (1<<PCIE1)
    sts PCICR, r20

    ldi r18, 0x00 ; scanned key code
    sei

loop:
    call led_display
    rjmp loop

keypad_ISR:
    push r16
    in r16, SREG
    push r16
    push r20

    ; Disable Port C pin change interrupts during scan (debounce guard)
    ldi r20, 0
    sts PCMSK1, r20

    ; Step 1: Read columns (rows as low outputs, columns as pull-up inputs)
    ldi r20, 0x30
    out DDRC, r20
    ldi r20, 0x0F
    out PORTC, r20
    nop
    in r16, PINC
    mov r18, r16
    andi r18, 0x0F

    ; Step 2: Read rows (columns as low outputs, rows as pull-up inputs)
    ldi r20, 0x0F
    out DDRC, r20
    ldi r20, 0x30
    out PORTC, r20
    nop
    in r16, PINC
    andi r16, 0x30
    add r18, r16 ; combine row and column code in r18

    ; Step 3: Restore initial pin state and re-enable interrupt
    ldi r20, 0x0F
    out DDRC, r20
    ldi r20, 0x30
    out PORTC, r20
    ldi r20, (1<<PCINT12)|(1<<PCINT13)
    sts PCMSK1, r20

    pop r20
    pop r16
    out SREG, r16
    pop r16
    reti

led_display:
    out PORTB, r18
    ret
