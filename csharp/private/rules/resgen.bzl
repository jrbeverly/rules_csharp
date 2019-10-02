# Label of the template file to use.
_TEMPLATE = "@d2l_rules_csharp//csharp/private:rules/Template.csproj"

def _csharp_resgen_impl(ctx):
    csproj_output = ctx.actions.declare_file("{}.csproj".format(ctx.attr.name))

    ctx.actions.expand_template(
        template = ctx.file._template,
        output = csproj_output,
        substitutions = {
            "{FRAMEWORK}": "net462",
        },
    )

    resx = []
    for src in ctx.files.srcs:
        resx_output = ctx.actions.declare_file("{}.resx".format(src.basename))
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

    res_outs = ctx.actions.declare_file("obj/Debug/net452/%s.dll" % (ctx.label.name))
    ctx.actions.run(
        inputs = resx + [csproj_output],
        # tools = [bat],
        outputs = [res_outs],
        executable = "C:/Users/jbeverly/Repositories/bazel/diff/dotnet-sdk-3.0.100-win-x64/dotnet.exe",
        arguments = ["build", csproj_output.path.replace("/", "\\")],
        mnemonic = "BuildResXProject",
        progress_message = "Compiling resx files",
        env = {
            "HOME": "C:\\Users\\jbeverly\\",
            "HOMEPATH": "C:\\Users\\jbeverly\\",
            "DOTNET_CLI_HOME": "C:\\Users\\jbeverly\\bazel\\dotnet",
        },
    )
    files = depset(direct = [res_outs])
    runfiles = ctx.runfiles(files = [res_outs])
    # files = depset(direct = resx + [csproj_output])
    # runfiles = ctx.runfiles(files = resx)
    return [DefaultInfo(files = files, runfiles = runfiles)]

csharp_resgen = rule(
    implementation = _csharp_resgen_impl,
    attrs = {
        "srcs": attr.label_list(mandatory = True, allow_files = True),
        "_template": attr.label(
            default = Label(_TEMPLATE),
            allow_single_file = True,
        ),
    },
)
