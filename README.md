# Modern C Project Template

A professional, cross-platform, zero-friction C project template designed for real-world projects.

Compiles out of the box on **Windows** (MSYS2 UCRT64, native `cmd.exe`, PowerShell, Git Bash), **Linux**, and **macOS** with **GNU Make**, **GCC** or **Clang**, **clangd**, **GDB/LLDB**, and **VS Code**.

---

## Highlights

- **Zero-Config Drag-and-Drop Dependencies (`dependencies/`)**: Drop external libraries (`.h`, `.a`, `.lib`, `.dll.a`) or complete SDK folders into `dependencies/` and build immediately. No manual Makefile edits required.
- **Automatic Runtime Library Deployment**: Windows DLLs (and Linux/macOS shared objects) in `dependencies/` are automatically copied directly alongside the target executable on every build.
- **Single Configuration File (`config.mk`)**: All project knobs (binary name, project type, C standard, warning levels, compiler, flags) live in `config.mk`. The generic `Makefile` never needs editing.
- **Three Target Types**: Switch between `executable`, `static` library (`lib<name>.a`), or `shared` library (`.dll` / `.so` / `.dylib`) by changing a single variable.
- **Dual Build Modes**: Clean separation of `build/debug/` and `build/release/` artifacts.
- **Header Dependency Tracking**: Incremental builds track header changes automatically via compiler-generated `.d` files.
- **Auto-Generated `compile_commands.json`**: Accurate compilation database generated directly from the build configuration on every run, powering **clangd** with zero configuration drift.
- **Built-in Unit Testing (`make test`)**: Standalone, multi-suite test harness with a lightweight, zero-dependency testing helper (`tests/test_framework.h`).
- **Sanitizer Support**: One-command sanitizer builds via `make SANITIZE=address,undefined`.
- **First-Class Tooling**: Pre-configured **Clang-Format** (formatting), **Clang-Tidy** (static analysis), and **EditorConfig** (editor consistency).
- **Turnkey VS Code Integration**: Rich `tasks.json` (build, run, test, format, tidy), `launch.json` (F5 debug with GDB/LLDB pretty printing), and `settings.json`.
- **Pre-Configured GitHub Actions CI**: Multi-platform matrix testing on Ubuntu (GCC & Clang), macOS (Clang), and Windows (MSYS2 UCRT64).

---

## Project Structure

```text
.
├── config.mk                 # Project identity, flags, and build configuration
├── Makefile                  # Portable build engine (POSIX sh & Windows cmd.exe)
├── .clang-format             # Code formatting rules
├── .clang-tidy               # Static analysis rules
├── .editorconfig             # Editor whitespace and indent definitions
├── .gitattributes            # Line endings and binary file handling
├── .gitignore                # Ignores build artifacts and editor caches
│
├── src/                      # C source files (compiled automatically)
│   ├── main.c                # Application entry point (excluded during test builds)
│   └── greeting.c            # Example implementation
│
├── include/                  # Public project headers
│   └── greeting.h            # Example header
│
├── tests/                    # Unit tests (compiled and run by `make test`)
│   ├── test_framework.h      # Minimal, dependency-free test assertion macros
│   └── test_greeting.c       # Example test suite
│
├── dependencies/             # External third-party libraries (drop-in)
│   ├── README.md             # Guide on library layouts and linking
│   ├── include/              # Loose third-party headers
│   ├── lib/                  # Loose third-party libraries (.a, .lib, .dll.a)
│   ├── bin/                  # Loose runtime files (.dll)
│   └── <package>/            # (Optional) Extracted SDK folders (include/, lib/, bin/)
│
├── build/                    # Generated automatically (ignored by git)
│   ├── debug/
│   │   ├── bin/              # Executables and copied runtime DLLs
│   │   └── obj/              # Object (.o) and dependency (.d) files
│   └── release/
│       ├── bin/
│       └── obj/
│
└── .vscode/                  # Editor & debugger configurations
    ├── extensions.json       # Recommended extensions (clangd, cpptools)
    ├── launch.json           # F5 debug launcher (GDB/LLDB)
    ├── settings.json         # clangd & formatting settings
    └── tasks.json            # Build, test, clean, and analyze tasks
```

