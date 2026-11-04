# dependencies/

Drop third-party libraries here. **No Makefile edits are needed.** Every
`make` run picks them up automatically.

## Layout

Use either layout, or both at once:

```text
dependencies/
├── include/              loose headers            → -isystem dependencies/include
├── lib/                  loose libraries          → linked automatically
├── bin/                  loose runtime files      → copied next to the executable
│
└── <package>/            one folder per library (e.g. an extracted SDK)
    ├── include/
    ├── lib/
    └── bin/
```

The package layout matches the way most prebuilt libraries are shipped. For
example, from `SDL2-devel-2.x.y-mingw.zip` copy the `x86_64-w64-mingw32` folder
here, rename it to `SDL2`, and you're done.

## What goes where

| Folder     | Files                                          | What the Makefile does                                    |
|------------|------------------------------------------------|-----------------------------------------------------------|
| `include/` | `.h`                                           | Adds it as an include path (`-isystem`, so warnings in third-party headers stay hidden) |
| `lib/`     | Windows: `.a`, `.dll.a`, `.lib` · Linux: `.a`, `.so` · macOS: `.a`, `.dylib` | Adds `-L` and links every library found |
| `bin/`     | Windows: `.dll` · Linux: `.so*` · macOS: `.dylib` | Copies them into `build/<mode>/bin/` so the program finds them at run time |

Notes:

- If a library is present both as a shared/import library and as a static one
  (`libfoo.dll.a` + `libfoo.a`, or `libfoo.so` + `libfoo.a`), the shared one is
  linked. Static libraries often need extra system libraries.
- Linking uses `--start-group … --end-group`, so the library order doesn't matter.
  It also uses `--as-needed`, so unused shared libraries add no runtime dependency.
- Only the top level of each `lib/` folder is scanned. Sub-folders such as
  `lib/cmake/` and `lib/pkgconfig/` are ignored.
- Run `make info` to see exactly which include paths, libraries and runtime
  files were detected.

## When something needs manual care

Set these in `config.mk`:

| Situation | Setting |
|---|---|
| A library file must not be auto-linked (e.g. `libSDL2_test.a`) | `AUTO_LINK_EXCLUDE := libSDL2_test.a` |
| You want full control over what gets linked | `AUTO_LINK := 0` and list `-lfoo` in `LDLIBS` |
| The library needs system libraries | `LDLIBS += -lws2_32 -lgdi32 ...` (see its documentation) |
| You use the static build of a library that ships both | Delete the shared variant from `lib/`, or exclude it |
| The library is installed system-wide (apt, brew, pacman) | `PKG_CONFIG_PACKAGES := sdl2` |
| A GUI program should not open a console window (Windows) | `EXTRA_LDFLAGS := -mwindows` |

> **Toolchain compatibility (Windows):** use libraries built for MinGW-w64 /
> GCC (`.a` / `.dll.a`). Prebuilt MSVC `.lib` files work for plain C APIs, but
> MSVC static libraries usually do not. Don't mix MSYS2 environments either
> (UCRT64 vs MINGW64).
