# =============================================================================
#  Project configuration
# =============================================================================
#  This is the ONLY build file you normally need to touch. The Makefile next to
#  it contains the generic build machinery and reads every setting below.
#
#  Every variable uses `?=` so it can also be overridden from the command line:
#      make PROJECT=demo BUILD=release
# =============================================================================

# --- Identity ----------------------------------------------------------------

# Name of the produced binary. Defaults to the name of the project folder, so
# renaming the folder renames the program (and VS Code's launch.json follows
# automatically). Set it explicitly if your folder name contains spaces.
PROJECT ?= $(PROJECT_DIR_NAME)

# Exposed to the code as the PROJECT_VERSION string macro.
VERSION ?= 0.1.0

# What to build:
#   executable - a program                     (build/<mode>/bin/<name>[.exe])
#   static     - a static library              (build/<mode>/bin/lib<name>.a)
#   shared     - a shared library / DLL        (build/<mode>/bin/<name>.dll, lib<name>.so, lib<name>.dylib)
PROJECT_TYPE ?= executable

# Default build mode: debug or release (`make release` is a shortcut).
BUILD ?= debug

# --- Toolchain ---------------------------------------------------------------

# Any GCC-compatible compiler works: gcc, clang, x86_64-w64-mingw32-gcc, ...
# (make has a built-in default of `cc`, hence the origin check: CC set in the
# environment or on the command line still wins.)
ifeq ($(origin CC),default)
CC := gcc
endif

# --- Language and warnings ---------------------------------------------------

# C standard: c99, c11, c17, c23, gnu17, ...
C_STANDARD ?= c17

WARNINGS ?= -Wall -Wextra -Wpedantic -Wshadow -Wformat=2 -Wundef \
            -Wstrict-prototypes -Wmissing-prototypes -Wold-style-definition

# Set to 1 to turn every warning into an error (recommended for CI).
WERROR ?= 0

# --- Per-mode flags ----------------------------------------------------------

DEBUG_CFLAGS   ?= -g3 -O0 -DDEBUG
RELEASE_CFLAGS ?= -O2 -DNDEBUG

DEBUG_LDFLAGS   ?=
RELEASE_LDFLAGS ?= -s

# Sanitizers, e.g. `make SANITIZE=address,undefined`.
# Supported on Linux/macOS. MinGW only supports a subset (or none) of them.
SANITIZE ?=

# --- Extra flags (appended to the defaults computed by the Makefile) ---------

# Preprocessor flags, e.g. -DUSE_FEATURE -Ithird_party/foo
EXTRA_CPPFLAGS ?=
# Compiler flags, e.g. -march=native
EXTRA_CFLAGS ?=
# Linker flags, e.g. -mwindows (GUI app without a console on Windows)
EXTRA_LDFLAGS ?=

# Libraries that are NOT dropped into dependencies/: system libraries provided
# by the toolchain. Examples: -lws2_32 -lgdi32 -lopengl32 (Windows),
# -lpthread -ldl (Linux). -lm is linked by default for <math.h>.
LDLIBS ?= -lm

# pkg-config packages to compile and link against (e.g. sdl2 gtk4 libcurl).
# Handy on Linux, macOS (Homebrew) and MSYS2 (pacman-installed libraries).
PKG_CONFIG_PACKAGES ?=

# --- Dependencies (drag-and-drop folder) -------------------------------------

# See dependencies/README.md. Libraries found in the lib/ folders are linked
# automatically when AUTO_LINK is 1. Set it to 0 to list them yourself in LDLIBS.
DEPENDENCIES_DIR ?= dependencies
AUTO_LINK ?= 1

# File names (patterns allowed) in dependencies/**/lib that must NOT be linked
# automatically, e.g. libSDL2_test.a or %_static.lib
AUTO_LINK_EXCLUDE ?=

# --- Layout ------------------------------------------------------------------

SRC_DIR   ?= src
INC_DIR   ?= include
TEST_DIR  ?= tests
BUILD_DIR ?= build

# The source file holding main(). It is left out when linking the test
# executables (each test has its own main()) and for library projects.
MAIN_SRC ?= $(SRC_DIR)/main.c

# --- Tooling -----------------------------------------------------------------

# Generate compile_commands.json for clangd / clang-tidy on every make run.
COMPILE_COMMANDS ?= 1

CLANG_FORMAT ?= clang-format
CLANG_TIDY   ?= clang-tidy
PKG_CONFIG   ?= pkg-config

# Arguments passed to the program by `make run`, e.g. make run ARGS="foo bar"
ARGS ?=
