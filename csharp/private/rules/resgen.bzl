# Label of the template file to use.
_TEMPLATE = "@d2l_rules_csharp//csharp/private:rules/Template.csproj"
_TEMPLATE_EMBEDDED_RESOURCE = "        <EmbeddedResource Include=\"%s\" />"

def _csproj_embedded_resource(resx_files):
    result = ""
    for src in resx_files:
        result += _TEMPLATE_EMBEDDED_RESOURCE % (src.basename)
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

    ## Copying the resx files
    resx = []
    for src in ctx.files.srcs:
        resx_output = ctx.actions.declare_file("{}".format(src.basename))
        bat = ctx.actions.declare_file("%s-%s-cmd.bat" % (ctx.label.name, src.basename))
        resx.append(resx_output)
        ctx.actions.write(
            output = bat,
            content = "@copy /Y \"%s\" \"%s\" >NUL" % (
                src.path.replace("/", "\\"),
                resx_output.path.replace("/", "\\"),
            ),
            is_executable = True,
        )

        ctx.actions.run(
            inputs = [src],
            tools = [bat],
            outputs = [resx_output],
            executable = "cmd.exe",
            arguments = ["/C", bat.path.replace("/", "\\")],
            mnemonic = "CopyFile",
            progress_message = "Copying files",
            use_default_shell_env = True,
        )


    # Capturing the outputs from this.
    out_resources = []
    for src in ctx.files.srcs:
        out_r1 = ctx.actions.declare_file("obj/Debug/net472/%s.%s.resources" % (ctx.attr.name, src.basename[:-(len(src.extension)+1)]))
        if (len(src.basename.split(".")) > 2):
            splits = src.basename.split(".")
            culture = splits[1]
            # out_r2 = ctx.actions.declare_file("obj/Debug/net452/%s/%s.resources.dll" % (culture, ctx.attr.name))
            # out_resources.append(out_r2)
        
        out_resources.append(out_r1)
    
    ctx.actions.run(
        inputs = resx + [csproj_output],
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

"""Converts files to common language runtime binary files that can be embedded.
The Resource File Generator (Resgen.exe) converts text (.txt or .restext) files and 
XML-based resource format (.resx) files to common language runtime binary (.resources) 
files that can be embedded in a runtime binary executable or satellite assembly.

Args:
    name: Name of the rule.
    srcs: The files to convert to .resources files.
    csproj: The name of the source project.
    target_frameworks: A list of target framework monikers to build.
"""
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
