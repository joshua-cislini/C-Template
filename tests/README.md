# `tests/` — Unit Testing System

This directory contains standalone unit test suites and test helper utilities.

The template includes a fast, modular test runner invoked with:
```bash
make test
```

---

## How It Works

1. **Automated Test Suite Discovery**:
   - Every file matching `tests/test_*.c` (e.g., `test_greeting.c`, `test_parser.c`) is automatically recognized as an independent test suite.
   - Each test file is compiled into its own isolated executable:
     ```text
     build/<mode>/bin/test_<name>[.exe]
     ```

2. **Clean Separation from `main.c`**:
   - The test executables link against all project source files in `src/` **except** `src/main.c` (`MAIN_SRC`).
   - This ensures each test suite can define its own `int main(void)` without symbol collision.

3. **Test Support / Helper Files**:
   - Any `.c` file inside `tests/` that does **not** match `test_*.c` (for example, `tests/mock_server.c` or `tests/fixtures.c`) is treated as shared test support code.
   - Support code is compiled into object files and automatically linked into **every** test executable.

4. **Runtime Library Access**:
   - Test binaries are placed in `build/<mode>/bin/`, directly beside copied runtime shared libraries (`.dll`, `.so`, `.dylib`).
   - Tests execute with complete access to dynamic dependencies without special environment variables.

5. **Execution and Exit Codes**:
   - `make test` runs each test executable in sequence.
   - If any test assertion fails, the test binary returns a non-zero exit code (`1`), which causes `make test` to fail immediately and trigger an error in CI.

---

## The Built-in Test Framework (`tests/test_framework.h`)

The template includes a minimal, zero-dependency, header-only testing helper designed for fast turnaround and clear diagnostics.

### Available Assertion Macros

| Macro | Description | Failure Behavior |
|---|---|---|
| `CHECK(cond)` | Verifies that boolean expression `cond` is true. | Prints filename, line number, and expression text. |
| `CHECK_EQ_INT(expected, actual)` | Compares two integer expressions (`long long`). | Prints expected vs. actual values on mismatch. |
| `CHECK_EQ_STR(expected, actual)` | Compares two C strings (`const char *`). | NULL-safe: handles `NULL` strings cleanly without segfaults. |

### Test Runner & Reporting Macros

| Macro | Description |
|---|---|
| `RUN_TEST(fn)` | Executes a `void fn(void)` test function, tracking failures and printing `PASS <fn>` or `FAIL <fn>`. |
| `TEST_REPORT()` | Flushes stdout, prints the total test and check counts, and returns `0` on success or `1` on failure. |

---

## Writing a New Test Suite

Creating a new test suite takes just three steps:

### 1. Create `tests/test_<name>.c`
For example, `tests/test_calculator.c`:

```c
#include "calculator.h"
#include "test_framework.h"

static void test_addition(void) {
    CHECK(add(2, 2) == 4);
    CHECK_EQ_INT(10, add(7, 3));
}

static void test_division_by_zero(void) {
    CHECK_EQ_INT(-1, divide(10, 0));
}

int main(void) {
    RUN_TEST(test_addition);
    RUN_TEST(test_division_by_zero);
    return TEST_REPORT();
}
```

### 2. Run the Tests
```bash
make test
```

### 3. Output
The runner displays cleanly formatted output:
```text
  CC     tests/test_calculator.c
  LINK   build/debug/bin/test_calculator.exe
  TEST   test_calculator
  PASS  test_addition
  PASS  test_division_by_zero
  2/2 tests passed (3 checks, 0 failed)
All tests passed: test_calculator test_greeting
```

---

## Running Individual Test Suites

You can build and run a specific test suite using its target name:
```bash
# Run only test_greeting
make run-test_greeting

# Run only test_calculator
make run-test_calculator
```

---

## Using Alternative Test Frameworks

`test_framework.h` is intentionally lightweight and zero-dependency. If your project requires advanced features like mocking, test fixtures, or JUnit XML output, you can easily use:
- **[Unity](http://www.throwtheswitch.org/unity)**: Drop `unity.c` and `unity.h` into `tests/`.
- **[cmocka](https://cmocka.org/)**: Drop headers into `include/` and compiled library into `lib/`.
- **[greatest](https://github.com/silentbicycle/greatest)**: Header-only unit testing.
- **[Criterion](https://github.com/Snaipe/Criterion)**: Advanced testing with sandboxing.
