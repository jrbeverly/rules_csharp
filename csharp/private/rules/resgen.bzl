load(
    "@d2l_rules_csharp//csharp/private:providers.bzl",
    "CSharpResource",
)
# load("@rules_cc//cc:defs.bzl", "cc_binary")

# Label of the csproj template for ResX compilation
_TEMPLATE = "@d2l_rules_csharp//csharp/private:wrappers/resx.cc"
_CSPROJ_TEMPLATE = "@d2l_rules_csharp//csharp/private:rules/ResGen.csproj"
script_template = """\
#!/bin/bash
set -euo pipefail
# --- begin runfiles.bash initialization ---
if [[ ! -d "${RUNFILES_DIR:-/dev/null}" && ! -f "${RUNFILES_MANIFEST_FILE:-/dev/null}" ]]; then
    if [[ -f "$0.runfiles_manifest" ]]; then
      export RUNFILES_MANIFEST_FILE="$0.runfiles_manifest"
    elif [[ -f "$0.runfiles/MANIFEST" ]]; then
      export RUNFILES_MANIFEST_FILE="$0.runfiles/MANIFEST"
    elif [[ -f "$0.runfiles/bazel_tools/tools/bash/runfiles/runfiles.bash" ]]; then
      export RUNFILES_DIR="$0.runfiles"
    fi
fi
if [[ -f "${RUNFILES_DIR:-/dev/null}/bazel_tools/tools/bash/runfiles/runfiles.bash" ]]; then
  source "${RUNFILES_DIR}/bazel_tools/tools/bash/runfiles/runfiles.bash"
elif [[ -f "${RUNFILES_MANIFEST_FILE:-/dev/null}" ]]; then
  source "$(grep -m1 "^bazel_tools/tools/bash/runfiles/runfiles.bash " \
            "$RUNFILES_MANIFEST_FILE" | cut -d ' ' -f 2-)"
else
  echo >&2 "ERROR: cannot find @bazel_tools//tools/bash/runfiles:runfiles.bash"
  exit 1
fi
# --- end runfiles.bash initialization ---
dotnet_exe="$(rlocation %s/%s)"
if [[ "$OSTYPE" == "linux-gnu" ]]; then
    ${dotnet_exe} $@
else
    dotnet_path=$(echo "/$dotnet_exe" | sed 's/\\\\/\\//g' | sed 's/://')
    ${dotnet_path} $@
fi
"""
def _csharp_resx_execv_impl(ctx):
    toolchain = ctx.toolchains["@d2l_rules_csharp//csharp/private:toolchain_type"]
    exe, runfiles = toolchain.tool

    tool_path = ctx.attr.tool[DefaultInfo].files_to_run.executable.short_path
    command = script_template % (ctx.workspace_name, tool_path)

    ctx.actions.write(
        output = ctx.outputs.executable,
        content = command,
        is_executable = True,
    )

    exec_runfiles = ctx.runfiles(files = [ctx.file._bash_runfiles])
    exec_runfiles = exec_runfiles.merge(runfiles)
    exec_runfiles = exec_runfiles.merge(ctx.attr.tool[DefaultInfo].default_runfiles)
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
        "_bash_runfiles": attr.label(
            doc = "The csproj template used in compiling the resx file.",
            default = Label("@bazel_tools//tools/bash/runfiles"),
            allow_single_file = True,
        ),
    },
    toolchains = ["@d2l_rules_csharp//csharp/private:toolchain_type"],
)

def _csharp_resx_template_impl(ctx):
    if not ctx.attr.out:
        resource_name = ctx.attr.name
    else:
        resource_name = ctx.attr.out

    toolchain = ctx.toolchains["@d2l_rules_csharp//csharp/private:toolchain_type"]
    cc_file = ctx.actions.declare_file("%s.cc" % (ctx.attr.name))
    ctx.actions.expand_template(
        template = ctx.file._template,
        output = cc_file,
        substitutions = {
            "{ResXFile}": "%s/%s" % (ctx.workspace_name, ctx.file.srcs.path),
            "{ResXManifest}": resource_name,
            "{CsProjTemplate}": "%s" % (ctx.file._csproj_template.short_path[3:]),
            "{NetFramework}": ctx.attr.target_framework,
            "{DotnetExe}": toolchain.runtime.executable.short_path[3:],
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
    toolchains = ["@d2l_rules_csharp//csharp/private:toolchain_type"],
)

def _csharp_resx_build_impl(ctx):
    """_csharp_resx_impl emits actions for compiling a resx file."""
    if not ctx.attr.out:
        resource_name = ctx.attr.name
    else:
        resource_name = ctx.attr.out

    # csproj = ctx.actions.declare_file(ctx.attr.csproj)
    # ctx.actions.run(
    #     inputs = [ctx.file._csproj_template],
    #     outputs = [csproj],
    #     executable = ctx.attr.tool.files_to_run,
    #     arguments = [csproj.path],
    #     mnemonic = "CreateCsProjTemplate",
    #     progress_message = "Creating csproj template",
    # )

    csproj = ctx.actions.declare_file(ctx.attr.csproj)
    args = ctx.actions.args()
    args.add("build")
    args.add(csproj.path)

    resource = ctx.actions.declare_file("obj/Debug/%s/%s.resources" % (ctx.attr.target_framework, resource_name))
    ctx.actions.run_shell(
        inputs = [ctx.file.srcs],
        outputs = [csproj, resource],
        tools = [ctx.executable.dotnet],
        command = "%s %s %s" % (ctx.executable.dotnet.path, "build", csproj.path),
        # arguments = [args],
        mnemonic = "CompileResX",
        progress_message = "Compiling resx file to binary",
        use_default_shell_env = False,
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