---

## Quick Start

### 1. Requirements

- A C compiler: **GCC** or **Clang**
- **GNU Make** (version 4.0 or newer recommended)
- Optional: **clangd** (language server), **clang-format**, **clang-tidy**, **GDB** or **LLDB**

#### Windows (MSYS2 UCRT64 — Recommended)
Install [MSYS2](https://www.msys2.org/), open the **MSYS2 UCRT64** terminal, and install the complete toolchain:

```bash
pacman -S --needed \
    mingw-w64-ucrt-x86_64-gcc \
    mingw-w64-ucrt-x86_64-gdb \
    mingw-w64-ucrt-x86_64-make \
    mingw-w64-ucrt-x86_64-clang \
    mingw-w64-ucrt-x86_64-clang-tools-extra
```

Add `C:\msys64\ucrt64\bin` and `C:\msys64\usr\bin` to your Windows `PATH` environment variable.

#### Linux (Debian / Ubuntu)
```bash
sudo apt update
sudo apt install build-essential gcc gdb clangd clang-format clang-tidy
```

#### macOS (Homebrew)
```bash
brew install make llvm
```

---

### 2. Build and Run

Run from your terminal or command prompt:

```bash
# Debug build (default)
make

# Run the program
make run

# Pass arguments to the program
make run ARGS="Ada"

# Run unit tests
make test

# Release build with optimizations (-O2, stripped symbols)
make release
make release run
```

> **Note for Windows users:** If `make` is not aliased, use `mingw32-make`. The Makefile detects whether it is running under Bash, PowerShell, or native `cmd.exe` and handles paths and commands accordingly.

---

## Customizing Your Project (`config.mk`)

You should rarely need to modify the `Makefile`. All project configurations are defined in `config.mk`:

| Variable | Default | Description |
|---|---|---|
| `PROJECT` | Folder name | Name of output binary (defaults to current folder name) |
| `VERSION` | `0.1.0` | Injected into code as `PROJECT_VERSION` macro |
| `PROJECT_TYPE` | `executable` | Build output: `executable`, `static`, or `shared` |
| `BUILD` | `debug` | Default mode: `debug` or `release` |
| `CC` | `gcc` | Compiler: `gcc`, `clang`, or cross-compiler |
| `C_STANDARD` | `c17` | C standard (`c99`, `c11`, `c17`, `c23`) |
| `WARNINGS` | `-Wall -Wextra ...` | Warning flags |
| `WERROR` | `0` | Treat warnings as errors (set `1` for CI) |
| `SANITIZE` | *(empty)* | Sanitizers, e.g. `make SANITIZE=address,undefined` |
| `LDLIBS` | `-lm` | System libraries (e.g. `-lws2_32 -lopengl32`) |
| `PKG_CONFIG_PACKAGES` | *(empty)* | Packages discovered via `pkg-config` (e.g. `sdl2`) |

Any variable can also be overridden from the command line:

```bash
make PROJECT=my_app BUILD=release CC=clang
```

---

## Adding Dependencies (Drag-and-Drop)

Adding third-party libraries requires **zero Makefile adjustments**:

### Option A: Loose Files Layout
Drop files directly into the standard subdirectories:
- **Headers (`.h`)**: Place in `dependencies/include/`
- **Libraries (`.a`, `.lib`, `.dll.a`, `.so`, `.dylib`)**: Place in `dependencies/lib/`
- **Runtime DLLs (`.dll`)**: Place in `dependencies/bin/`

### Option B: Vendor Package Layout
When downloading precompiled libraries (such as SDL2, cJSON, Raylib, or GLFW), simply extract the library folder directly into `dependencies/<package>/`:

```text
dependencies/
└── SDL2/
    ├── include/
    │   └── SDL2/
    │       └── SDL.h
    ├── lib/
    │   ├── libSDL2.dll.a
    │   └── libSDL2main.a
    └── bin/
        └── SDL2.dll
```

### How the Build System Handles Dependencies
1. **Include paths**: All `dependencies/**/include` directories are automatically added with `-isystem` (compiler warnings in third-party headers are suppressed).
2. **Auto-linking**: Every `.a`, `.lib`, and `.dll.a` found in library directories is passed to the linker inside `-Wl,--start-group ... -Wl,--end-group` to eliminate order-dependent linking issues.
3. **Smart library selection**: If both a static archive and an import/shared library exist (e.g. `libfoo.a` and `libfoo.dll.a`), the shared library is preferred automatically.
4. **Runtime deployment**: Every `.dll` found in `dependencies/**/bin` or `dependencies/**/lib` is automatically copied into `build/<mode>/bin/` alongside your executable.
5. **Dead-stripping**: `-Wl,--as-needed` ensures libraries that are dropped in but not referenced do not bloat the resulting executable.

Run `make info` anytime to inspect detected include directories, auto-linked libraries, and copied DLLs.

---

## Unit Testing

Place test files in the `tests/` directory named `test_<suite>.c`:

```c
#include "greeting.h"
#include "test_framework.h"

static void test_greeting(void) {
    char buffer[64];
    greeting_format(buffer, sizeof buffer, "Alice");
    CHECK_EQ_STR("Hello, Alice!", buffer);
}

int main(void) {
    RUN_TEST(test_greeting);
    return TEST_REPORT();
}
```

Run tests with:

```bash
make test
```

The test runner:
- Compiles all project sources (excluding `src/main.c`).
- Builds each `tests/test_*.c` file into an isolated executable in `build/<mode>/bin/`.
- Executes each suite, reports test counts and assertions, and returns a non-zero exit code if any check fails.

---

## Code Quality & Tooling

### Clang-Format
Format all source files and headers:
```bash
make format
```
Check if all files conform to the style rules without modifying them:
```bash
make format-check
```

### Clang-Tidy
Run static analysis across your codebase:
```bash
make tidy
```

### `compile_commands.json`
Every build automatically regenerates an up-to-date `compile_commands.json` in the project root. This ensures that **clangd** always has the exact compiler flags, macro definitions, and search paths without requiring any manual updates.

---

## Make Targets Reference

| Target | Description |
|---|---|
| `make` / `make all` | Build project in debug mode (`build/debug/bin/`) |
| `make release` | Build project in release mode (`build/release/bin/`) |
| `make run [ARGS="..."]` | Build and execute the program with optional arguments |
| `make test` | Build and run all unit test suites in `tests/` |
| `make clean` | Delete the `build/` directory |
| `make rebuild` | Clean and rebuild the project |
| `make format` | Format source and header files using `clang-format` |
| `make format-check` | Check code formatting compliance |
| `make tidy` | Run static analysis using `clang-tidy` |
| `make info` | Print detected toolchains, sources, flags, and dependencies |
| `make help` | Display target and variable help |

---

## VS Code Integration

Open the project folder in VS Code (`code .`). The repository includes full editor integration:

- **IntelliSense & Diagnostics**: Powered by **clangd** and the automatically generated `compile_commands.json`.
- **Keyboard Shortcuts**:
  - `Ctrl + Shift + B`: Run default build task.
  - `F5`: Build and launch with **GDB** debugger.
  - `Ctrl + F5`: Run without debugging.
- **Tasks Menu (`Terminal > Run Task...`)**:
  - `Build` (Debug)
  - `Build Release`
  - `Run`
  - `Test`
  - `Clean`
  - `Rebuild`
  - `Format`
  - `Tidy`
- **Interactive Console**: For programs requiring terminal user input (`stdin`), use the **"Debug (external console)"** launch target from the Run & Debug view.

---

## License

This template is licensed under the [MIT License](LICENSE).
