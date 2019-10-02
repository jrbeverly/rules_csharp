load(
    "@d2l_rules_csharp//csharp:defs.bzl",
    "csharp_binary",
    "csharp_library",
    "csharp_resgen"
)

# bazel run //examples:hello
csharp_binary(
    name = "hello",
    srcs = ["hello.cs"],
    target_frameworks = ["net472"],
    deps = [":lib"],
)

# bazel test //examples:lib_test
csharp_library(
    name = "lib",
    srcs = ["lib.cs"],
    target_frameworks = ["net472"],
    deps = ["@net//:System.Linq"],
)

csharp_resgen(
    name = "lib.strings",
    src = "Strings.resx"
    # target_frameworks = ["net472"],
)