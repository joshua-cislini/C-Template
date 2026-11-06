# =============================================================================
#  Generic C build system (Makefile)
# =============================================================================
#  You normally do NOT need to edit this file:
#    - project settings live in config.mk
#    - source files go into src/, headers into include/
#    - third-party libraries go into lib/, runtime DLLs/shared libs into bin/
#
#  Works on Windows (MSYS2 / MinGW-w64, from a POSIX shell OR plain cmd.exe),
#  Linux and macOS with GNU Make. Run `make help` for the available targets.
# =============================================================================

# --- Helpers -----------------------------------------------------------------

empty :=
space := $(empty) $(empty)
comma := ,
define newline


endef

# Recursive wildcard: $(call rwildcard,<dir>,<pattern>)
rwildcard = $(foreach d,$(wildcard $(1:=/*)),$(call rwildcard,$d,$2) $(filter $(subst *,%,$2),$d))

# Recursive directory finder: $(call find_dirs,<dir>) returns <dir> and all subdirectories
find_dirs = $(sort $(patsubst %/,%,$1 $(dir $(wildcard $1/*/) $(call rwildcard,$1,*))))

# Folder name of the project (spaces replaced by underscores).
PROJECT_DIR_NAME := $(subst ?,_,$(notdir $(subst $(space),?,$(CURDIR))))

# --- Configuration (with fallbacks if config.mk is untouched or missing) -----

-include config.mk

PROJECT             ?= $(PROJECT_DIR_NAME)
VERSION             ?= 0.1.0
PROJECT_TYPE        ?= executable
BUILD               ?= debug
ifeq ($(origin CC),default)
CC                  := gcc
endif
C_STANDARD          ?= c17
WARNINGS            ?= -Wall -Wextra -Wpedantic -Wshadow -Wformat=2 -Wundef \
                       -Wstrict-prototypes -Wmissing-prototypes -Wold-style-definition
WERROR              ?= 0
DEBUG_CFLAGS        ?= -g3 -O0 -DDEBUG
RELEASE_CFLAGS      ?= -O2 -DNDEBUG
DEBUG_LDFLAGS       ?=
RELEASE_LDFLAGS     ?= -s
SANITIZE            ?=
EXTRA_CPPFLAGS      ?=
EXTRA_CFLAGS        ?=
EXTRA_LDFLAGS       ?=
LDLIBS              ?= -lm
PKG_CONFIG_PACKAGES ?=
SRC_DIR             ?= src
INC_DIR             ?= include
LIB_DIR             ?= lib
BIN_DIR             ?= bin
TEST_DIR            ?= tests
BUILD_DIR           ?= build
AUTO_LINK           ?= 1
AUTO_LINK_EXCLUDE   ?=
MAIN_SRC            ?= $(SRC_DIR)/main.c
COMPILE_COMMANDS    ?= 1
CLANG_FORMAT        ?= clang-format
CLANG_TIDY          ?= clang-tidy
PKG_CONFIG          ?= pkg-config
ARGS                ?=

.DEFAULT_GOAL := all

# `make release <goals>` / `make debug <goals>` select the build mode.
ifneq ($(filter release,$(MAKECMDGOALS)),)
override BUILD := release
endif
ifneq ($(filter debug,$(MAKECMDGOALS)),)
override BUILD := debug
endif

# --- Host / shell detection --------------------------------------------------

# Which shell runs the recipes? On Windows, GNU Make uses sh.exe when it is on
# PATH (MSYS2, Git for Windows, w64devkit) and falls back to cmd.exe otherwise.
ifeq ($(OS),Windows_NT)
  ifeq ($(shell echo "q"),"q")
    SHELL_TYPE := cmd
  else
    SHELL_TYPE := sh
  endif
else
  SHELL_TYPE := sh
endif

