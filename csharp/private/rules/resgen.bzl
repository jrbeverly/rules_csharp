# Label of the template file to use.
_TEMPLATE = "@d2l_rules_csharp//csharp/private:rules/Template.csproj"

def _csharp_resx_impl(ctx):
    proj_name = "hello"
    csproj_output = ctx.actions.declare_file("{}.csproj".format(proj_name))

    ctx.actions.expand_template(
        template = ctx.file._template,
        output = csproj_output,
        substitutions = {
            "{FRAMEWORK}": "net472",
            "{PATH}": ctx.files.srcs[0].basename,
        },
    )

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


    out_resources = []
    for src in ctx.files.srcs:
        out_r1 = ctx.actions.declare_file("obj/Debug/net472/%s.%s.resources" % (proj_name, src.basename[:-(len(src.extension)+1)]))
        if (len(src.basename.split(".")) > 2):
            splits = src.basename.split(".")
            culture = splits[1]
            # out_r2 = ctx.actions.declare_file("obj/Debug/net452/%s/%s.resources.dll" % (culture, proj_name))
            # out_resources.append(out_r2)
        out_resources.append(out_r1)
    
    ctx.actions.run(
        inputs = resx + [csproj_output],
        # tools = [bat],
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
    # files = depset(direct = resx + [csproj_output])
    # runfiles = ctx.runfiles(files = resx)
    return [DefaultInfo(files = files, runfiles = runfiles)]

csharp_resx = rule(
    implementation = _csharp_resx_impl,
    attrs = {
        "srcs": attr.label_list(mandatory = True, allow_files = True),
        "_template": attr.label(
            default = Label(_TEMPLATE),
            allow_single_file = True,
        ),
    },
)
