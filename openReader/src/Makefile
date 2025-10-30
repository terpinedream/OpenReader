# Makefile for Kindle Touch Reader
# Cross-compile for ARM

# Toolchains - try multiple possibilities
CC_ARM = arm-linux-gnueabihf-gcc
CC_ARM_ALT = arm-none-eabi-gcc

# Flags
CFLAGS = -Wall -O2 -static
TARGET = touch_reader
SRC = touch_reader.c

# Output directory
OUTDIR = ../bin

all: arm

# ARM build (static for portability)
arm:
	@echo "Building for ARM (static)..."
	@mkdir -p $(OUTDIR)
	@if command -v $(CC_ARM) >/dev/null 2>&1; then \
		$(CC_ARM) $(CFLAGS) $(SRC) -o $(OUTDIR)/$(TARGET); \
		echo "✓ Built with $(CC_ARM)"; \
	elif command -v $(CC_ARM_ALT) >/dev/null 2>&1; then \
		$(CC_ARM_ALT) $(CFLAGS) $(SRC) -o $(OUTDIR)/$(TARGET); \
		echo "✓ Built with $(CC_ARM_ALT)"; \
	else \
		echo "✗ No ARM cross-compiler found!"; \
		echo "Install with: sudo apt install gcc-arm-linux-gnueabihf"; \
		exit 1; \
	fi

# Test build for host (x86_64)
test:
	@echo "Building for host (testing)..."
	@mkdir -p $(OUTDIR)
	gcc $(CFLAGS) $(SRC) -o $(OUTDIR)/$(TARGET)_test
	@echo "✓ Test binary: $(OUTDIR)/$(TARGET)_test"

clean:
	rm -f $(OUTDIR)/$(TARGET) $(OUTDIR)/$(TARGET)_test

install: arm
	@echo "Binary ready at: $(OUTDIR)/$(TARGET)"
	@echo "Copy to Kindle: /mnt/us/extensions/openReader/bin/"

.PHONY: all arm test clean install