# Target platform (override with PLATFORM=windows|linux|macos when cross-compiling).
ifndef PLATFORM
  ifeq ($(OS),Windows_NT)
    PLATFORM := windows
  else ifeq ($(shell uname -s 2>/dev/null),Darwin)
    PLATFORM := macos
  else
    PLATFORM := linux
  endif
endif

# GNU Make >= 4 (needed for $(file) and for setting -j from inside the makefile).
MAKE_4 := $(if $(filter 4,$(firstword $(sort $(MAKE_VERSION) 4))),1,)

# --- Shell abstraction -------------------------------------------------------

ifeq ($(SHELL_TYPE),cmd)
  native_path = $(subst /,\,$1)
  MKDIR   = if not exist "$(call native_path,$1)" mkdir "$(call native_path,$1)"
  RMDIR   = if exist "$(call native_path,$1)" rmdir /s /q "$(call native_path,$1)"
  RMFILE  = if exist "$(call native_path,$1)" del /q "$(call native_path,$1)"
  COPY    = copy /y "$(call native_path,$1)" "$(call native_path,$2)" >nul
  RUN     = $(call native_path,$1)
  LOGLINE = @echo   $1	$2
else
  MKDIR   = mkdir -p "$1"
  RMDIR   = rm -rf "$1"
  RMFILE  = rm -f "$1"
  COPY    = cp -f "$1" "$2"
  RUN     = $(if $(filter /%,$1),$1,./$1)
  LOGLINE = @printf '  %-6s %s\n' '$1' '$2'
endif

# Quiet output by default; `make V=1` prints the full commands.
ifeq ($(V),1)
  Q :=
  LOG =
else
  Q := @
  LOG = $(LOGLINE)
endif

# Parallel build by default (override with `make -jN` or JOBS=N).
ifeq ($(MAKE_4),1)
  ifeq ($(filter -j%,$(MAKEFLAGS)),)
    ifeq ($(OS),Windows_NT)
      JOBS ?= $(if $(NUMBER_OF_PROCESSORS),$(NUMBER_OF_PROCESSORS),4)
    else
      JOBS ?= $(shell nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 1)
    endif
    MAKEFLAGS += -j$(JOBS)
  endif
endif

# `make clean all` must not run clean in parallel with the build.
ifneq ($(filter clean rebuild,$(MAKECMDGOALS)),)
.NOTPARALLEL:
endif

# --- Build mode --------------------------------------------------------------

ifeq ($(BUILD),debug)
  MODE_CFLAGS  := $(DEBUG_CFLAGS)
  MODE_LDFLAGS := $(DEBUG_LDFLAGS)
else ifeq ($(BUILD),release)
  MODE_CFLAGS  := $(RELEASE_CFLAGS)
  MODE_LDFLAGS := $(RELEASE_LDFLAGS)
else
  $(error BUILD must be 'debug' or 'release', got '$(BUILD)')
endif

OUT_DIR     := $(BUILD_DIR)/$(BUILD)
OBJ_DIR     := $(OUT_DIR)/obj
OUT_BIN_DIR := $(OUT_DIR)/bin

# --- Platform specifics ------------------------------------------------------

ifeq ($(PLATFORM),windows)
  EXE           := .exe
  SHARED_NAME   := $(PROJECT).dll
  LINK_LIB_GLOB := *.a *.lib
  RUNTIME_GLOB  := *.dll
  RPATH         :=
  LINK_GROUP    := 1
else ifeq ($(PLATFORM),macos)
  EXE           :=
  SHARED_NAME   := lib$(PROJECT).dylib
  LINK_LIB_GLOB := *.a *.dylib
  RUNTIME_GLOB  := *.dylib
  RPATH         := -Wl,-rpath,@executable_path
  LINK_GROUP    :=
  MODE_LDFLAGS  := $(filter-out -s,$(MODE_LDFLAGS))
else
  EXE           :=
  SHARED_NAME   := lib$(PROJECT).so
  LINK_LIB_GLOB := *.a *.so
  RUNTIME_GLOB  := *.so *.so.*
  RPATH         := -Wl,-rpath,'$$ORIGIN'
  LINK_GROUP    := 1
