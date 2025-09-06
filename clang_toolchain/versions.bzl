"""
Toolchain version configurations.

Each configuration specifies compatible versions of LLVM/Clang and Alpine packages.
The Alpine packages (musl, libstdc++) need to be compatible with each other but
are generally independent of the Clang version.
"""

DEFAULT_VERSION = "21.1.0"

TOOLCHAIN_VERSIONS = {
    "18.1.8": {
        "llvm": {
            "version": "18.1.8",
            "url": "https://github.com/llvm/llvm-project/releases/download/llvmorg-{version}/clang+llvm-{version}-x86_64-linux-gnu-ubuntu-18.04.tar.xz",
            "strip_prefix": "clang+llvm-{version}-x86_64-linux-gnu-ubuntu-18.04",
            "clang_resource_dir": "lib/clang/18/include",  # Path to builtin headers
        },
        "alpine": {
            "version": "v3.22",
            "packages": [
                {
                    "name": "musl-dev",
                    "version": "1.2.5-r10",
                    "url": "https://dl-cdn.alpinelinux.org/alpine/v3.22/main/x86_64/musl-dev-1.2.5-r10.apk",
                },
                {
                    "name": "libstdc++",
                    "version": "14.2.0-r6",
                    "url": "https://dl-cdn.alpinelinux.org/alpine/v3.22/main/x86_64/libstdc++-14.2.0-r6.apk",
                },
                {
                    "name": "libstdc++-dev",
                    "version": "14.2.0-r6",
                    "url": "https://dl-cdn.alpinelinux.org/alpine/v3.22/main/x86_64/libstdc++-dev-14.2.0-r6.apk",
                },
            ],
        },
        "ubuntu": {
            "packages": [
                {
                    "name": "libtinfo5",
                    "url": "http://archive.ubuntu.com/ubuntu/pool/universe/n/ncurses/libtinfo5_6.3-2ubuntu0.1_amd64.deb",
                    "sha256": "ab89265d8dd18bda6a29d7c796367d6d9f22a39a8fa83589577321e7caf3857b",
                },
            ],
        },
    },
    "17.0.6": {
        "llvm": {
            "version": "17.0.6",
            "url": "https://github.com/llvm/llvm-project/releases/download/llvmorg-{version}/clang+llvm-{version}-x86_64-linux-gnu-ubuntu-22.04.tar.xz",
            "strip_prefix": "clang+llvm-{version}-x86_64-linux-gnu-ubuntu-22.04",
            "clang_resource_dir": "lib/clang/17/include",  # Path to builtin headers
        },
        "alpine": {
            "version": "v3.22",
            "packages": [
                {
                    "name": "musl-dev",
                    "version": "1.2.5-r10",
                    "url": "https://dl-cdn.alpinelinux.org/alpine/v3.22/main/x86_64/musl-dev-1.2.5-r10.apk",
                },
                {
                    "name": "libstdc++",
                    "version": "14.2.0-r6",
                    "url": "https://dl-cdn.alpinelinux.org/alpine/v3.22/main/x86_64/libstdc++-14.2.0-r6.apk",
                },
                {
                    "name": "libstdc++-dev",
                    "version": "14.2.0-r6",
                    "url": "https://dl-cdn.alpinelinux.org/alpine/v3.22/main/x86_64/libstdc++-dev-14.2.0-r6.apk",
                },
            ],
        },
        "ubuntu": {
            "packages": [
                {
                    "name": "libtinfo5",
                    "url": "http://archive.ubuntu.com/ubuntu/pool/universe/n/ncurses/libtinfo5_6.3-2ubuntu0.1_amd64.deb",
                    "sha256": "ab89265d8dd18bda6a29d7c796367d6d9f22a39a8fa83589577321e7caf3857b",
                },
            ],
        },
    },
    "19.1.7": {
        "llvm": {
            "version": "19.1.7",
            "url": "https://github.com/llvm/llvm-project/releases/download/llvmorg-{version}/LLVM-{version}-Linux-X64.tar.xz",
            "strip_prefix": "LLVM-{version}-Linux-X64",
            "clang_resource_dir": "lib/clang/19/include",  # Path to builtin headers
        },
        "alpine": {
            "version": "v3.22",
            "packages": [
                {
                    "name": "musl-dev",
                    "version": "1.2.5-r10",
                    "url": "https://dl-cdn.alpinelinux.org/alpine/v3.22/main/x86_64/musl-dev-1.2.5-r10.apk",
                },
                {
                    "name": "libstdc++",
                    "version": "14.2.0-r6",
                    "url": "https://dl-cdn.alpinelinux.org/alpine/v3.22/main/x86_64/libstdc++-14.2.0-r6.apk",
                },
                {
                    "name": "libstdc++-dev",
                    "version": "14.2.0-r6",
                    "url": "https://dl-cdn.alpinelinux.org/alpine/v3.22/main/x86_64/libstdc++-dev-14.2.0-r6.apk",
                },
            ],
        },
        "ubuntu": {
            "packages": [
                {
                    "name": "libtinfo5",
                    "url": "http://archive.ubuntu.com/ubuntu/pool/universe/n/ncurses/libtinfo5_6.3-2ubuntu0.1_amd64.deb",
                    "sha256": "ab89265d8dd18bda6a29d7c796367d6d9f22a39a8fa83589577321e7caf3857b",
                },
            ],
        },
    },
    "20.1.8": {
        "llvm": {
            "version": "20.1.8",
            "url": "https://github.com/llvm/llvm-project/releases/download/llvmorg-{version}/LLVM-{version}-Linux-X64.tar.xz",
            "strip_prefix": "LLVM-{version}-Linux-X64",
            "clang_resource_dir": "lib/clang/20/include",  # Path to builtin headers
        },
        "alpine": {
            "version": "v3.22",
            "packages": [
                {
                    "name": "musl-dev",
                    "version": "1.2.5-r10",
                    "url": "https://dl-cdn.alpinelinux.org/alpine/v3.22/main/x86_64/musl-dev-1.2.5-r10.apk",
                },
                {
                    "name": "libstdc++",
                    "version": "14.2.0-r6",
                    "url": "https://dl-cdn.alpinelinux.org/alpine/v3.22/main/x86_64/libstdc++-14.2.0-r6.apk",
                },
                {
                    "name": "libstdc++-dev",
                    "version": "14.2.0-r6",
                    "url": "https://dl-cdn.alpinelinux.org/alpine/v3.22/main/x86_64/libstdc++-dev-14.2.0-r6.apk",
                },
            ],
        },
        "ubuntu": {
            "packages": [
                {
                    "name": "libtinfo5",
                    "url": "http://archive.ubuntu.com/ubuntu/pool/universe/n/ncurses/libtinfo5_6.3-2ubuntu0.1_amd64.deb",
                    "sha256": "ab89265d8dd18bda6a29d7c796367d6d9f22a39a8fa83589577321e7caf3857b",
                },
            ],
        },
    },
    "21.1.0": {
        "llvm": {
            "version": "21.1.0",
            "url": "https://github.com/llvm/llvm-project/releases/download/llvmorg-{version}/LLVM-{version}-Linux-X64.tar.xz",
            "strip_prefix": "LLVM-{version}-Linux-X64",
            "clang_resource_dir": "lib/clang/21/include",  # Path to builtin headers
        },
        "alpine": {
            "version": "v3.22",
            "packages": [
                {
                    "name": "musl-dev",
                    "version": "1.2.5-r10",
                    "url": "https://dl-cdn.alpinelinux.org/alpine/v3.22/main/x86_64/musl-dev-1.2.5-r10.apk",
                },
                {
                    "name": "libstdc++",
                    "version": "14.2.0-r6",
                    "url": "https://dl-cdn.alpinelinux.org/alpine/v3.22/main/x86_64/libstdc++-14.2.0-r6.apk",
                },
                {
                    "name": "libstdc++-dev",
                    "version": "14.2.0-r6",
                    "url": "https://dl-cdn.alpinelinux.org/alpine/v3.22/main/x86_64/libstdc++-dev-14.2.0-r6.apk",
                },
            ],
        },
        "ubuntu": {
            "packages": [
                {
                    "name": "libtinfo5",
                    "url": "http://archive.ubuntu.com/ubuntu/pool/universe/n/ncurses/libtinfo5_6.3-2ubuntu0.1_amd64.deb",
                    "sha256": "ab89265d8dd18bda6a29d7c796367d6d9f22a39a8fa83589577321e7caf3857b",
                },
            ],
        },
    },
}

def get_toolchain_config(version):
    if version not in TOOLCHAIN_VERSIONS:
        fail("Unsupported version: {}\nAvailable versions: {}".format(version, ", ".join(TOOLCHAIN_VERSIONS.keys())))
    return TOOLCHAIN_VERSIONS[version]
