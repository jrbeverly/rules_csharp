load(
    "//csharp/private:common.bzl",
    "collect_transitive_info",
    "fill_in_missing_frameworks",
)
load("//csharp/private:providers.bzl", "AnyTargetFramework", "CSharpAssembly", "tfm_from_attr")

def _import_library(ctx):
    files = []

    if ctx.file.dll == None and ctx.file.refdll == None:
        fail("At least one of dll or refdll must be specified")

    if ctx.file.dll != None:
        files.append(ctx.file.dll)

    if ctx.file.pdb != None:
        files.append(ctx.file.pdb)

    if ctx.file.refdll != None:
        files.append(ctx.file.refdll)

    files += ctx.files.native_dlls

    tfm = ctx.attr.target_framework

    (refs, runfiles, native_dlls) = collect_transitive_info(ctx.attr.deps, tfm)

    providers = {
        tfm: CSharpAssembly[tfm](
            out = ctx.file.dll,
            refout = ctx.file.refdll,
            pdb = ctx.file.pdb,
            native_dlls = depset(direct = ctx.files.native_dlls, transitive = [native_dlls]),
            deps = ctx.attr.deps,
            transitive_refs = refs,
            transitive_runfiles = runfiles,
            actual_tfm = tfm,
        ),
    }

    fill_in_missing_frameworks(providers)

    return [DefaultInfo(files = depset(files))] + providers.values()

import_library = rule(
    _import_library,
    doc = "Creates a target for a static C# DLL for a specific target framework",
    attrs = {
        "target_framework": attr.string(
            doc = "The target framework for this DLL",
            mandatory = True,
        ),
        "dll": attr.label(
            doc = "A static DLL",
            allow_single_file = [".dll"],
        ),
        "pdb": attr.label(
            doc = "Debug symbols for the dll",
            allow_single_file = [".pdb"],
        ),
        "refdll": attr.label(
            doc = "A metadata-only DLL, suitable for compiling against but not running",
            allow_single_file = [".dll"],
        ),
        "native_dlls": attr.label_list(
            doc = "A list of native dlls, which while unreferenced, are required for running and compiling",
            allow_files = [".dll"],
        ),
        "deps": attr.label_list(
            doc = "other DLLs that this DLL depends on.",
            providers = AnyTargetFramework,
        ),
    },
    executable = False,
)

def _import_multiframework_library_impl(ctx):
    attrs = {}
    for (tfm, tf_provider) in CSharpAssembly.items():
        attrs[tfm] = tfm_from_attr(ctx.attr, tfm)

    providers = {}

    for (tfm, attr) in attrs.items():
        if attr != None:
            providers[tfm] = attr[CSharpAssembly[tfm]]

    fill_in_missing_frameworks(providers)

    # TODO: we don't return an explicit DefaultInfo for this rule... maybe we
    # should construct one from a specific (indicated by the user) framework?
    return providers.values()

def _generate_multiframework_attrs():
    attrs = {}
    for (tfm, tf_provider) in CSharpAssembly.items():
        attrs[tfm.replace(".", "_")] = attr.label(
            doc = "The %s version of this library" % tfm,
            providers = [tf_provider],
        )

    return attrs

import_multiframework_library = rule(
    _import_multiframework_library_impl,
    doc = "Aggregate import_library targets for specific target-frameworks into one target",
    attrs = _generate_multiframework_attrs(),
)
