load(
    "@d2l_rules_csharp//csharp/private:providers.bzl",
    "CSharpResource",
)
# load("@rules_cc//cc:defs.bzl", "cc_binary")

# Label of the csproj template for ResX compilation
_TEMPLATE = "@d2l_rules_csharp//csharp/private:wrappers/resx.cc"
_CSPROJ_TEMPLATE = "@d2l_rules_csharp//csharp/private:rules/ResGen.csproj"

def _csharp_resx_template_impl(ctx):
    if not ctx.attr.out:
        resource_name = ctx.attr.name
    else:
        resource_name = ctx.attr.out

    cc_file = ctx.actions.declare_file("%s.cc" % (ctx.attr.name))
    ctx.actions.expand_template(
        template = ctx.file._template,
        output = cc_file,
        substitutions = {
            "{ResXFile}": "__main__/%s" % (ctx.file.src.path),
            "{ResXManifest}": resource_name,
            "{CsProjTemplate}": "%s" % (ctx.file._csproj_template.short_path[3:]),
            "{NetFramework}": ctx.attr.target_framework,
            "{TemplateName}": "%s.csproj" % (ctx.attr.name),
        },
    )
    return [
        DefaultInfo(
            files = depset(direct = [cc_file]),
        ),
    ]

csharp_resx_template = rule(
    implementation = _csharp_resx_template_impl,
    attrs = {
        "src": attr.label(
            allow_single_file = True,
        ),
        "out": attr.string(
            doc = "Specifies the name of the output (.resources) resource file. The extension is not necessary.",
        ),
        "target_framework": attr.string(
            doc = "A target framework moniker used in building the resource file.",
            default = "netcoreapp3.0",
        ),
        "_template": attr.label(
            default = Label(_TEMPLATE),
            allow_single_file = True,
        ),
        "_csproj_template": attr.label(
            default = Label(_CSPROJ_TEMPLATE),
            allow_single_file = True,
        ),
    },
)

def _csharp_resx_build_impl(ctx):
    """_csharp_resx_impl emits actions for compiling a resx file."""
    if not ctx.attr.out:
        resource_name = ctx.attr.name
    else:
        resource_name = ctx.attr.out

    csproj = ctx.actions.declare_file(ctx.attr.csproj)
    resource = ctx.actions.declare_file("obj/Debug/%s/%s.resources" % (ctx.attr.target_framework, resource_name))

    toolchain = ctx.toolchains["@d2l_rules_csharp//csharp/private:toolchain_type"]
    ctx.actions.run(
        inputs = [],
        outputs = [csproj],
        executable = ctx.attr.src.files_to_run,
        arguments = [],
        mnemonic = "CreateCsProjTemplate",
        progress_message = "Creating csproj template",
    )

    args = ctx.actions.args()
    args.add("build")
    args.add(csproj.path)

    ctx.actions.run(
        inputs = [ctx.file.src, csproj],
        outputs = [resource],
        executable = toolchain.runtime,
        arguments = [args],
        mnemonic = "CompileResX",
        progress_message = "Compiling resx file to binary",
    )

    files = depset(direct = [resource])
    return [
        CSharpResource(
            name = ctx.attr.name,
            result = resource,
            identifier = resource.basename if not ctx.attr.identifier else ctx.attr.identifier,
        ),
        DefaultInfo(
            files = files,
        ),
    ]

csharp_resx_build = rule(
    implementation = _csharp_resx_build_impl,
    attrs = {
        "src": attr.label(
            doc = "The XML-based resource format (.resx) file.",
            mandatory = True,
            allow_single_file = True,
        ),
        "identifier": attr.string(
            doc = "The logical name for the resource; the name that is used to load the resource. The default is the name of the rule.",
        ),
        "out": attr.string(
            doc = "Specifies the name of the output (.resources) resource file. The extension is not necessary.",
        ),
        "csproj": attr.string(
            doc = "Specifies the name of the output (.resources) resource file. The extension is not necessary.",
        ),
        "target_framework": attr.string(
            doc = "A target framework moniker used in building the resource file.",
            default = "netcoreapp3.0",
        ),
        # "_csproj_template": attr.label(
        #     doc = "The csproj template used in compiling the resx file.",
        #     default = Label(_CSPROJ_TEMPLATE),
        #     allow_single_file = True,
        # ),
    },
    toolchains = ["@d2l_rules_csharp//csharp/private:toolchain_type"],
    doc = """
Compiles an XML-based resource format (.resx) file into a binary resource (.resources) file.
""",
)

def csharp_resx(name, src):
    template = "%s-template" % (name)
    csharp_resx_template(
        name = "%s-template" % (name),
        src = src,
        out = name,
    )

    native.cc_binary(
        name = "%s-csproj" % (name),
        data = [src, _CSPROJ_TEMPLATE],
        srcs = ["%s" % (template)],
        deps = ["@bazel_tools//tools/cpp/runfiles"],
    )

    csharp_resx_build(
        name = "%s" % (name),
        src = "%s-csproj" % (name),
        csproj = "%s-template.csproj" % (name),
    )
