# Label of the template file to use.
_TEMPLATE = "@d2l_rules_csharp//csharp/private:rules/Template.csproj"

def _csharp_resx_impl(ctx):
    csproj = ctx.actions.declare_file("%s.csproj" % (ctx.attr.name))
    ctx.actions.expand_template(
        template = ctx.file._csproj_template,
        output = csproj,
        substitutions = {
            "{FRAMEWORK}": ctx.attr.target_framework,
            "{RESOURCE}": ctx.file.src.basename,
        },
    )

    ## Copying the resx files
    ## TODO: Replace this with a `copy_file` cross platform
    copied_source = ctx.actions.declare_file("{}".format(ctx.file.src.basename))
    copy_bat = ctx.actions.declare_file("%s-%s-cmd.bat" % (ctx.label.name, ctx.file.src.basename))
    ctx.actions.write(
        output = copy_bat,
        content = "@copy /Y \"%s\" \"%s\" >NUL" % (
            ctx.file.src.path.replace("/", "\\"),
            copied_source.path.replace("/", "\\"),
        ),
        is_executable = True,
    )

    ctx.actions.run(
        inputs = [ctx.file.src],
        tools = [copy_bat],
        outputs = [copied_source],
        executable = "cmd.exe",
        arguments = ["/C", copy_bat.path.replace("/", "\\")],
        mnemonic = "CSharpResXCopyFile",
        progress_message = "Copying files",
        use_default_shell_env = True,
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
        inputs = [copied_source, csproj],
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
