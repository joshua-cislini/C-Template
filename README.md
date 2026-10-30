# C Multi-File Project Template

A ready-to-use **Visual Studio Code** C development environment for **Windows**, using **MSYS2 UCRT64**, **GCC**, **GNU Make**, **GDB**.

The template provides:

- GCC as the C compiler.
- GNU ld as the linker.
- clangd for autocomplete, diagnostics, syntax highlighting, and code navigation.
- Clang-Format for automatic code formatting.
- GNU Make for building and managing the project.
- GDB for debugging.
- Automatic DLL copying.
- Multi-file compilation with automatic header dependency tracking.

---

# 1. Project Structure

```text
MyProject/
│
├── Makefile
├── README.md
├── compile_flags.txt
├── .clang-format
│
├── src/
│   ├── main.c
│   ├── test.c
│   └── ...
│
├── include/
│   ├── test.h
│   └── ...
│
├── lib/
│   └── (static and import libraries)
│
├── dll/
│   └── (runtime DLL files)
│
├── build/
│   ├── program.exe
│   └── obj/
│       ├── main.o
│       ├── main.d
│       ├── test.o
│       └── test.d
│
└── .vscode/
    ├── settings.json
    ├── tasks.json
    ├── launch.json
    └── extensions.json
```

### Directories

| Directory | Purpose |
|---|---|
| `src/` | C source files |
| `include/` | Project header files |
| `lib/` | Static and import libraries (`.a`, `.dll.a`) |
| `dll/` | Runtime DLL files |
| `build/` | Compiled executable |
| `build/obj/` | Object and dependency files |
| `.vscode/` | VS Code configuration |

The `build/` directory is generated automatically.

---

# 2. Installing MSYS2

Download MSYS2 from:

https://www.msys2.org/

Install it using the default installation directory:

```text
C:\msys64
```

If you choose another location, update the paths in the VS Code configuration files accordingly.

## Update MSYS2

Open the MSYS2 terminal and execute:

```bash
pacman -Syu
```

If the terminal asks you to close, do so, reopen MSYS2 and run the command again until all updates are complete.

## Install the UCRT64 toolchain

Open the **MSYS2 UCRT64** terminal from the Windows Start menu.

Install the compiler, debugger, build tools, and LLVM utilities:

```bash
pacman -S --needed \
    mingw-w64-ucrt-x86_64-gcc \
    mingw-w64-ucrt-x86_64-gdb \
    mingw-w64-ucrt-x86_64-make \
    mingw-w64-ucrt-x86_64-clang \
    mingw-w64-ucrt-x86_64-clang-tools-extra
```

This provides:

| Package | Purpose |
|---|---|
| GCC | C compiler |
| GNU ld | Linker |
| GDB | Debugger |
| GNU Make | Build system |
| clangd | Language server |
| Clang-Format | Code formatting |
| Clang-Tidy | Static analysis |

The tools are installed in:

```text
C:\msys64\ucrt64\bin
```

## Verify the installation

In the UCRT64 terminal, execute:

```bash
gcc --version
gdb --version
mingw32-make --version
clangd --version
clang-format --version
```

All commands should return version information.

---

# 3. Installing Visual Studio Code

Download VS Code:

https://code.visualstudio.com/

Install these extensions:

| Extension | Identifier | Purpose |
|---|---|---|
| clangd | `llvm-vs-code-extensions.vscode-clangd` | IntelliSense and language support |
| C/C++ | `ms-vscode.cpptools` | GDB debugging integration |

The C/C++ extension is used for debugging. clangd remains responsible for code intelligence.

---

# 4. Compiler Configuration

The project uses **GCC**, not Clang.

The compiler is located at:

```text
C:\msys64\ucrt64\bin\gcc.exe
```

The linker is GNU ld, which GCC invokes automatically.

The project targets 64-bit Windows using the MinGW-w64 toolchain.

---

# 5. Makefile

The Makefile handles compilation, linking, execution, and cleaning.

It automatically:

- Finds all `.c` files in `src/`.
- Creates the required build directories.
- Compiles source files separately.
- Tracks header dependencies.
- Links all object files.
- Copies DLL files from `dll/` into `build/`.

The Makefile uses MSYS2 Bash for its Unix-style commands.

## Available targets

| Command | Action |
|---|---|
| `mingw32-make` | Build the project |
| `mingw32-make run` | Build and run |
| `mingw32-make clean` | Delete build files |
| `mingw32-make rebuild` | Clean and build again |

