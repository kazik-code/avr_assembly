MCU_FLASH  = m328pb
PROGRAMMER = xplainedmini

INC_DIR    = include
BUILD_DIR  = build

AVRA       = avra
AVRDUDE    = avrdude

MODULES    = 01_gpio_blinky \
             02_7seg_hex_lookup \
             03_16bit_hex_counter \
             04_16bit_signed_sub \
             05_temp_converter_f2c \
             06_ext_interrupt_int0 \
             07_matrix_keypad_pcint

HEX_TARGETS = $(patsubst %,$(BUILD_DIR)/%/main.hex,$(MODULES))

.PHONY: all build flash clean

all: build

build: $(HEX_TARGETS)

$(BUILD_DIR)/%/main.hex: %/main.asm
	@mkdir -p $(dir $@)
	$(AVRA) -I $(INC_DIR) -o $@ -d $(dir $@)main.obj -e $(dir $@)main.eep.hex $<

flash:
ifndef M
	$(error Usage: make flash M=<module_name>, e.g. make flash M=03_16bit_hex_counter)
endif
	@$(MAKE) $(BUILD_DIR)/$(M)/main.hex
	$(AVRDUDE) -c $(PROGRAMMER) -p $(MCU_FLASH) -U flash:w:$(BUILD_DIR)/$(M)/main.hex:i

clean:
	rm -rf $(BUILD_DIR)