endif

# --- Sources -----------------------------------------------------------------

SOURCES      := $(sort $(call rwildcard,$(SRC_DIR),*.c))
LIB_SOURCES  := $(filter-out $(MAIN_SRC),$(SOURCES))
TEST_MAINS   := $(sort $(wildcard $(TEST_DIR)/test_*.c))
TEST_SUPPORT := $(filter-out $(TEST_MAINS),$(sort $(call rwildcard,$(TEST_DIR),*.c)))
ALL_SOURCES  := $(SOURCES) $(TEST_MAINS) $(TEST_SUPPORT)

to_obj = $(patsubst %.c,$(OBJ_DIR)/%.o,$1)

OBJECTS              := $(call to_obj,$(SOURCES))
LIB_OBJECTS          := $(call to_obj,$(LIB_SOURCES))
TEST_SUPPORT_OBJECTS := $(call to_obj,$(TEST_SUPPORT))
ALL_OBJECTS          := $(call to_obj,$(ALL_SOURCES))

FORMAT_FILES := $(sort $(foreach d,$(SRC_DIR) $(INC_DIR) $(TEST_DIR),$(call rwildcard,$d,*.c) $(call rwildcard,$d,*.h)))

# --- Recursive Include, Library, and Runtime Discovery -----------------------
#  - include/ and src/ (plus all nested subdirectories) are added to include paths
#  - lib/ (plus all nested subdirectories) are scanned for static/import libraries
#  - bin/ and lib/ (plus all nested subdirectories) are scanned for runtime DLLs/.so/.dylib

ALL_INC_DIRS := $(call find_dirs,$(INC_DIR)) $(call find_dirs,$(SRC_DIR))
ALL_LIB_DIRS := $(filter-out %/cmake %/pkgconfig,$(call find_dirs,$(LIB_DIR)))
ALL_BIN_DIRS := $(call find_dirs,$(BIN_DIR))

LIB_FILES := $(sort $(foreach p,$(LINK_LIB_GLOB),$(call rwildcard,$(LIB_DIR),$p)))
# When a library exists both as shared/import and static, prefer the shared one
# (static libraries often need extra system libraries to link).
LIB_FILES := $(filter-out $(patsubst %.dll.a,%.a,$(filter %.dll.a,$(LIB_FILES))) \
                          $(patsubst %.so,%.a,$(filter %.so,$(LIB_FILES))) \
                          $(patsubst %.dylib,%.a,$(filter %.dylib,$(LIB_FILES))),$(LIB_FILES))
LIB_FILES := $(filter-out $(addprefix %/,$(AUTO_LINK_EXCLUDE)) $(AUTO_LINK_EXCLUDE),$(LIB_FILES))

ifeq ($(AUTO_LINK),1)
  ifeq ($(PLATFORM),linux)
    # -l:<file> records the bare file name in the executable (not the path).
    AUTO_LIBS := $(addprefix -l:,$(notdir $(LIB_FILES)))
  else
    AUTO_LIBS := $(LIB_FILES)
  endif
endif

# Runtime files (DLLs / shared objects) in bin/ or lib/ copied next to the binaries.
RUNTIME_FILES  := $(sort $(foreach d,$(BIN_DIR) $(LIB_DIR),$(foreach p,$(RUNTIME_GLOB),$(call rwildcard,$d,$p))))
RUNTIME_COPIES := $(sort $(addprefix $(OUT_BIN_DIR)/,$(notdir $(RUNTIME_FILES))))

# --- pkg-config --------------------------------------------------------------

ifneq ($(strip $(PKG_CONFIG_PACKAGES)),)
  PKG_CFLAGS := $(shell $(PKG_CONFIG) --cflags $(PKG_CONFIG_PACKAGES))
  PKG_LIBS   := $(shell $(PKG_CONFIG) --libs $(PKG_CONFIG_PACKAGES))
