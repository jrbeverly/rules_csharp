# Label of the template file to use.
_TEMPLATE = "@d2l_rules_csharp//csharp/private:rules/Template.csproj"

def _csharp_resgen_impl(ctx):
    csproj_output = ctx.actions.declare_file("{}.csproj".format(ctx.attr.name))
    resx_output = ctx.actions.declare_file("{}.resx".format(ctx.attr.name))

    ctx.actions.expand_template(
        template = ctx.file._template,
        output = csproj_output,
        substitutions = {
            "{ASSEMBLY}": "ResGen",
            "{CLASSNAME}": "Strings",
            "{FRAMEWORK}": "net462",
        },
    )

    bat = ctx.actions.declare_file(ctx.label.name + "-cmd.bat")
    ctx.actions.write(
        output = bat,
        content = "@copy /Y \"%s\" \"%s\" >NUL" % (
            ctx.file.src.path.replace("/", "\\"),
            resx_output.path.replace("/", "\\"),
        ),
        is_executable = True,
    )
    ctx.actions.run(
        inputs = [ctx.file.src],
        tools = [bat],
        outputs = [resx_output],
        executable = "cmd.exe",
        arguments = ["/C", bat.path.replace("/", "\\")],
        mnemonic = "CopyFile",
        progress_message = "Copying files",
        use_default_shell_env = True,
    )

    files = depset(direct = [resx_output])
    runfiles = ctx.runfiles(files = [resx_output])
    return [DefaultInfo(files = files, runfiles = runfiles)]

csharp_resgen = rule(
    implementation = _csharp_resgen_impl,
    attrs = {
        "src": attr.label(mandatory = True, allow_single_file = True),
        "_template": attr.label(
            default = Label(_TEMPLATE),
            allow_single_file = True,
        ),
    },
)
