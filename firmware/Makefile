CROSS=riscv32-unknown-elf-
CFLAGS = -march=rv32im -Wl,-Bstatic,-T,sections.lds,--strip-debug -ffreestanding -nostdlib -mstrict-align -O0  


firmware.elf: sections.lds start.s firmware.c
	${CROSS}gcc -DCLK_FREQ=50000000 ${CFLAGS} -o $@ start.s firmware.c

firmware_testbench.elf: sections.lds start.s firmware_tb.c
	${CROSS}gcc -DCLK_FREQ=50000000 ${CFLAGS} -o $@ start.s firmware_tb.c


%.hex: %.elf
	${CROSS}objcopy -O verilog $< $@

%.lst: %.elf
	${CROSS}objdump -d $< >$@


progmem: hex2progmem.py firmware.hex
	python3 hex2progmem.py firmware.hex > progmem.v

progmem_tb: hex2progmem.py firmware_testbench.hex
	python3 hex2progmem.py firmware_testbench.hex > progmem_tb.v


all_noflash: firmware.elf firmware.hex firmware.lst progmem

all_testbench: firmware_testbench.elf firmware_testbench.hex firmware_testbench.lst progmem_tb

all: all_noflash all_testbench

clear:
	rm -rf *.elf
	rm -rf *.hex
	rm -rf *.lst
	rm -rf *.v