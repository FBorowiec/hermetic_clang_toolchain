"""
Downloads pre-built LLVM binaries and Ubuntu dependencies for hermetic toolchain
"""

def _hermetic_clang_repository_impl(repository_ctx):
    version = repository_ctx.attr.version
    url = repository_ctx.attr.url

    repository_ctx.download_and_extract(
        url = url,
        stripPrefix = "clang+llvm-{version}-x86_64-linux-gnu-ubuntu-18.04".format(version = version),
    )

    ubuntu_libs = [
        {
            "name": "libtinfo5",
            "url": "http://archive.ubuntu.com/ubuntu/pool/main/n/ncurses/libtinfo5_6.1-1ubuntu1_amd64.deb",
            "sha256": "450bf945387029bee91d8eea76deacb8df907a1f6641fbce388933d1fdfb5a0d",
        },
    ]

    repository_ctx.execute(["mkdir", "-p", "lib"])
    for lib in ubuntu_libs:
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
        repository_ctx.execute(["rm", "-rf", "control.tar.*", "data.tar.*", "debian-binary", lib["name"] + ".deb", "lib/x86_64-linux-gnu"])

    repository_ctx.file(
        "clang_wrapper.sh",
        content = '''#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
export LD_LIBRARY_PATH="$SCRIPT_DIR/lib:$LD_LIBRARY_PATH"

# Check if this is a linking command by looking for -o flag and .o files
if [[ "$*" == *"-o"* ]] && [[ "$*" == *".o"* ]]; then
    # Use clang for linking with lld
    exec "$SCRIPT_DIR/bin/clang" -fuse-ld=lld "$@"
else
    # Regular compilation
    exec "$SCRIPT_DIR/bin/clang" "$@"
fi
''',
        executable = True,
    )

    repository_ctx.file(
        "clang++_wrapper.sh",
        content = '''#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
export LD_LIBRARY_PATH="$SCRIPT_DIR/lib:$LD_LIBRARY_PATH"
exec "$SCRIPT_DIR/bin/clang++" "$@"
''',
        executable = True,
    )

    repository_ctx.file(
        "BUILD",
        content = '''
package(default_visibility = ["//visibility:public"])

load(":cc_toolchain_config.bzl", "cc_toolchain_config")

cc_toolchain_config(
    name = "cc_toolchain_config",
)

cc_toolchain(
    name = "cc_toolchain",
    all_files = ":all_files",
    ar_files = ":ar_files",
    as_files = ":compiler_files", 
    compiler_files = ":compiler_files",
    dwp_files = ":empty",
    linker_files = ":linker_files",
    objcopy_files = ":objcopy_files",
    strip_files = ":strip_files",
    supports_param_files = 1,
    toolchain_config = ":cc_toolchain_config",
    toolchain_identifier = "hermetic-clang",
)

filegroup(
    name = "compiler_files",
    srcs = [
        "clang_wrapper.sh",
        "clang++_wrapper.sh",
        "bin/clang",
        "bin/clang++",
    ] + glob([
        "lib/clang/**/*",
        "include/**/*",
        "lib/**/*.so*",
    ]),
)

filegroup(
    name = "linker_files", 
    srcs = [
        "clang_wrapper.sh",
        "bin/ld.lld",
        "bin/lld", 
        "bin/clang",
        "bin/clang++",
    ] + glob([
        "lib/**/*.so*",
        "lib/**/*.a",
    ]),
)

filegroup(
    name = "ar_files",
    srcs = ["bin/llvm-ar"],
)

filegroup(
    name = "objcopy_files",
    srcs = ["bin/llvm-objcopy"],
)

filegroup(
    name = "strip_files",
    srcs = ["bin/llvm-strip"],
)

filegroup(
    name = "all_files",
    srcs = [
        ":compiler_files",
        ":linker_files", 
        ":ar_files",
        ":objcopy_files",
        ":strip_files",
    ],
)

filegroup(
    name = "empty",
    srcs = [],
)
'''.format(version = version),
    )

    # Get the repository path dynamically for the toolchain config
    repo_path = str(repository_ctx.path("."))
    clang_include_path = repo_path + "/lib/clang/18/include"

    # Create toolchain configuration for pre-built binaries
    repository_ctx.file(
        "cc_toolchain_config.bzl",
        content = '''
load("@bazel_tools//tools/cpp:cc_toolchain_config_lib.bzl", "feature", "flag_group", "flag_set", "tool_path", "variable_with_value")
load("@bazel_tools//tools/build_defs/cc:action_names.bzl", "ACTION_NAMES")

def _impl(ctx):
    # Use pre-built hermetic tools with wrappers
    tool_paths = [
        tool_path(
            name = "gcc",
            path = "clang_wrapper.sh",
        ),
        tool_path(
            name = "ld",
            path = "clang_wrapper.sh",
        ),
        tool_path(
            name = "ar", 
            path = "bin/llvm-ar",
        ),
        tool_path(
            name = "cpp",
            path = "clang++_wrapper.sh",
        ),
        tool_path(
            name = "gcov",
            path = "bin/llvm-cov",
        ),
        tool_path(
            name = "nm",
            path = "bin/llvm-nm",
        ),
        tool_path(
            name = "objdump",
            path = "bin/llvm-objdump",
        ),
        tool_path(
            name = "strip",
            path = "bin/llvm-strip",
        ),
    ]

    cxx_builtin_include_directories = [
        "{clang_include_path}",
        "/usr/include",
        "/usr/include/c++/13", 
        "/usr/include/x86_64-linux-gnu/c++/13", 
        "/usr/include/x86_64-linux-gnu",
        "/usr/local/include",
    ]

    features = [
        feature(
            name = "default_compile_flags",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = [
                        ACTION_NAMES.assemble,
                        ACTION_NAMES.preprocess_assemble,
                        ACTION_NAMES.linkstamp_compile,
                        ACTION_NAMES.c_compile,
                        ACTION_NAMES.cpp_compile,
                        ACTION_NAMES.cpp_header_parsing,
                        ACTION_NAMES.cpp_module_compile,
                        ACTION_NAMES.cpp_module_codegen,
                        ACTION_NAMES.lto_backend,
                        ACTION_NAMES.clif_match,
                    ],
                    flag_groups = [
                        flag_group(
                            flags = [
                                "-fstack-protector",
                                "-Wall",
                                "-Wunused-but-set-parameter",
                                "-Wno-free-nonheap-object",
                                "-fcolor-diagnostics",
                                "-fno-omit-frame-pointer",
                            ],
                        ),
                    ],
                ),
            ],
        ),
        feature(
            name = "default_link_flags",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = [
                        ACTION_NAMES.cpp_link_executable,
                        ACTION_NAMES.cpp_link_dynamic_library,
                        ACTION_NAMES.cpp_link_nodeps_dynamic_library,
                    ],
                    flag_groups = [
                        flag_group(
                            flags = [
                                "-lstdc++",
                                "-lm",
                            ],
                        ),
                    ],
                ),
            ],
        ),
    ]

    return cc_common.create_cc_toolchain_config_info(
        ctx = ctx,
        features = features,
        cxx_builtin_include_directories = cxx_builtin_include_directories,
        toolchain_identifier = "hermetic-clang-{version}",
        host_system_name = "local",
        target_system_name = "local", 
        target_cpu = "k8",
        target_libc = "unknown",
        compiler = "clang",
        abi_version = "unknown",
        abi_libc_version = "unknown", 
        tool_paths = tool_paths,
    )

cc_toolchain_config = rule(
    implementation = _impl,
    attrs = {{}},
    provides = [CcToolchainConfigInfo],
)
'''.format(clang_include_path = clang_include_path, version = version),
    )

hermetic_clang_repository = repository_rule(
    implementation = _hermetic_clang_repository_impl,
    attrs = {
        "url": attr.string(mandatory = True),
        "version": attr.string(mandatory = True),
    },
)

def _hermetic_clang_extension_impl(_module_ctx):
    version = "18.1.8"
    url = "https://github.com/llvm/llvm-project/releases/download/llvmorg-{version}/clang+llvm-{version}-x86_64-linux-gnu-ubuntu-18.04.tar.xz".format(version = version)
    clang_repo_name = "hermetic_clang_" + version.replace(".", "_")

    hermetic_clang_repository(
        name = clang_repo_name,
        url = url,
        version = version,
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
