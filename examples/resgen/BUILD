load(
    "@d2l_rules_csharp//csharp:defs.bzl",
    "csharp_binary",
    "csharp_resgen"
)

# bazel run //examples:hello
csharp_binary(
    name = "hello",
    srcs = ["hello.cs", "Strings.Designer.cs"],
    resources = ["Hello.Strings.resources"],
    target_frameworks = ["net472"],
    deps = ["@net//:System.Linq"],
)

csharp_resgen(
    name = "lib.strings",
    src = "Strings.resx"
    # target_frameworks = ["net472"],
)