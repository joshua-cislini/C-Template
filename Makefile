# Use MSYS2 Bash for Unix-style commands
SHELL := C:/msys64/usr/bin/bash.exe
.SHELLFLAGS := -c

# Compiler
CC := gcc

# Project configuration
TARGET := program

SRC_DIR := src
INC_DIR := include
BUILD_DIR := build
OBJ_DIR := $(BUILD_DIR)/obj

# Compiler flags
CFLAGS := -std=c99 -Wall -Wextra -Wpedantic -g -O0
CPPFLAGS := -I$(INC_DIR) -I$(SRC_DIR)

# Linker flags and libraries
LDFLAGS :=
LDLIBS :=

# Source and object files
SOURCES := $(wildcard $(SRC_DIR)/*.c)
OBJECTS := $(patsubst $(SRC_DIR)/%.c,$(OBJ_DIR)/%.o,$(SOURCES))
DEPS := $(OBJECTS:.o=.d)

OUTPUT := $(BUILD_DIR)/$(TARGET).exe

# Targets
.PHONY: all run clean rebuild

all: $(OUTPUT)

# Link object files
$(OUTPUT): $(OBJECTS)
	@mkdir -p "$(BUILD_DIR)"
	$(CC) $(LDFLAGS) -o "$@" $(OBJECTS) $(LDLIBS)

	# Copy DLL files if the dll directory exists
	@if [ -d "dll" ]; then \
		for file in dll/*.dll; do \
			[ -f "$$file" ] && cp -f "$$file" "$(BUILD_DIR)/"; \
		done; \
	fi

# Compile source files
$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c
	@mkdir -p "$(OBJ_DIR)"
	$(CC) $(CPPFLAGS) $(CFLAGS) -MMD -MP -c "$<" -o "$@"

# Include automatically generated dependencies
-include $(DEPS)

# Run the program
run: $(OUTPUT)
	./$(OUTPUT)

# Remove build files
clean:
	rm -rf "$(BUILD_DIR)"

# Clean and rebuild
rebuild:
	$(MAKE) clean
	$(MAKE) all
