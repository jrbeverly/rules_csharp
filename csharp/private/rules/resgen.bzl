# Label of the template file to use.
_TEMPLATE = "@d2l_rules_csharp//csharp/private:rules/ResGen.csproj"
_RUNTIME_CONFIG = "@d2l_rules_csharp//csharp/private:rules/bazel.runtimeconfig.json"

# When we write the csproj to disk, it will be placed within the rules
# output directory (e.g. \bazel-out\x64_windows-fastbuild\bin\resgen\) within
# the output base of bazel (path\to\output\random\execroot\__main__\). 
#
# The compilation will look for the resgen files relative to the csproj file. The
# symlink for the workspace is located at the workspace bin (which is 4 dirs up)
# 
# As long as the bazel-out path to rule remains constant, we can jump to the workspace
# bin output. From there, we use the symlink to reference files in the workspace.
def _relative_to_ref(path):
  return "../../../../%s" % (path)

def _csharp_resx_impl(ctx):
    if not ctx.attr.out:
        out = "%s.%s.resources" % (ctx.attr.name, ctx.file.src.basename[:-(len(ctx.file.src.extension)+1)])
    else:
        out = ctx.attr.out
    csproj = ctx.actions.declare_file("%s.csproj" % (ctx.attr.name))
    ctx.actions.expand_template(
        template = ctx.file._csproj_template,
        output = csproj,
        substitutions = {
            "{FRAMEWORK}": ctx.attr.target_framework,
            "{RESOURCE}": _relative_to_ref(ctx.file.src.path),
            "{LOGICAL_NAME}": out,
        },
    )

    # Capturing the outputs from this.
    resource = ctx.actions.declare_file("obj/Debug/%s/%s" % (ctx.attr.target_framework, out))
    
    print(ctx.file._runtime_config.path)
    toolchain = ctx.toolchains["@d2l_rules_csharp//csharp/private:toolchain_type"]
    ctx.actions.run(
        inputs = [ctx.file.src, csproj],
        outputs = [resource],
        executable = toolchain.runtime,
        arguments = ["build", csproj.path.replace("/", "\\")],
        mnemonic = "BuildResXProject",
        progress_message = "Compiling resx files",
        env = {
            "DOTNET_CLI_HOME": "/root/",
            "HOME": "/root/",
            "APPDATA": "/root/",
            "PROGRAMFILES": "/root/",
        },
    )
    files = depset(direct = [resource])
    runfiles = ctx.runfiles(files = [resource])
    return [DefaultInfo(files = files, runfiles = runfiles)]

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
            default = "net472",
        ),
        "_csproj_template": attr.label(
            doc = "The csproj template used in compiling a resx file.",
            default = Label(_TEMPLATE),
            allow_single_file = True,
        ),
        "_runtime_config": attr.label(
            doc = "The csproj template used in compiling a resx file.",
            default = Label(_RUNTIME_CONFIG),
            allow_single_file = True,
        ),
    },
    toolchains = ["@d2l_rules_csharp//csharp/private:toolchain_type"],
)