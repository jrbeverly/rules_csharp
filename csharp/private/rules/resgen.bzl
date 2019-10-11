# Label of the template file to use.
_TEMPLATE = "@d2l_rules_csharp//csharp/private:rules/Template.csproj"

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
    framework = ctx.attr.target_frameworks[0]
    csproj = ctx.actions.declare_file("%s.csproj" % (ctx.attr.name))
    ctx.actions.expand_template(
        template = ctx.file._csproj_template,
        output = csproj,
        substitutions = {
            "{FRAMEWORK}": framework,
            "{RESOURCE}": _relative_to_ref(ctx.file.src.path),
        },
    )

    # Capturing the outputs from this.
    resource = ctx.actions.declare_file("obj/Debug/%s/%s.%s.resources" % (framework, ctx.attr.name, ctx.file.src.basename[:-(len(ctx.file.src.extension)+1)]))
    
    ctx.actions.run(
        inputs = [ctx.file.src, csproj],
        outputs = [resource],
        executable = ctx.attr._dotnet_runner,
        arguments = ["build", csproj.path.replace("/", "\\")],
        mnemonic = "BuildResXProject",
        progress_message = "Compiling resx files",
        env = {
            "DOTNET_CLI_HOME": "C:\\",
            "HOME": "/c/",
            "APPDATA": "C:\\",
            "PROGRAMFILES": "C:\\",
        },
    )
    files = depset(direct = [resource])
    runfiles = ctx.runfiles(files = [resource])
    return [DefaultInfo(files = files, runfiles = runfiles)]

csharp_resx = rule(
    implementation = _csharp_resx_impl,
    attrs = {
        "src": attr.label(
            mandatory = True, 
            allow_single_file = True
        ),
        "identifier": attr.string(),
        "target_frameworks": attr.string_list(
            doc = "A list of target framework monikers to build" +
                  "See https://docs.microsoft.com/en-us/dotnet/standard/frameworks",
            allow_empty = False,
        ),
        "_csproj_template": attr.label(
            default = Label(_TEMPLATE),
            allow_single_file = True,
        ),
        "_dotnet_runner": attr.string(
            default = "dotnet.exe",
        ),
    },
)
