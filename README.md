# Hermetic clang toolchain for `bazel`

A lightweight, hermetic Clang toolchain for `bazel` that downloads pre-built
LLVM binaries and bundles necessary system dependencies.

## Features

- fully hermetic
- lightweight - downloads pre-built binaries instead of building from source
- cross-platform - works on all linux x86_64 systems
- `clang18` - pre-built compiler binaries
- `ubuntu` lib - bundled `libtinfo5` for compatibility

## Usage

Add this to your `MODULE.bazel`:

```python
bazel_dep(name = "hermetic_clang_toolchain", version = "1.0.0")
```

## Included
