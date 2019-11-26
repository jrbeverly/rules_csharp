load(
    "@d2l_rules_csharp//csharp/private:providers.bzl",
    "CSharpResource",
)
load("@rules_cc//cc:defs.bzl", "cc_binary")

# Label of the csproj template for ResX compilation
_TEMPLATE = "@d2l_rules_csharp//csharp/private:rules/ResGen.csproj"
_WRAPPER = "@d2l_rules_csharp//csharp/private:wrappers/resx.cc"

# When compiling the csproj, it will look for the embedded resources related to
# the path of the csproj on disk. Since the csproj is written by the bazel, it will
# be in the rule bin directory. If we want to get the relative path to the
# ResX files, we need to get to a junction/symlink for the source.
#
# The junction/symlink that we are using is 4 directories up (\bazel-out\<sandbox>\bin\<name>\)
def _bazel_to_relative_path(path):
    return "../../../../%s" % (path)

def _csharp_resx_impl(ctx):
    """_csharp_resx_impl emits actions for compiling a resx file."""
    if not ctx.attr.out:
        resource_name = ctx.attr.name
    else:
        resource_name = ctx.attr.out

    cc_binary(
        name = "%s-cc" % (ctx.attr.name),
        srcs = [_WRAPPER],
        data = [_TEMPLATE],
        deps = ["@bazel_tools//tools/cpp/runfiles"],
    )

    toolchain = ctx.toolchains["@d2l_rules_csharp//csharp/private:toolchain_type"]
    resource = ctx.actions.declare_file("obj/Debug/%s/%s.resources" % (ctx.attr.target_framework, resource_name))
    ctx.actions.run(
        inputs = [ctx.file.src, csproj],
        outputs = [resource],
        executable = toolchain.runtime,
        arguments = [],
        mnemonic = "CompileResX",
        progress_message = "Compiling resx file to binary",
        env = {
            "BAZEL_CSHARP_RESX_FRAMEWORK": ctx.attr.target_framework,
            "BAZEL_CSHARP_RESX_FILE": _bazel_to_relative_path(ctx.file.src.path),
            "BAZEL_CSHARP_RESX_MANIFEST": resource_name,
        },
    )

    files = depset(direct = [resource])
    return [
        CSharpResource(
            name = ctx.attr.name,
            result = resource,
            identifier = resource.basename if not ctx.attr.identifier else ctx.attr.identifier,
        ),
        DefaultInfo(
            files = files,
        ),
    ]

csharp_resx = rule(
    implementation = _csharp_resx_impl,
    attrs = {
        "src": attr.label(
            doc = "The XML-based resource format (.resx) file.",
            mandatory = True,
            allow_single_file = True,
        ),
        "identifier": attr.string(
            doc = "The logical name for the resource; the name that is used to load the resource. The default is the name of the rule.",
        ),
        "out": attr.string(
            doc = "Specifies the name of the output (.resources) resource file. The extension is not necessary.",
        ),
        "target_framework": attr.string(
            doc = "A target framework moniker used in building the resource file.",
            default = "netcoreapp3.0",
        ),
        "_csproj_template": attr.label(
            doc = "The csproj template used in compiling the resx file.",
            default = Label(_TEMPLATE),
            allow_single_file = True,
        ),
    },
    toolchains = ["@d2l_rules_csharp//csharp/private:toolchain_type"],
    doc = """
Compiles an XML-based resource format (.resx) file into a binary resource (.resources) file.
""",
)