## Adding external libraries

To use an external library:

1. Place its headers in `include/` or another appropriate directory.
2. Place its static or import library in `lib/`.
3. Place required runtime DLLs in `dll/`.

Then configure the Makefile:

```makefile
CPPFLAGS += -Iinclude
LDFLAGS += -Llib
LDLIBS += -lname
```

Replace `name` with the actual library name.

For example, a library named `example` would generally use:

```makefile
LDLIBS += -lexample
```

Its runtime DLL, if required, should be placed in `dll/`.

---

# 6. VS Code Build Configuration

The VS Code tasks are defined in:

```text
.vscode/tasks.json
```

The default build shortcut is:

**Ctrl + Shift + B**

It executes the Build task, which calls:

```bash
mingw32-make -j4
```

The Make executable is located at:

```text
C:\msys64\ucrt64\bin\mingw32-make.exe
```

The task adds the UCRT64 and MSYS2 directories to PATH so the compiler and shell utilities can be found.

---

# 7. Running and Debugging

The debugger configuration is defined in:

```text
.vscode/launch.json
```

The executable is:

```text
build/program.exe
```

The debugger is:

```text
C:\msys64\ucrt64\bin\gdb.exe
```

## Keyboard shortcuts

| Shortcut | Action |
|---|---|
| `Ctrl + Shift + B` | Build |
| `Ctrl + F5` | Build and run without debugging |
| `F5` | Build and start debugging |
| `F10` | Step over |
| `F11` | Step into |
| `Shift + F11` | Step out |
| `Shift + F5` | Stop debugging |

Both running configurations execute the Build task first, ensuring that the executable is up to date.

Program output is displayed in VS Code's integrated terminal.

## Breakpoints

Click next to a line number to create a breakpoint.

When debugging, you can inspect:

- Local variables.
- Global variables.
- The call stack.
- Watch expressions.
- Memory.

---

# 8. clangd and compile_flags.txt

This project uses **clangd** for:

- Autocomplete.
- Syntax highlighting.
- Diagnostics.
- Code navigation.
- Go to definition.
- Find references.
- Header resolution.

clangd is not the compiler. It independently analyzes your source code using the compilation flags provided in `compile_flags.txt`.

The file is located in the project root.

Example:

```text
--target=x86_64-w64-windows-gnu
-std=c99
-Wall
-Wextra
-Wpedantic
-Iinclude
-Isrc
```

Whenever you add additional include directories or change important compiler flags, update this file accordingly.

---

# 9. Code Formatting

The project uses **Clang-Format**.

Formatting rules are stored in:

```text
.clang-format
```

VS Code can format code automatically when:

- Pasting code.
- Typing code.
- Saving a file.

Manual formatting:

**Shift + Alt + F**

The formatter is provided by the LLVM tooling.

---

# 10. Building Manually

Open a UCRT64 terminal in the project directory.

Build:

```bash
mingw32-make
```

Build and run:

```bash
mingw32-make run
```

Clean:

```bash
mingw32-make clean
```

Rebuild:

```bash
mingw32-make rebuild
```

Alternatively, use the VS Code shortcuts.

---

# 11. Important Notes

### Do not mix toolchains

This project uses UCRT64.

Avoid mixing precompiled libraries, object files, and runtime dependencies from incompatible MSYS2 environments, especially MINGW64 and CLANG64.

### Changing compilers

If you change compiler or important compiler flags, clean the project first:

```bash
mingw32-make clean
```

This prevents old object files from being linked with newly compiled files.

### DLL files

DLLs placed in `dll/` are automatically copied into `build/` when linking the executable.

The executable can then find those DLLs alongside itself.

### Adding source files

Simply place additional `.c` files inside `src/`.

Make automatically detects them on the next build.

### Adding headers

Place project headers inside `include/`.

Header dependencies are automatically tracked through generated `.d` files.

---

# 12. License

This project is licensed under the MIT License.

See the `LICENSE` file for the complete license text.

---

**Toolchain summary**

| Component | Tool |
|---|---|
| Compiler | GCC |
| Linker | GNU ld |
| Language server | clangd |
| Formatter | Clang-Format |
| Build system | GNU Make |
| Debugger | GDB |
| Environment | MSYS2 UCRT64 |
| Editor | Visual Studio Code |