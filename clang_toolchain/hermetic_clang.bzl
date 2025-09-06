"""
Downloads pre-built LLVM binaries and Alpine Linux packages for hermetic toolchain
"""

load(":versions.bzl", "DEFAULT_VERSION", "get_toolchain_config")

def _fetch_ubuntu_packages(repository_ctx, ubuntu_packages):
    """Download Ubuntu packages needed for clang to run"""
    repository_ctx.execute(["mkdir", "-p", "lib"])

    for pkg in ubuntu_packages:
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

def _fetch_alpine_packages(repository_ctx, alpine_packages):
    repository_ctx.execute(["mkdir", "-p", "alpine-root"])
    repository_ctx.execute(["mkdir", "-p", "sysroot/lib"])
    repository_ctx.execute(["mkdir", "-p", "sysroot/include"])

    for pkg in alpine_packages:
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

def _update_templates(repository_ctx, version, clang_resource_dir):
    repo_path = str(repository_ctx.path("."))
    clang_include_path = repo_path + "/" + clang_resource_dir

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
    config = get_toolchain_config(version)

    llvm_config = config["llvm"]
    url = llvm_config["url"].format(version = llvm_config["version"])
    strip_prefix = llvm_config["strip_prefix"].format(version = llvm_config["version"])

    repository_ctx.download_and_extract(
        url = url,
        stripPrefix = strip_prefix,
    )

    _fetch_ubuntu_packages(repository_ctx, config["ubuntu"]["packages"])
    _fetch_alpine_packages(repository_ctx, config["alpine"]["packages"])

    _create_files(repository_ctx)
    _update_templates(repository_ctx, version, llvm_config["clang_resource_dir"])

hermetic_clang_repository = repository_rule(
    implementation = _hermetic_clang_repository_impl,
    attrs = {
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

def _hermetic_clang_extension_impl(module_ctx):
    requested_version = None
    for mod in module_ctx.modules:
        for use in mod.tags.use:
            version = use.version if hasattr(use, "version") else DEFAULT_VERSION
            if requested_version and requested_version != version:
                fail("Multiple different clang versions requested: {} and {}. Only one version can be used.".format(
                    requested_version,
                    version,
                ))
            requested_version = version

    if requested_version:
        hermetic_clang_repository(
            name = "hermetic_clang",
            version = requested_version,
        )

_use_tag = tag_class(
    attrs = {
        "version": attr.string(
            doc = "The LLVM/Clang version to use (e.g., '18.1.8', '19.1.5', '20.1.8')",
        ),
    },
)

hermetic_clang_extension = module_extension(
    implementation = _hermetic_clang_extension_impl,
    tag_classes = {"use": _use_tag},
)

