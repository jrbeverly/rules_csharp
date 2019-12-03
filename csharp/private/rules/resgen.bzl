load(
    "@d2l_rules_csharp//csharp/private:providers.bzl",
    "CSharpResource",
)
# load("@rules_cc//cc:defs.bzl", "cc_binary")

# Label of the csproj template for ResX compilation
_TEMPLATE = "@d2l_rules_csharp//csharp/private:wrappers/resx.cc"
_CSPROJ_TEMPLATE = "@d2l_rules_csharp//csharp/private:rules/ResGen.csproj"

def _csharp_resx_execv_impl(ctx):
    toolchain = ctx.toolchains["@d2l_rules_csharp//csharp/private:toolchain_type"]
    exe, runfiles = toolchain.tool

#bazel-out/host/bin/resgen/Hello.Strings-execv.runfiles/csharp_examples/resgen/Strings.resx
    tool_path = toolchain.runtime.executable.short_path[3:]
    command = """#!/bin/bash
        export RUNFILES_DIR="$0.runfiles"
        ls bazel-out/host/bin/resgen/
        ${RUNFILES_DIR}/%s $@""" % (tool_path)

    ctx.actions.write(
        output = ctx.outputs.executable,
        content = command,
        is_executable = True,
    )

    exec_runfiles = runfiles.merge(ctx.attr.tool[DefaultInfo].default_runfiles)
    for r in exec_runfiles.files.to_list():
        print(r.path)
    return [DefaultInfo(
        runfiles = exec_runfiles,
    )]

csharp_resx_execv = rule(
    implementation = _csharp_resx_execv_impl,
    executable = True,
    attrs = {
        "tool": attr.label(
            doc = "The tool responsible for generating a csproj file.",
            mandatory = True,
        ),
    },
    toolchains = ["@d2l_rules_csharp//csharp/private:toolchain_type"],
)

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
            "{ResXFile}": "%s/%s" % (ctx.workspace_name, ctx.file.srcs.path),
            "{ResXManifest}": resource_name,
            "{CsProjTemplate}": "%s" % (ctx.file._csproj_template.short_path[3:]),
            "{NetFramework}": ctx.attr.target_framework,
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
        "srcs": attr.label(
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
    ctx.actions.run(
        inputs = [ctx.file._csproj_template],
        outputs = [csproj],
        executable = ctx.attr.tool.files_to_run,
        arguments = [csproj.path],
        mnemonic = "CreateCsProjTemplate",
        progress_message = "Creating csproj template",
    )

    args = ctx.actions.args()
    args.add("build")
    args.add(csproj.path)

    toolchain = ctx.toolchains["@d2l_rules_csharp//csharp/private:toolchain_type"]

    resource = ctx.actions.declare_file("obj/Debug/%s/%s.resources" % (ctx.attr.target_framework, resource_name))
    ctx.actions.run(
        inputs = [csproj, ctx.file.srcs],
        outputs = [resource],
        # executable = toolchain.runtime,
        executable = ctx.executable.dotnet,
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
        "srcs": attr.label(
            doc = "The XML-based resource format (.resx) file.",
            mandatory = True,
            allow_single_file = True,
        ),
        "tool": attr.label(
            doc = "The tool responsible for generating a csproj file.",
            mandatory = True,
            executable = True,
            cfg = "host",
        ),
        "dotnet": attr.label(
            doc = "The tool responsible for generating a csproj file.",
            mandatory = True,
            executable = True,
            cfg = "host",
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
        "_csproj_template": attr.label(
            doc = "The csproj template used in compiling the resx file.",
            default = Label(_CSPROJ_TEMPLATE),
            allow_single_file = True,
        ),
    },
    toolchains = ["@d2l_rules_csharp//csharp/private:toolchain_type"],
    doc = """
Compiles an XML-based resource format (.resx) file into a binary resource (.resources) file.
""",
)

def csharp_resx(name, src):
    template = "%s-template" % (name)
    csproj = "%s-csproj" % (name)
    execv = "%s-execv" % (name)

    csharp_resx_template(
        name = template,
        srcs = src,
        out = name,
    )

    native.cc_binary(
        name = csproj,
        srcs = [template],
        data = [src, _CSPROJ_TEMPLATE],
        deps = ["@bazel_tools//tools/cpp/runfiles"],
    )

    csharp_resx_execv(
        name = execv,
        tool = csproj,
    )

    csharp_resx_build(
        name = name,
        srcs = src,
        tool = csproj,
        dotnet = execv,
        csproj = "%s-template.csproj" % (name),
    )
