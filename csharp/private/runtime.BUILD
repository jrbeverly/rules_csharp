load("@rules_cc//cc:defs.bzl", "cc_binary")
load("@d2l_rules_csharp//csharp:defs.bzl", "csharp_wrapper")

exports_files(
    glob(
        [
            "dotnet",
            "dotnet.exe",  # windows, yeesh
        ],
        allow_empty = True,
    ) + glob([
        "host/**/*",
        "shared/**/*",
    ]) +
    # csharp compiler: csc
    glob([
        "sdk/3.0.100/Roslyn/bincore/**/*",
    ]),
    visibility = ["//visibility:public"],
)

cc_binary(
    name = "dotnetw",
    srcs = [":main-cc"],
    deps = ["@bazel_tools//tools/cpp/runfiles"],
    visibility = ["//visibility:public"],
)

csharp_wrapper(
    name = "main-cc",
    src = "main.cc",
)
