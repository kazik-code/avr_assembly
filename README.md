# AVR Assembly — Bare-Metal Projects (ATmega328PB)

Low-level AVR assembly implementations for the **ATmega328PB** microcontroller targeting the *ATmega328PB Xplained Mini* evaluation board. The repository demonstrates direct hardware control, register manipulation, multi-byte signed arithmetic, lookup tables, and hardware interrupt handling without external runtime libraries.

---

## Requirements

The build and deployment workflow relies on:
- **`avra`** — Assembler for AVR architecture
- **`avrdude`** — Flash memory programming utility
- **`make`** — Build automation tool

### Toolchain Installation

- **macOS (Homebrew):**
  ```bash
  brew install avra avrdude make
  ```
- **Linux (Debian / Ubuntu):**
  ```bash
  sudo apt update && sudo apt install avra avrdude make
  ```
- **Linux (Arch Linux):**
  ```bash
  sudo pacman -S avra avrdude make
  ```
- **Windows:**
  - The `Makefile` relies on standard Unix shell utilities (`mkdir -p`, `rm -rf`). On Windows, execute commands within **MSYS2**, **Git Bash**, or **WSL2** (WSL2 requires USB forwarding to access the debugger via `usbipd-win`).
  - Alternatively: since `avra` syntax is compatible with the official `avrasm2` assembler, each `main.asm` can be built and flashed directly inside **Microchip Studio** (formerly *Atmel Studio*).

---

## Building and Flashing

All tasks are executed from the repository root via the `Makefile` and function identically on macOS and Linux.

### 1. Build All Modules
Compiles all subprojects in one pass. Output `.hex` binaries are placed in `build/<module_name>/main.hex`:
```bash
make build
```

### 2. Flash a Target Module
To compile and flash a specific module to the target board using the onboard `xplainedmini` programmer, set the `M` variable:
```bash
make flash M=<module_name>
```
**Example:**
```bash
make flash M=03_16bit_hex_counter
```

> **Linux USB Permissions Note:**  
> If `avrdude` reports `Permission denied`, execute with `sudo` (`sudo make flash M=...`) or add a `udev` rule for the Atmel mEDBG programmer (`ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="2145", MODE="0666"` in `/etc/udev/rules.d/99-xplainedmini.rules`) and reload rules via `sudo udevadm control --reload-rules && sudo udevadm trigger`.

### 3. Clean Build Artifacts
Removes the `build/` directory and all generated files:
```bash
make clean
```

### 4. Running in Microchip Studio (Windows)
For standalone GUI development on Windows workstations:
1. Create a new **AVR Assembler Project** for **ATmega328PB** (or **ATmega328P**).
2. Paste the contents of `<module_name>/main.asm` into the project's primary `.asm` file (register definition files are resolved automatically; `.include "m328Pdef.inc"` works out of the box).
3. Build the solution (**F7**) and flash the board via **Ctrl+Alt+F5** (*Start Without Debugging*).

---

## Module Overview

### `01_gpio_blinky`
- **Operation:** Periodically toggles digital outputs PB0–PB4 (LED indicators) in an infinite loop using software delay routines.
- **Key Mechanisms:**
  - Direct I/O direction and port data configuration (`DDRB`, `PORTB`).
  - Stack pointer initialization in I/O memory (`SPH:SPL = RAMEND`).
  - 3-level nested loop timing generation (`dec`, `brne`).
  - Stack frame register preservation (`push`, `pop`) across subroutine calls.

### `02_7seg_hex_lookup`
- **Operation:** Sequentially cycles hexadecimal digits (`0`–`F`) on a single common-anode 7-segment display.
- **Key Mechanisms:**
  - Flash program memory Look-Up Table (LUT) with segment bitmasks (`.cseg`, `.DB` directive).
  - Indirect program memory addressing via the 16-bit `Z` register (`ZH:ZL`) with auto-post-increment (`lpm r16, Z+`).
  - Active-low segment driving logic (`PORTD` sinks segment cathodes, `PB0` switches the common anode).

### `03_16bit_hex_counter`
- **Operation:** 16-bit hex counter continuously incrementing from `0x0000` to `0xFFFF`, rendered in real time across a 4-digit 7-segment display.
- **Key Mechanisms:**
  - Time-division multiplexing: cyclic digit strobe selection on `PB0`–`PB3` synchronized with cathode segment output on `PORTD`.
  - Multi-byte arithmetic: 16-bit register pair increment with carry propagation (`add`, `adc`).
  - Bit extraction: isolating upper and lower nibbles using bitwise masking (`andi 0x0F`) and nibble swap (`swap`).
  - Segment pattern mapping via program Flash LUT (`lpm`).

### `04_16bit_signed_sub`
- **Operation:** 16-bit signed two's complement subtraction. Renders the absolute value on a 4-digit display while signaling negative sign (PB5) and arithmetic overflow (PB4) via LEDs.
- **Key Mechanisms:**
  - Multi-byte subtraction with borrow (`sub`, `sbc`).
  - CPU status register (`SREG`) flag evaluation:
    - Two's complement overflow detection via the `V` flag (`brvc`).
    - True mathematical sign evaluation via the signed flag $S = N \oplus V$ (`brlt`).
  - Absolute value conversion for negative results using two's complement negation (bitwise inversion `com` and increment with carry `adc`).

### `05_temp_converter_f2c`
- **Operation:** Fahrenheit to Celsius conversion following $C = \frac{5}{9}(F - 32)$ for 16-bit signed values. Displays the absolute value in decimal (BCD) on a 4-digit 7-segment display with sign (PB5) and overflow (PB4) indicators.
- **Key Mechanisms:**
  - 16-bit signed immediate arithmetic (`subi`, `sbci`).
  - Shift-and-add multiplication: computing $x \times 5 = (x \ll 2) + x$ using arithmetic shifts (`lsl`, `rol`).
  - 16-bit restoring division algorithm implemented for architectures lacking a hardware division unit.
  - Binary-to-BCD conversion via successive subtraction of base-10 powers (1000, 100, 10, 1).

### `06_ext_interrupt_int0`
- **Operation:** Asynchronously toggles the onboard LED0 (PB5) on an external falling-edge hardware trigger on pin INT0 (PD2).
- **Key Mechanisms:**
  - External interrupt controller configuration: interrupt unmasking in `EIMSK` and falling-edge sense control in `EICRA` (`ISC01=1, ISC00=0`).
  - Internal pull-up resistor activation on input pin `PD2`.
  - Dedicated interrupt vector table entry (`INT0addr`) returning via `reti`.
  - Atomic interrupt service routine (ISR) context preservation: backing up working registers and `SREG` on the stack.
  - Port output state inversion using bitwise XOR (`eor`).

### `07_matrix_keypad_pcint`
- **Operation:** Scans a 2×4 matrix keypad connected to Port C, detects keypresses via Pin Change Interrupts (PCINT), and outputs the decoded key index onto LEDs (PB0–PB5).
- **Key Mechanisms:**
  - Pin Change Interrupt system: pin masking on `PC4`–`PC5` via `PCMSK1` (`PCINT12`, `PCINT13`) and controller group enablement in `PCICR` (`PCIE1`).
  - Two-phase matrix scanning architecture:
    1. Idle mode: columns (PC0–PC3) driven low, rows (PC4–PC5) configured as pull-up inputs to trigger the interrupt.
    2. Active ISR mode: temporary interrupt mask disabling (debounce protection) followed by sequential column driving and row sampling.
  - Context save and restore (`SREG`, working registers) inside the ISR.
