"""
Downloads pre-built LLVM binaries and Alpine Linux packages for hermetic toolchain
"""

VERSION = "18.1.8"
LLVM_CLANG_URL = "https://github.com/llvm/llvm-project/releases/download/llvmorg-{version}/clang+llvm-{version}-x86_64-linux-gnu-ubuntu-18.04.tar.xz".format(version = VERSION)

# Alpine Linux packages for musl and libstdc++
ALPINE_PACKAGES = [
    {
        "name": "musl-dev",
        "url": "https://dl-cdn.alpinelinux.org/alpine/v3.22/main/x86_64/musl-dev-1.2.5-r10.apk",
    },
    {
        "name": "libstdc++",
        "url": "https://dl-cdn.alpinelinux.org/alpine/v3.22/main/x86_64/libstdc++-14.2.0-r6.apk",
    },
    {
        "name": "libstdc++-dev",
        "url": "https://dl-cdn.alpinelinux.org/alpine/v3.22/main/x86_64/libstdc++-dev-14.2.0-r6.apk",
    },
]

# Ubuntu packages needed for clang itself to run
UBUNTU_PACKAGES = [
    {
        "name": "libtinfo5",
        "url": "http://archive.ubuntu.com/ubuntu/pool/universe/n/ncurses/libtinfo5_6.3-2ubuntu0.1_amd64.deb",
        "sha256": "ab89265d8dd18bda6a29d7c796367d6d9f22a39a8fa83589577321e7caf3857b",
    },
]

def _fetch_ubuntu_packages(repository_ctx):
    """Download Ubuntu packages needed for clang to run"""
    repository_ctx.execute(["mkdir", "-p", "lib"])

    for pkg in UBUNTU_PACKAGES:
        repository_ctx.download(
            url = pkg["url"],
            sha256 = pkg["sha256"],
            output = pkg["name"] + ".deb",
        )
        repository_ctx.execute([
            "bash",
            "-c",
            "ar x {name}.deb && tar -xf data.tar.* && cp -r lib/x86_64-linux-gnu/* lib/ 2>/dev/null || true && cp -r usr/lib/x86_64-linux-gnu/* lib/ 2>/dev/null || true".format(name = pkg["name"]),
        ])
        repository_ctx.execute([
            "rm",
            "-rf",
            "control.tar.*",
            "data.tar.*",
            "debian-binary",
            pkg["name"] + ".deb",
            "lib/x86_64-linux-gnu",
            "usr",
        ])

def _fetch_alpine_packages(repository_ctx):
    repository_ctx.execute(["mkdir", "-p", "alpine-root"])
    repository_ctx.execute(["mkdir", "-p", "sysroot/lib"])
    repository_ctx.execute(["mkdir", "-p", "sysroot/include"])

    for pkg in ALPINE_PACKAGES:
        repository_ctx.download(
            url = pkg["url"],
            output = pkg["name"] + ".apk",
        )
        repository_ctx.execute([
            "tar",
            "-xzf",
            pkg["name"] + ".apk",
            "-C",
            "alpine-root",
        ])
        repository_ctx.execute(["rm", pkg["name"] + ".apk"])

    repository_ctx.execute([
        "bash",
        "-c",
        """
        # Copy musl libraries and headers to sysroot
        if [ -d alpine-root/usr/include ]; then
            cp -r alpine-root/usr/include/* sysroot/include/ 2>/dev/null || true
        fi
        if [ -d alpine-root/usr/lib ]; then
            cp -r alpine-root/usr/lib/* sysroot/lib/ 2>/dev/null || true
        fi
        if [ -d alpine-root/usr/lib/gcc ]; then
            cp -r alpine-root/usr/lib/gcc/* sysroot/lib/ 2>/dev/null || true
        fi
        # Also copy headers to include for compatibility
        if [ -d alpine-root/usr/include ]; then
            cp -r alpine-root/usr/include/* include/ 2>/dev/null || true
        fi
        # Clean up
        rm -rf alpine-root
        """,
    ])

def _create_files(repository_ctx):
    repository_ctx.execute(["mkdir", "-p", "include"])
    clang_wrapper_content = repository_ctx.read(
        repository_ctx.attr._clang_wrapper_template,
    )
    repository_ctx.file(
        "clang_wrapper.sh",
        content = clang_wrapper_content,
        executable = True,
    )

    clangpp_wrapper_content = repository_ctx.read(
        repository_ctx.attr._clangpp_wrapper_template,
    )
    repository_ctx.file(
        "clang++_wrapper.sh",
        content = clangpp_wrapper_content,
        executable = True,
    )

    build_content = repository_ctx.read(repository_ctx.attr._build_template)
    repository_ctx.file(
        "BUILD",
        content = build_content,
    )

def _update_templates(repository_ctx, version):
    repo_path = str(repository_ctx.path("."))
    clang_include_path = repo_path + "/lib/clang/18/include"

    cc_toolchain_config_content = repository_ctx.read(repository_ctx.attr._cc_toolchain_config_template)
    cc_toolchain_config_content = cc_toolchain_config_content.replace(
        "{clang_include_path}",
        clang_include_path,
    ).replace(
        "{version}",
        version,
    ).replace(
        "{repo_path}",
        repo_path,
    )
    repository_ctx.file(
        "cc_toolchain_config.bzl",
        content = cc_toolchain_config_content,
    )

def _hermetic_clang_repository_impl(repository_ctx):
    version = repository_ctx.attr.version
    url = repository_ctx.attr.url

    repository_ctx.download_and_extract(
        url = url,
        stripPrefix = "clang+llvm-{version}-x86_64-linux-gnu-ubuntu-18.04".format(version = version),
    )

    _fetch_ubuntu_packages(repository_ctx)
    _fetch_alpine_packages(repository_ctx)

    _create_files(repository_ctx)
    _update_templates(repository_ctx, version)

hermetic_clang_repository = repository_rule(
    implementation = _hermetic_clang_repository_impl,
    attrs = {
        "url": attr.string(mandatory = True),
        "version": attr.string(mandatory = True),
        "_clang_wrapper_template": attr.label(
            default = "//clang_toolchain/templates:clang_wrapper.sh",
            allow_single_file = True,
        ),
        "_clangpp_wrapper_template": attr.label(
            default = "//clang_toolchain/templates:clang++_wrapper.sh",
            allow_single_file = True,
        ),
        "_build_template": attr.label(
            default = "//clang_toolchain/templates:BUILD.bazel.template",
            allow_single_file = True,
        ),
        "_cc_toolchain_config_template": attr.label(
            default = "//clang_toolchain/templates:cc_toolchain_config.bzl.template",
            allow_single_file = True,
        ),
    },
)

def _hermetic_clang_extension_impl(_module_ctx):
    clang_repo_name = "hermetic_clang_" + VERSION.replace(".", "_")

    hermetic_clang_repository(
        name = clang_repo_name,
        url = LLVM_CLANG_URL,
        version = VERSION,
    )

hermetic_clang_extension = module_extension(
    implementation = _hermetic_clang_extension_impl,
)

def hermetic_clang_toolchain(name, version):
    clang_repo_name = "hermetic_clang_" + version.replace(".", "_")

    native.alias(
        name = name,
        actual = "@{repo}//:cc_toolchain".format(repo = clang_repo_name),
    )
