# Use MSYS2 Bash for Unix-style commands
SHELL := C:/msys64/usr/bin/bash.exe
.SHELLFLAGS := -c

# Compiler
CC := gcc

# Project configuration
TARGET := program

SRC_DIR := src
INC_DIR := include
LIB_DIR := lib
DLL_DIR := dll
BUILD_DIR := build
OBJ_DIR := $(BUILD_DIR)/obj

# Compiler flags
CFLAGS := -std=c99 -Wall -Wextra -Wpedantic -g -O0
CPPFLAGS := -I$(INC_DIR) -I$(SRC_DIR)

# Linker flags and libraries
LDFLAGS := -L$(LIB_DIR)
# Auto-discover static and import libraries in lib/ (.a, .lib, .dll.a)
AUTO_LIBS := $(sort $(wildcard $(LIB_DIR)/*.a) $(wildcard $(LIB_DIR)/*.lib))
# Additional system or manual libraries (e.g. -lm, -lws2_32)
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
	$(CC) $(LDFLAGS) -o "$@" $(OBJECTS) -Wl,--as-needed -Wl,--start-group $(AUTO_LIBS) -Wl,--end-group $(LDLIBS)
	@if [ -d "$(DLL_DIR)" ]; then \
		for file in $(DLL_DIR)/*.dll; do \
			if [ -f "$$file" ]; then \
				cp -f "$$file" "$(BUILD_DIR)/"; \
			fi; \
		done; \
	fi

# Compile source files
$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c
	@mkdir -p "$(@D)"
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