endif

# --- Final flags -------------------------------------------------------------

ifeq ($(PROJECT_TYPE),shared)
  ifneq ($(PLATFORM),windows)
    PIC_FLAGS := -fPIC
  endif
endif

SANITIZE_FLAGS := $(if $(strip $(SANITIZE)),-fsanitize=$(SANITIZE) -fno-omit-frame-pointer)

ALL_CPPFLAGS := $(addprefix -I,$(ALL_INC_DIRS)) \
                -DPROJECT_NAME=\"$(PROJECT)\" -DPROJECT_VERSION=\"$(VERSION)\" \
                $(PKG_CFLAGS) $(EXTRA_CPPFLAGS) $(CPPFLAGS)
ALL_CFLAGS   := -std=$(C_STANDARD) $(WARNINGS) $(if $(filter 1,$(WERROR)),-Werror) \
                $(MODE_CFLAGS) $(SANITIZE_FLAGS) $(PIC_FLAGS) $(EXTRA_CFLAGS) $(CFLAGS)
ALL_LDFLAGS  := $(MODE_LDFLAGS) $(SANITIZE_FLAGS) $(addprefix -L,$(ALL_LIB_DIRS)) \
                $(RPATH) $(EXTRA_LDFLAGS) $(LDFLAGS)
ALL_LDLIBS   := $(if $(LINK_GROUP),-Wl$(comma)--as-needed) \
                $(if $(AUTO_LIBS),$(if $(LINK_GROUP),-Wl$(comma)--start-group) $(AUTO_LIBS) $(if $(LINK_GROUP),-Wl$(comma)--end-group)) \
                $(PKG_LIBS) $(LDLIBS)
DEPFLAGS     := -MMD -MP

# Rebuild everything when the build configuration changes.
BUILD_FILES := Makefile $(wildcard config.mk)

# --- Outputs -----------------------------------------------------------------

ifeq ($(PROJECT_TYPE),executable)
  TARGET := $(OUT_BIN_DIR)/$(PROJECT)$(EXE)
else ifeq ($(PROJECT_TYPE),static)
  TARGET := $(OUT_BIN_DIR)/lib$(PROJECT).a
else ifeq ($(PROJECT_TYPE),shared)
  TARGET := $(OUT_BIN_DIR)/$(SHARED_NAME)
else
  $(error PROJECT_TYPE must be 'executable', 'static' or 'shared', got '$(PROJECT_TYPE)')
endif

TEST_NAMES := $(basename $(notdir $(TEST_MAINS)))
TEST_BINS  := $(addprefix $(OUT_BIN_DIR)/,$(addsuffix $(EXE),$(TEST_NAMES)))
TEST_RUNS  := $(addprefix run-,$(TEST_NAMES))

# Every directory that must exist.
ALL_DIRS := $(sort $(OUT_BIN_DIR) $(patsubst %/,%,$(dir $(ALL_OBJECTS))))

# --- compile_commands.json (clangd, clang-tidy) ------------------------------
#  Rewritten whenever the list of sources or the flags change.

