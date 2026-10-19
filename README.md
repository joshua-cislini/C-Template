# C Multi-File Project Template

A simple C project using **GCC**, **MinGW**, **Make**, **GDB**, **clangd**, and **Clang-Format**, designed for development in **Visual Studio Code**.

---

## Project Structure

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
├── build/
│   ├── program.exe
│   │
│   └── obj/
│       ├── main.o
│       ├── main.d
│       ├── test.o
│       └── test.d
│
└── .vscode/
    ├── settings.json
    ├── tasks.json
    └── launch.json
```

### Directories

| Directory    | Purpose                                         |
| ------------ | ----------------------------------------------- |
| `src/`       | C source files (`.c`)                           |
| `include/`   | Header files (`.h`)                             |
| `build/`     | Compiled output                                 |
| `build/obj/` | Object files (`.o`) and dependency files (`.d`) |
| `.vscode/`   | VS Code configuration                           |

### Important files

| File                | Purpose                                             |
| ------------------- | --------------------------------------------------- |
| `Makefile`          | Controls compilation, linking, running, and cleaning |
| `compile_flags.txt` | Defines include paths and flags for `clangd`       |
| `README.md`         | Project documentation                               |
| `.clang-format`     | Defines the project's C/C++ code formatting style   |
| `main.c`            | Program entry point                                 |
| `.h` files          | Function declarations and shared definitions        |
| `.c` files          | Function implementations                            |

---

# Building the Project

## Requirements

The following tools must be installed and available from the terminal:

* GCC / MinGW
* `mingw32-make`
* GDB
* Visual Studio Code
* **VS Code Extensions**:
  * `llvm-vs-code-extensions.vscode-clangd` (Language Server & Intellisense)
  * `ms-vscode.cpptools` (Required for GDB Debugging only)

---

## Build

Open a terminal in the project root:

```text
mingw32-make
```

This compiles all `.c` files in `src/` and links them into:

```text
build/program.exe
```

You can also use the VS Code build shortcut:

**`Ctrl + Shift + B`**

---

# Run

To build and run the program:

```text
mingw32-make run
```

Or run the executable directly:

```text
build/program.exe
```

---

# Debug

Press:

**`F5`**

VS Code will:

1. Run the `Build` task.
2. Compile the project using Make.
3. Start GDB.
4. Launch `build/program.exe`.
5. Allow debugging with breakpoints and stepping.

Useful debugging shortcuts:

| Key           | Action                     |
| ------------- | -------------------------- |
| `F5`          | Start / continue debugging |
| `F10`         | Step over                  |
| `F11`         | Step into                  |
| `Shift + F11` | Step out                   |
| `Shift + F5`  | Stop debugging             |

---

# Language Server (`clangd`) & `compile_flags.txt`

This project uses **`clangd`** for code navigation, autocompletion, diagnostics, and code analysis.

To ensure `clangd` knows where project headers and target architecture flags live, the project includes a **`compile_flags.txt`** file in the root directory:

```text
-std=c99
-Wall
-Wextra
-Iinclude
-Isrc
--target=x86_64-w64-mingw32
```

`clangd` automatically reads `compile_flags.txt` and uses it to resolve `#include` directives and type checks without requiring complex JSON configurations.

---

# Clean

To remove all compiled files:

```text
mingw32-make clean
```

This deletes the entire `build/` directory.

---

# Rebuild

To completely clean and rebuild the project:

```text
mingw32-make clean
mingw32-make
```

Or use the VS Code `Rebuild` task.

---

# Code Formatting

This project uses **Clang-Format** to keep the source code consistently formatted.

The formatting rules are stored in:

```text
.clang-format
```

This file is located in the **root of the project** so that the same formatting rules can be used throughout the entire project.

## VS Code formatting

VS Code uses `clangd` (via `Clang-Format`) to format C source and header files automatically when:

* pasting code
* typing code
* saving a file

The relevant settings in `.vscode/settings.json`:

```json
"editor.formatOnPaste": true,
"editor.formatOnType": true,
"editor.formatOnSave": true,
"editor.defaultFormatter": "llvm-vs-code-extensions.vscode-clangd",
"C_Cpp.intelliSenseEngine": "Disabled"
```

## Manual formatting

Use:

**`Shift + Alt + F`**

or:

1. Right-click inside the source file.
2. Select **Format Document**.

---

# License

This project is licensed under the **MIT License**.

See the [`LICENSE`](LICENSE) file for the complete license text.