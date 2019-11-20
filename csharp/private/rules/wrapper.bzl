def _csharp_wrapper_impl(ctx):
    cc_file = ctx.actions.declare_file("%s.cc" % (ctx.attr.name))
    ctx.actions.expand_template(
        template = ctx.file.src,
        output = cc_file,
        substitutions = {
            "{DotnetExe}": ctx.file.target.short_path[3:] ,
        },
    )

    files = depset(direct = [cc_file])
    return [
        DefaultInfo(
            files = files,
        ),
    ]

csharp_wrapper = rule(
    implementation = _csharp_wrapper_impl,
    attrs = {
        "src": attr.label(
            mandatory = True, 
            allow_single_file = True
        ),
        "target": attr.label(
            mandatory = True, 
            allow_single_file = True
        ),
    },
)