ifeq ($(COMPILE_COMMANDS)$(MAKE_4),11)
  ifeq ($(SHELL_TYPE),cmd)
    CC_PATH := $(subst \,/,$(firstword $(shell where $(CC) 2>nul)))
  else ifeq ($(OS),Windows_NT)
    CC_PATH := $(shell p=$$(command -v $(CC) 2>/dev/null) && { cygpath -m "$$p" 2>/dev/null || echo "$$p"; })
  else
    CC_PATH := $(shell command -v $(CC) 2>/dev/null)
  endif
  CC_PATH := $(if $(CC_PATH),$(CC_PATH),$(CC))

  json_escape  = $(subst ",\",$(subst \,\\,$1))
  compdb_entry = {$(newline)  "directory": "$(subst \,/,$(CURDIR))",$(newline)  "file": "$1",$(newline)  "command": "$(call json_escape,$(strip $(CC_PATH) $(ALL_CPPFLAGS) $(ALL_CFLAGS) -c $1 -o $(call to_obj,$1)))"$(newline)}
  COMPDB_JSON := [$(newline)$(subst }$(space){,}$(comma)$(newline){,$(foreach s,$(ALL_SOURCES),$(call compdb_entry,$s)))$(newline)]

  ifneq ($(COMPDB_JSON),$(file <compile_commands.json))
    $(file >compile_commands.json,$(COMPDB_JSON))
  endif
endif

# =============================================================================
#  Targets
# =============================================================================

.PHONY: all debug release run test clean rebuild format format-check tidy info help $(TEST_RUNS)

# Keep object files that are only needed by the test executables.
.SECONDARY:

all: $(TARGET) $(RUNTIME_COPIES)

debug release: all

# --- Compile -----------------------------------------------------------------

.SECONDEXPANSION:

$(OBJ_DIR)/%.o: %.c $(BUILD_FILES) | $$(@D)
	$(call LOG,CC,$<)
	$(Q)$(CC) $(ALL_CPPFLAGS) $(ALL_CFLAGS) $(DEPFLAGS) -c $< -o $@

-include $(ALL_OBJECTS:.o=.d)

# --- Link --------------------------------------------------------------------

ifeq ($(PROJECT_TYPE),executable)
$(TARGET): $(OBJECTS) $(LIB_FILES) | $(OUT_BIN_DIR)
	$(call LOG,LINK,$@)
	$(Q)$(CC) $(ALL_LDFLAGS) $(OBJECTS) $(ALL_LDLIBS) -o $@
endif

ifeq ($(PROJECT_TYPE),static)
$(TARGET): $(LIB_OBJECTS) | $(OUT_BIN_DIR)
	$(call LOG,AR,$@)
	$(Q)$(call RMFILE,$@)
	$(Q)$(AR) rcs $@ $(LIB_OBJECTS)
endif

ifeq ($(PROJECT_TYPE),shared)
  ifeq ($(PLATFORM),windows)
    SHARED_LDFLAGS := -shared -Wl,--out-implib,$(OUT_BIN_DIR)/lib$(PROJECT).dll.a
  else ifeq ($(PLATFORM),macos)
    SHARED_LDFLAGS := -dynamiclib -install_name @rpath/$(SHARED_NAME)
  else
    SHARED_LDFLAGS := -shared -Wl,-soname,$(SHARED_NAME)
  endif
$(TARGET): $(LIB_OBJECTS) $(LIB_FILES) | $(OUT_BIN_DIR)
	$(call LOG,LINK,$@)
	$(Q)$(CC) $(SHARED_LDFLAGS) $(ALL_LDFLAGS) $(LIB_OBJECTS) $(ALL_LDLIBS) -o $@
endif

# Test executables: tests/test_<name>.c + tests/ helpers + project code (minus main).
$(OUT_BIN_DIR)/test_%$(EXE): $(OBJ_DIR)/$(TEST_DIR)/test_%.o $(TEST_SUPPORT_OBJECTS) $(LIB_OBJECTS) $(LIB_FILES) | $(OUT_BIN_DIR)
	$(call LOG,LINK,$@)
	$(Q)$(CC) $(ALL_LDFLAGS) $(filter %.o,$^) $(ALL_LDLIBS) -o $@

# --- Runtime files -----------------------------------------------------------

define COPY_RULE
$(OUT_BIN_DIR)/$(notdir $1): $1 | $(OUT_BIN_DIR)
	$$(call LOG,COPY,$$@)
	$(Q)$$(call COPY,$$<,$$@)
endef
$(foreach f,$(RUNTIME_FILES),$(eval $(call COPY_RULE,$f)))

# --- Directories -------------------------------------------------------------
#  Each directory depends on its listed ancestors so that parallel builds
#  never race while creating them.

$(foreach d,$(ALL_DIRS),$(eval $d: | $(foreach a,$(ALL_DIRS),$(if $(filter $a/%,$d),$a))))
$(ALL_DIRS):
	$(Q)$(call MKDIR,$@)

# --- Run / test --------------------------------------------------------------

run: all
ifeq ($(PROJECT_TYPE),executable)
	$(Q)$(call RUN,$(TARGET)) $(ARGS)
else
	$(error make run needs PROJECT_TYPE=executable)
endif

test: $(TEST_RUNS)
ifeq ($(strip $(TEST_NAMES)),)
	@echo No tests found: add $(TEST_DIR)/test_NAME.c files.
else
	@echo All tests passed: $(TEST_NAMES)
endif

$(TEST_RUNS): run-%: $(OUT_BIN_DIR)/%$(EXE) $(RUNTIME_COPIES)
	$(call LOG,TEST,$*)
	$(Q)$(call RUN,$<)

# --- Housekeeping ------------------------------------------------------------

clean:
	$(call LOG,CLEAN,$(BUILD_DIR))
	$(Q)$(call RMDIR,$(BUILD_DIR))

rebuild:
	$(Q)$(MAKE) --no-print-directory clean
	$(Q)$(MAKE) --no-print-directory all BUILD=$(BUILD)

format:
	$(Q)$(CLANG_FORMAT) -i $(FORMAT_FILES)

format-check:
	$(Q)$(CLANG_FORMAT) --dry-run --Werror $(FORMAT_FILES)

tidy:
	$(Q)$(CLANG_TIDY) -p . --quiet $(ALL_SOURCES)

info:
	$(info Project        : $(PROJECT) $(VERSION), $(PROJECT_TYPE), $(BUILD))
	$(info Platform/shell : $(PLATFORM) / $(SHELL_TYPE), GNU Make $(MAKE_VERSION))
	$(info Compiler       : $(CC))
	$(info Output         : $(TARGET))
	$(info Sources        : $(SOURCES))
	$(info Tests          : $(TEST_NAMES))
	$(info Include dirs   : $(ALL_INC_DIRS))
	$(info Library dirs   : $(ALL_LIB_DIRS))
	$(info Auto-linked    : $(AUTO_LIBS))
	$(info Runtime files  : $(RUNTIME_FILES))
	$(info pkg-config     : $(PKG_CONFIG_PACKAGES))
	$(info CPPFLAGS       : $(strip $(ALL_CPPFLAGS)))
	$(info CFLAGS         : $(strip $(ALL_CFLAGS)))
	$(info LDFLAGS        : $(strip $(ALL_LDFLAGS)))
	$(info LDLIBS         : $(strip $(ALL_LDLIBS)))
	$(info )
	@cd .

help:
	$(info Usage: make [target...] [VARIABLE=value...])
	$(info )
	$(info Targets:)
	$(info $(space) all            Build the project - default target, debug mode)
	$(info $(space) release        Optimized build; combine with other goals: make release run)
	$(info $(space) run            Build and run the program; pass arguments with ARGS="a b")
	$(info $(space) test           Build and run every $(TEST_DIR)/test_NAME.c)
	$(info $(space) clean          Delete the $(BUILD_DIR) directory)
	$(info $(space) rebuild        clean + all)
	$(info $(space) format         Format the sources with clang-format)
	$(info $(space) format-check   Fail if a source file is not formatted)
	$(info $(space) tidy           Run clang-tidy static analysis)
	$(info $(space) info           Show the detected configuration and libraries)
	$(info )
	$(info Variables:)
	$(info $(space) BUILD=debug|release   V=1 (verbose)   WERROR=1   SANITIZE=address,undefined)
	$(info )
	$(info Project settings live in config.mk; drop headers in $(INC_DIR)/, libs in $(LIB_DIR)/, DLLs in $(BIN_DIR)/.)
	@cd .
