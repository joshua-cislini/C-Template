# `.vscode/` — Visual Studio Code Integration

This directory contains turnkey development, build, debug, and IntelliSense configuration for **Visual Studio Code**.

---

## Configuration Files Overview

| File | Purpose | Key Features |
|---|---|---|
| [`settings.json`](settings.json) | Editor & Language Server Settings | Enables **clangd**, activates inline **clang-tidy**, sets format-on-save, configures file associations. |
| [`tasks.json`](tasks.json) | Build, Test, Clean & Tooling Tasks | 9 predefined tasks mapping directly to Makefile targets; auto-injects MSYS2 toolchain paths on Windows. |
| [`launch.json`](launch.json) | F5 Debugger Configurations | Dual GDB/LLDB profiles (integrated console & external terminal for interactive input). |
| [`extensions.json`](extensions.json) | Extension Recommendations | Recommends `vscode-clangd`, `cpptools` (debug engine), and `makefile-tools`. |

---

## Detailed File Breakdown

### 1. `settings.json` — Fast, Drift-Free Language Support

This template configures **clangd** as the primary language engine:
- **IntelliSense Engine Disabled in `cpptools`**:
  `"C_Cpp.intelliSenseEngine": "disabled"` avoids running two competing language servers simultaneously.
- **Clangd Configuration**:
  - `--background-index`: Indexes your codebase in the background for instant symbol search.
  - `--clang-tidy`: Displays clang-tidy static analysis warnings and suggestions directly in your editor as you type.
  - `--header-insertion=never`: Prevents unwanted automatic `#include` additions when typing common symbols.
  - `--query-driver`: Allows clangd to discover GCC/Clang built-in system headers (standard library paths) across MinGW, Linux, and macOS.
- **Format on Save**:
  Automatically formats C files on save using the root `.clang-format` configuration.
- **File Associations**:
  - `*.h` files are explicitly treated as C (rather than C++).
  - `*.mk` files (like `config.mk`) are treated as Makefiles.

---

### 2. `tasks.json` — Integrated Build and Workflow Tasks

All tasks automatically use `mingw32-make` on Windows and `make` on Linux/macOS. On Windows, the task runner prepends `C:\msys64\ucrt64\bin;C:\msys64\usr\bin` to `PATH`, ensuring builds succeed even if MSYS2 was not added to the system PATH.

#### Available Tasks (`Terminal > Run Task...`):

1. **`Build`** *(Default Build Task — `Ctrl + Shift + B`)*:
   Builds the project in debug mode (`make`).
2. **`Build Release`**:
   Builds an optimized release binary (`make release`).
3. **`Run`**:
   Builds and executes the binary (`make run`).
4. **`Test`** *(Default Test Task)*:
   Builds and executes all unit test suites in `tests/` (`make test`).
5. **`Clean`**:
   Deletes the `build/` directory (`make clean`).
6. **`Rebuild`**:
   Executes a clean followed by a full rebuild (`make rebuild`).
7. **`Format`**:
   Formats all project sources and headers with `clang-format` (`make format`).
8. **`Tidy`**:
   Executes static analysis across all files with `clang-tidy` (`make tidy`).
9. **`Configure`** *(Auto-run on Folder Open)*:
   Silently runs `make info` when VS Code opens the workspace, generating `compile_commands.json` immediately so clangd is active before your first manual build.

All compilation tasks use the `$gcc` problem matcher so errors and warnings appear directly in the **Problems** tab with clickable links to line numbers.

---

### 3. `launch.json` — Interactive Debugging

Pressing **F5** automatically runs the `Build` task and attaches the debugger to `build/debug/bin/<PROJECT>[.exe]`.

#### Configurations Provided:

1. **`Debug`**:
   - Primary debug target.
   - Runs within the VS Code integrated Debug Console.
   - Enables GDB pretty-printing (`-enable-pretty-printing`) for inspecting complex structs, strings, and arrays.
   - On macOS, automatically selects `lldb`. On Windows, targets `C:/msys64/ucrt64/bin/gdb.exe`.
2. **`Debug (external console)`**:
   - Launches your program in a standalone terminal window (`externalConsole: true`).
   - **Essential for programs reading user input (`stdin`)**: VS Code's integrated debug console cannot forward keyboard input to programs using `scanf`, `getchar`, or `fgets` on Windows. Use this configuration whenever debugging interactive CLI applications.

---

### 4. `extensions.json` — Recommended Extensions

When you open this project in VS Code, you will be prompted to install:
- **`llvm-vs-code-extensions.vscode-clangd`**: High-performance C/C++ language server.
- **`ms-vscode.cpptools`**: Microsoft C/C++ extension (used exclusively as the debug adapter for GDB/LLDB).
- **`ms-vscode.makefile-tools`**: Makefile syntax highlighting and target exploration.

---

## Troubleshooting VS Code Integration

### Missing Toolchain on Windows
If GDB or Make cannot be found:
1. Ensure MSYS2 is installed at `C:\msys64`.
2. In the MSYS2 UCRT64 terminal, run:
   ```bash
   pacman -S --needed mingw-w64-ucrt-x86_64-gcc mingw-w64-ucrt-x86_64-gdb mingw-w64-ucrt-x86_64-make mingw-w64-ucrt-x86_64-clang-tools-extra
   ```
3. If your MSYS2 installation is in a custom path (e.g. `D:\msys64`), update the path in `.vscode/tasks.json` and `.vscode/launch.json`.
