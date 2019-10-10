# When we are running in the execution directory
def _relative_to_ref(path):
  # Path to execroot (where shell is running) \execroot\__main__
  # Fixed path for the item itself \bazel-out\x64_windows-fastbuild\bin\resgen\
  #
  # In the execroot/__main__ dir, a symlink to the `workspace` directory is
  # available. As long as the fixed path remains constant, this should
  # correctly link to the resx file locations
  return "../../../../%s" % (path)

def _format_compile_arg(file):
    return "/compile %s" % (file.path)

def _csharp_resx_impl(ctx):
    resource = ctx.actions.declare_file(
        "%s.resources" % 
        (
            ctx.file.src.basename[:-(len(ctx.file.src.extension)+1)],
        ))

    ctx.actions.run(
        inputs = [ctx.file.src],
        outputs = [resource],
        executable = ctx.attr._custom_resx_tool,
        arguments = [ctx.file.src.path, resource.path],
        mnemonic = "CSharpResXCompile",
        progress_message = "Compiling resx files",
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
        ),
        "_custom_resx_tool": attr.string(
            default = "resgen.exe"
        ),
    },
)
