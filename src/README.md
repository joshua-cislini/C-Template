# `src/` — Application and Library Source Code

This directory contains the primary C source files (`.c`) and internal/private header files (`.h`) for the project.

---

## How It Works

The build system (`Makefile`) automatically discovers and compiles code in `src/` without requiring any manual updates:

1. **Recursive Source Discovery**:
   - Every `.c` file located directly in `src/` or within any nested subdirectory (e.g., `src/core/`, `src/utils/`, `src/render/`) is automatically detected via recursive wildcard scanning.
   - Each source file is compiled into a corresponding object file in `build/<mode>/obj/src/...` preserving directory structure.

2. **Automatic Internal Header Inclusion**:
   - `src/` and **all its nested subdirectories** are automatically added to the compiler's include path (`-I`).
   - Any private header placed inside `src/` (e.g., `src/internal_helpers.h` or `src/core/state.h`) can be included cleanly without convoluted relative paths (`../../`):
     ```c
     #include "internal_helpers.h"
     #include "state.h"
     ```

3. **Application Entry Point (`src/main.c`)**:
   - `src/main.c` contains the standard `main()` function for executable builds.
   - The Makefile designates this file through `MAIN_SRC ?= $(SRC_DIR)/main.c`.
   - **Crucial Behavior**:
     - When building the main application (`PROJECT_TYPE=executable`), `main.c` is compiled and linked.
     - When building **unit tests** (`make test`), `main.c` is **automatically excluded** so each test suite in `tests/test_*.c` can provide its own `main()` function without symbol collisions.
     - When building **libraries** (`PROJECT_TYPE=static` or `PROJECT_TYPE=shared`), `main.c` is also **automatically excluded** to ensure the produced library contains only reusable module functions.

4. **Injected Preprocessor Macros**:
   Every source file in `src/` is compiled with project metadata injected directly from `config.mk`:
   - `PROJECT_NAME`: A string literal representing the project name (e.g., `"C-Template"`).
   - `PROJECT_VERSION`: A string literal representing the current version (e.g., `"0.1.0"`).
   - `DEBUG` (in debug mode) or `NDEBUG` (in release mode).

---

## Directory Organization Guidelines

You can organize your source files in flat or modular hierarchies:

### Modular Architecture Example
```text
src/
├── main.c                  # CLI entry point, argument parsing, high-level coordination
├── greeting.c              # Public module implementation (declared in include/greeting.h)
├── core/
│   ├── engine.c            # Core engine logic
│   └── engine_internal.h   # Private engine header (not exposed in include/)
└── utils/
    ├── string_utils.c      # Utility functions
    └── string_utils.h      # Internal utility header
```

### Public vs. Private Headers
- **Public Headers (`include/`)**: Place API contracts, structs, and function prototypes meant to be consumed by external users, other libraries, or your unit test suites in `include/`.
- **Private Headers (`src/`)**: Place implementation-specific details, private macros, and internal helper prototypes in `src/` alongside their `.c` files to prevent leaking implementation details.

---

## Starter Files Included

- **`main.c`**:
  Demonstrates clean command-line argument handling (`--version`, custom name argument), return code usage (`EXIT_SUCCESS`, `EXIT_FAILURE`), and calling module functions.
- **`greeting.c`**:
  Implementation of the sample module defined in `include/greeting.h`, demonstrating buffer bounds checking, safe default fallback, and clean formatting.
