# Label of the template file to use.
_TEMPLATE = "@d2l_rules_csharp//csharp/private:rules/Template.csproj"

# When we are running in the execution directory
def _relative_to_ref(path):
  # Path to execroot (where shell is running) \execroot\__main__
  # Fixed path for the item itself \bazel-out\x64_windows-fastbuild\bin\resgen\
  #
  # In the execroot/__main__ dir, a symlink to the `workspace` directory is
  # available. As long as the fixed path remains constant, this should
  # correctly link to the resx file locations
  return "../../../../%s" % (path)

def _csharp_resx_impl(ctx):
    csproj = ctx.actions.declare_file("%s.csproj" % (ctx.attr.name))
    ctx.actions.expand_template(
        template = ctx.file._csproj_template,
        output = csproj,
        substitutions = {
            "{FRAMEWORK}": ctx.attr.target_framework,
            "{RESOURCE}": _relative_to_ref(ctx.file.src.path),
        },
    )

    resource = ctx.actions.declare_file(
        "obj/%s/%s/%s.%s.resources" % 
        (
            "Debug",
            ctx.attr.target_framework,
            ctx.attr.name, 
            ctx.file.src.basename[:-(len(ctx.file.src.extension)+1)],
        ))       
    
    ctx.actions.run(
        inputs = [ctx.file.src, csproj],
        outputs = [resource],
        executable = ctx.attr._runner,
        arguments = ["build", csproj.path.replace("/", "\\")],
        mnemonic = "CSharpResXCompile",
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
        "out": attr.string(),
        "_csproj_template": attr.label(
            default = Label(_TEMPLATE),
            allow_single_file = True,
        ),
        "_runner": attr.string(
            default = "dotnet.exe"
        ),
        "target_framework": attr.string(
            default = "net472"
        )
    },
)
