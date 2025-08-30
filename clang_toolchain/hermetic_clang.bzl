"""
Downloads pre-built LLVM binaries and Ubuntu dependencies for hermetic toolchain
"""

VERSION = "18.1.8"
URL = "https://github.com/llvm/llvm-project/releases/download/llvmorg-{version}/clang+llvm-{version}-x86_64-linux-gnu-ubuntu-18.04.tar.xz".format(version = VERSION)
UBUNTU_LIBS = [
    {
        "name": "libtinfo5",
        "url": "http://archive.ubuntu.com/ubuntu/pool/main/n/ncurses/libtinfo5_6.1-1ubuntu1_amd64.deb",
        "sha256": "450bf945387029bee91d8eea76deacb8df907a1f6641fbce388933d1fdfb5a0d",
    },
]

def _fetch_external_libs(repository_ctx):
    repository_ctx.execute(["mkdir", "-p", "lib"])
    for lib in UBUNTU_LIBS:
        repository_ctx.download(
            url = lib["url"],
            sha256 = lib["sha256"],
            output = lib["name"] + ".deb",
        )
        repository_ctx.execute([
            "bash",
            "-c",
            "ar x {name}.deb && tar -xf data.tar.* && cp -r lib/x86_64-linux-gnu/* lib/ 2>/dev/null || true".format(name = lib["name"]),
        ])
        repository_ctx.execute([
            "rm",
            "-rf",
            "control.tar.*",
            "data.tar.*",
            "debian-binary",
            lib["name"] + ".deb",
            "lib/x86_64-linux-gnu",
        ])

def _create_files(repository_ctx):
    clang_wrapper_content = repository_ctx.read(
        Label("@//:clang_toolchain/templates/clang_wrapper.sh"),
    )
    repository_ctx.file(
        "clang_wrapper.sh",
        content = clang_wrapper_content,
        executable = True,
    )

    clangpp_wrapper_content = repository_ctx.read(
        Label("@//:clang_toolchain/templates/clang++_wrapper.sh"),
    )
    repository_ctx.file(
        "clang++_wrapper.sh",
        content = clangpp_wrapper_content,
        executable = True,
    )

    build_content = repository_ctx.read(Label("@//:clang_toolchain/templates/BUILD.bazel.template"))
    repository_ctx.file(
        "BUILD",
        content = build_content,
    )

def _update_templates(repository_ctx, version):
    repo_path = str(repository_ctx.path("."))
    clang_include_path = repo_path + "/lib/clang/18/include"

    cc_toolchain_config_content = repository_ctx.read(Label("@//:clang_toolchain/templates/cc_toolchain_config.bzl.template"))
    cc_toolchain_config_content = cc_toolchain_config_content.replace(
        "{clang_include_path}",
        clang_include_path,
    ).replace(
        "{version}",
        version,
    )
    repository_ctx.file(
        "cc_toolchain_config.bzl",
        content = cc_toolchain_config_content,
    )

def _hermetic_clang_repository_impl(repository_ctx):
    _fetch_external_libs(repository_ctx)
    version = repository_ctx.attr.version
    url = repository_ctx.attr.url

    repository_ctx.download_and_extract(
        url = url,
        stripPrefix = "clang+llvm-{version}-x86_64-linux-gnu-ubuntu-18.04".format(version = version),
    )

    _create_files(repository_ctx)
    _update_templates(repository_ctx, version)

hermetic_clang_repository = repository_rule(
    implementation = _hermetic_clang_repository_impl,
    attrs = {
        "url": attr.string(mandatory = True),
        "version": attr.string(mandatory = True),
    },
)

def _hermetic_clang_extension_impl(_module_ctx):
    clang_repo_name = "hermetic_clang_" + VERSION.replace(".", "_")

    hermetic_clang_repository(
        name = clang_repo_name,
        url = URL,
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
