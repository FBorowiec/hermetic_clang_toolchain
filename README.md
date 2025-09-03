# Hermetic `Clang` Toolchain for `Bazel`

A fully hermetic `Clang/LLVM` toolchain for `Bazel` that produces completely
self-contained, statically linked binaries with zero host system dependencies.

## Hermeticity

- **hermetic**: Produces statically linked binaries with no host dependencies
- **`clang 18.1.8`**: Uses pre-built `LLVM/Clang` compiler
- **`musl libc`**: `c/c++` standard libraries fetched from Alpine repo
- **`libstdc++ 14.2.0`**: Alpine's C++ standard library built for `musl`
- **statically linked**: All binaries are statically linked (no dynamic dependencies)

## How It Works

The toolchain achieves hermeticity through several mechanisms:

1. **Separate Library Paths**:
   - `lib/`: Contains libraries needed by Clang itself to run (`Ubuntu`/`LLVM` libraries)
   - `sysroot/`: Contains `musl`, `libstdc++` libraries used for compiling
1. **Compiler Flags**:
   - `-nostdinc` and `-nostdinc++`: Prevents using host system headers
   - `-nostdlib`: Prevents linking against host system libraries
   - `-static`: Forces static linking of all dependencies
1. **Library Stack**:
   - **C Library**: `musl` from Alpine Linux (for static linking)
   - **C++ Library**: `libstdc++` from Alpine Linux (built against `musl`)
   - **Unwinding**: `libunwind` from LLVM (for exception handling)
   - **Linker**: `LLD` from `LLVM`

## Usage

Add this to your `MODULE.bazel`:

```python
bazel_dep(name = "hermetic_clang_toolchain", version = "1.0.0")
```

Add this to your `.bazelrc`:

```bazelrc
# Disable default C++ toolchain detection
build --incompatible_enable_cc_toolchain_resolution
build --action_env=BAZEL_DO_NOT_DETECT_CPP_TOOLCHAIN=1

# Use hermetic clang toolchain
build --extra_toolchains=//clang_toolchain:hermetic_clang_toolchain
```

## Example

See the `example/` directory for a working example:

```bash
bazel build //example:simple_test

# Run the test
./bazel-bin/example/simple_test

# Verify it's hermetic (should show "not a dynamic executable")
ldd bazel-bin/example/simple_test

# Check the binary info
file bazel-bin/example/simple_test
# Output: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), statically linked
readelf -p .comment bazel-bin/example/simple_test
# String dump of section '.comment':
#  [     0]  clang version 18.1.8
#  [    16]  Linker: LLD 18.1.8
#  [    29]  GCC: (Alpine 14.2.0) 14.2.0
```

## Architecture Details

### Downloaded Components

1. **`LLVM/Clang 18.1.8`**: Pre-built compiler toolchain from `LLVM` project
   - Provides: `clang`, `clang++`, `lld`, `llvm-ar`, and other `LLVM` tools
   - Source: GitHub releases
1. **Alpine Packages**:
   - `musl-dev`: C standard library
   - `libstdc++`: C++ standard library
   - `libstdc++-dev`: C++ headers
   - Source: Alpine Linux v3.22 repository
1. **Ubuntu Packages** (for `Clang` runtime only):
   - `libtinfo5`: Terminal info library needed by `Clang`

### Build Process

1. **Compilation**: Uses `Clang` with hermetic headers from `sysroot`
1. **Linking**: Statically links all libraries (`musl`, `libstdc++`, `libunwind`)
1. **Result**: Self-contained binary with no external dependencies
