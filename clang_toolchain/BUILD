alias(
    name = "hermetic_clang",
    actual = "@hermetic_clang_18_1_8//:cc_toolchain",
)

toolchain(
    name = "hermetic_clang_toolchain",
    exec_compatible_with = [
        "@platforms//os:linux",
        "@platforms//cpu:x86_64",
    ],
    target_compatible_with = [
        "@platforms//os:linux",
        "@platforms//cpu:x86_64",
    ],
    toolchain = ":hermetic_clang",
    toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
)
