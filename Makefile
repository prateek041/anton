# === Toolchain ===
ASM      := nasm
CC       := i686-elf-gcc
LD       := i686-elf-ld
QEMU     := qemu-system-i386

# === Flags ===
CFLAGS   := -ffreestanding -O2 -Wall -Wextra -Isrc/include
LDFLAGS  := -T src/linker.ld -nostdlib

# === Files ===
BUILD    := build
BOOT_OBJ := $(BUILD)/boot.o
KERN_OBJ := $(BUILD)/kernel.o
KERNEL   := $(BUILD)/anton.bin

# === OS Targets ===
.PHONY: run debug clean docs docs-build docs-serve docs-clean docs-watch

run: $(KERNEL)
	$(QEMU) -kernel $(KERNEL)

debug: $(KERNEL)
	$(QEMU) -kernel $(KERNEL) -s -S &
	gdb -ex "target remote :1234" -ex "symbol-file $(KERNEL)"

$(KERNEL): $(BOOT_OBJ) $(KERN_OBJ)
	$(LD) $(LDFLAGS) -o $@ $^

$(BUILD)/boot.o: src/boot/boot.asm | $(BUILD)
	$(ASM) -f elf32 $< -o $@

$(BUILD)/kernel.o: src/kernel/kernel.c | $(BUILD)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD):
	mkdir -p $(BUILD)

clean:
	rm -rf $(BUILD)

# === Docs Targets ===
MDBOOK   := mdbook
DOCS_DIR := docs

docs: docs-serve

docs-build: _require-mdbook
	$(MDBOOK) build $(DOCS_DIR)

docs-serve: _require-mdbook
	$(MDBOOK) serve $(DOCS_DIR) --open

docs-clean: _require-mdbook
	$(MDBOOK) clean $(DOCS_DIR)

docs-watch: _require-mdbook
	$(MDBOOK) watch $(DOCS_DIR)

_require-mdbook:
	@command -v $(MDBOOK) >/dev/null 2>&1 || { \
		echo "error: mdbook is not installed or not on PATH."; \
		echo "  Arch: sudo pacman -S mdbook"; \
		echo "  Or:   cargo install mdbook"; \
		exit 127; \
	}
