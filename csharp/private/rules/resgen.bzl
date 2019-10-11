# Label of the template file to use.
_TEMPLATE = "@d2l_rules_csharp//csharp/private:rules/Template.csproj"
_TEMPLATE_EMBEDDED_RESOURCE = "        <EmbeddedResource Include=\"%s\" />"

# When we are running in the execution directory
def _relative_to_ref(path):
  # Path to execroot (where shell is running) \execroot\__main__
  # Fixed path for the item itself \bazel-out\x64_windows-fastbuild\bin\resgen\
  #
  # In the execroot/__main__ dir, a symlink to the `workspace` directory is
  # available. As long as the fixed path remains constant, this should
  # correctly link to the resx file locations
  return "../../../../%s" % (path)

def _csproj_embedded_resource(resx_files):
    result = ""
    for src in resx_files:
        result += _TEMPLATE_EMBEDDED_RESOURCE % (_relative_to_ref(src.path))
    return result

def _csharp_resx_impl(ctx):
    csproj_output = ctx.actions.declare_file("%s.csproj" % (ctx.attr.name))
    embedded_resources = _csproj_embedded_resource(ctx.files.srcs)
    ctx.actions.expand_template(
        template = ctx.file._template,
        output = csproj_output,
        substitutions = {
            "{FRAMEWORK}": ctx.attr.target_frameworks[0],
            "{RESOURCES}": embedded_resources,
        },
    )

    # Capturing the outputs from this.
    out_resources = []
    for src in ctx.files.srcs:
        out_r1 = ctx.actions.declare_file("obj/Debug/net472/%s.%s.resources" % (ctx.attr.name, src.basename[:-(len(src.extension)+1)]))
        out_resources.append(out_r1)
    
    ctx.actions.run(
        inputs = ctx.files.srcs + [csproj_output],
        outputs = out_resources,
        executable = "C:/Users/jbeverly/Repositories/bazel/diff/dotnet-sdk-3.0.100-win-x64/dotnet.exe",
        arguments = ["build", csproj_output.path.replace("/", "\\")],
        mnemonic = "BuildResXProject",
        progress_message = "Compiling resx files",
        env = {
            "DOTNET_CLI_HOME": "C:\\Users\\jbeverly\\bazel\\dotnet",
            "HOME": "/c/Users/jbeverly",
            "APPDATA": "C:\\Users\\jbeverly\\AppData\\Roaming",
            "PROGRAMFILES": "C:\\Program Files",
        },
    )
    files = depset(direct = out_resources)
    runfiles = ctx.runfiles(files = out_resources)
    return [DefaultInfo(files = files, runfiles = runfiles)]

csharp_resx = rule(
    implementation = _csharp_resx_impl,
    attrs = {
        "srcs": attr.label_list(
            mandatory = True, 
            allow_files = True
        ),
        "target_frameworks": attr.string_list(
            doc = "A list of target framework monikers to build" +
                  "See https://docs.microsoft.com/en-us/dotnet/standard/frameworks",
            allow_empty = False,
        ),
        "_template": attr.label(
            default = Label(_TEMPLATE),
            allow_single_file = True,
        ),
    },
)
