load(
    "@d2l_rules_csharp//csharp/private:providers.bzl",
    "CSharpResource",
)

# Label of the csproj template for ResX compilation
_TEMPLATE = "@d2l_rules_csharp//csharp/private:rules/ResGen.csproj"

# When compiling the csproj, it will look for the embedded resources related to
# the path of the csproj on disk. Since the csproj is written by the bazel, it will
# be in the rule bin directory. If we want to get the relative path to the
# ResX files, we need to get to a junction/symlink for the source. 
#
# The junction/symlink that we are using is 4 directories up (\bazel-out\<sandbox>\bin\<name>\)
def _bazel_to_relative_path(path):
  return "../../../../%s" % (path)

def _csharp_resx_impl(ctx):
    if not ctx.attr.out:
        out = "%s.%s.resources" % (ctx.attr.name, ctx.file.src.basename[:-(len(ctx.file.src.extension)+1)])
    else:
        out = "%s.resources" % (ctx.attr.out)
    
    csproj = ctx.actions.declare_file("%s.csproj" % (ctx.attr.name))
    resource = ctx.actions.declare_file("obj/Debug/%s/%s" % (ctx.attr.target_framework, out))

    ctx.actions.expand_template(
        template = ctx.file._csproj_template,
        output = csproj,
        substitutions = {
            "{TargetFramework}": ctx.attr.target_framework,
            "{Resx}": _bazel_to_relative_path(ctx.file.src.path),
            "{ManifestResourceName}": ctx.attr.out,
        },
    )

    toolchain = ctx.toolchains["@d2l_rules_csharp//csharp/private:toolchain_type"]
    
    args = ctx.actions.args()
    args.add("build")
    args.add(csproj.path)
    
    ctx.actions.run(
        inputs = [ctx.file.src, csproj],
        outputs = [resource],
        executable = toolchain.runtime,
        arguments = [args],
        mnemonic = "CompileResX",
        progress_message = "Compiling resx file to binary",
        env = {
            "DOTNET_CLI_HOME": "/root/",
            "HOME": "/root/",
            "APPDATA": "/root/",
            "PROGRAMFILES": "/root/",
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
            doc = "The resx file.",
            mandatory = True, 
            allow_single_file = True
        ),
        "identifier": attr.string(
            doc = "The identifier of the resource.",
        ),
        "out": attr.string(
            doc = "The identifier of the resource.",
        ),
        "target_framework": attr.string(
            doc = "A target framework moniker to build.",
            default = "netcoreapp3.0",
        ),
        "_csproj_template": attr.label(
            doc = "The csproj template used in compiling a resx file.",
            default = Label(_TEMPLATE),
            allow_single_file = True,
        ),
    },
    toolchains = ["@d2l_rules_csharp//csharp/private:toolchain_type"],
)