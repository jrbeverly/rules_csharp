load(
    "@d2l_rules_csharp//csharp:defs.bzl",
    "csharp_binary",
    "csharp_resx"
)

# bazel run //examples:hello
csharp_binary(
    name = "hello",
    srcs = ["hello.cs", "Strings.Designer.cs"],
    resources = [":hello.strings"],
    target_frameworks = ["net472"],
    deps = ["@net//:System.Linq"],
)

csharp_resx(
    name = "hello.strings",
    src = "Strings.resx",
    target_framework = "net472",
)