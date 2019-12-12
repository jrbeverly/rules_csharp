"""Assembly Action

Calls the CSharp compiler, converting the provided elements into compiler options.

> dotnet.exe csc.dll /noconfig <other csc args>
> https://docs.microsoft.com/en-us/dotnet/csharp/language-reference/compiler-options/command-line-building-with-csc-exe
"""

load(
    "//private:common.bzl",
    "collect_transitive_info",
    "get_analyzer_dll",
    "use_highentropyva",
)
load(
    "//private:providers.bzl",
    "CSharpAssemblyInfo",
    "DEFAULT_LANG_VERSION",
    "SUB_SYSTEM_VERSION",
)

def _format_ref_arg(assembly):
    return "/r:" + assembly.path

def _format_analyzer_arg(analyzer):
    return "/analyzer:" + analyzer

def _format_additionalfile_arg(additionalfile):
    return "/additionalfile:" + additionalfile.path

def _format_resource_arg(resource):
    return "/resource:" + resource.path

def _format_define(symbol):
    return "/d:" + symbol

def _framework_preprocessor_symbols(tfm):
    """Gets the standard preprocessor symbols for the target framework.

    See https://docs.microsoft.com/en-us/dotnet/csharp/language-reference/preprocessor-directives/preprocessor-if#remarks
    for the official list.
    """

    specific = tfm.upper().replace(".", "_")

    if tfm.startswith("netstandard"):
        return ["NETSTANDARD", specific]
    elif tfm.startswith("netcoreapp"):
        return ["NETCOREAPP", specific]
    else:
        return ["NETFRAMEWORK", specific]

def AssemblyAction(
        actions,
        name,
        additionalfiles,
        analyzers,
        debug,
        defines,
        deps,
        keyfile,
        langversion,
        resources,
        srcs,
        out,
        target,
        target_framework,
        toolchain):
    """Calls the CSharp compiler on the provider elements.

    Calls the CSharp compiler, converting the provided elements into compiler options.

    > dotnet.exe csc.dll /noconfig <other csc args>
    > https://docs.microsoft.com/en-us/dotnet/csharp/language-reference/compiler-options/command-line-building-with-csc-exe

    Args:
        actions: Bazel methods for declaring output files and the actions that produce them.
        name: The name of the outputs.
        additionalfiles: Names additional files that don't directly affect code generation but may be used by analyzers for producing errors or warnings.
        analyzers: Run the analyzers from this assembly.
        debug: Emits debugging information.
        defines: Defines conditional compilation symbols.
        deps: Assembly files to reference.
        keyfile: Specifies a strong name key file.
        langversion: Specify language version: Default, ISO-1, ISO-2, 3, 4, 5, 6, 7, 7.1, 7.2, 7.3, or Latest
        resources: Embeds the specified resource.
        srcs: The source files for compilation.
        out: Specifies the output file name.
        target: Specifies the format of the output file.
        target_framework: The target framework moniker
        toolchain: The DotNET sdk toolchain.
    Returns:
        The compiled assembly.
    """
    out_file_name = name if out == "" else out
    out_dir = "bazelout/" + target_framework
    out_ext = "dll" if target == "library" else "exe"
    out_file = actions.declare_file("%s/%s.%s" % (out_dir, out_file_name, out_ext))
    refout = actions.declare_file("%s/%s.ref.%s" % (out_dir, out_file_name, out_ext))
    pdb = actions.declare_file("%s/%s.pdb" % (out_dir, out_file_name))

    # Our goal is to match msbuild as much as reasonable
    # https://docs.microsoft.com/en-us/dotnet/csharp/language-reference/compiler-options/listed-alphabetically
    args = actions.args()
    args.add("/unsafe-")
    args.add("/checked-")
    args.add("/nostdlib+")  # mscorlib will get added due to our transitive deps
    args.add("/utf8output")
    args.add("/deterministic+")
    args.add("/filealign:512")

    args.add("/nologo")

    if use_highentropyva(target_framework):
        args.add("/highentropyva+")
    else:
        args.add("/highentropyva-")

    ssv = SUB_SYSTEM_VERSION[target_framework]
    if ssv != None:
        args.add("/SUB_SYSTEM_VERSION:" + ssv)

    args.add("/warn:0")  # TODO: this stuff ought to be configurable

    args.add("/target:" + target)
    args.add("/langversion:" + (langversion or DEFAULT_LANG_VERSION[target_framework]))

    if debug:
        args.add("/debug+")
        args.add("/optimize-")
        args.add("/define:TRACE;DEBUG")
    else:
        args.add("/debug-")
        args.add("/optimize+")
        args.add("/define:TRACE;RELEASE")

    args.add("/debug:portable")

    # outputs
    args.add("/out:" + out_file.path)
    args.add("/refout:" + refout.path)
    args.add("/pdb:" + pdb.path)

    # assembly references
    (refs, runfiles, native_dlls) = collect_transitive_info(deps, target_framework)
    args.add_all(refs, map_each = _format_ref_arg)

    # analyzers
    analyzer_assemblies = [get_analyzer_dll(a) for a in analyzers]

    args.add_all(analyzer_assemblies, map_each = _format_analyzer_arg)
    args.add_all(additionalfiles, map_each = _format_additionalfile_arg)

    # .cs files
    args.add_all([cs.path for cs in srcs])

    # resources
    args.add_all(resources, map_each = _format_resource_arg)

    # defines
    args.add_all(
        _framework_preprocessor_symbols(target_framework) + defines,
        map_each = _format_define,
    )

    # keyfile
    if keyfile != None:
        args.add("/keyfile:" + keyfile.path)

    # TODO:
    # - appconfig(?)
    # - define
    #   * Need to audit D2L defines
    #   * msbuild adds some by default depending on your TF; we should too
    # - doc (d2l can probably skip this?)
    # - main (probably not a high priority for d2l)
    # - pathmap (needed for deterministic pdbs across hosts): this will
    #   probably need to be done in a wrapper because of the difference between
    #   the analysis phase (when this code runs) and execution phase.
    # - various code signing args (not needed for d2l)
    # - COM-related args like /link
    # - allow warnings to be configured
    # - unsafe (not needed for d2l)
    # - win32 args like /win32icon

    # spill to a "response file" when the argument list gets too big (Bazel
    # makes that call based on limitations of the OS).
    args.set_param_file_format("multiline")

    # Our wrapper uses _spawnv to launch dotnet, and that has a command line limit
    # of 1024 bytes, so always use a param file.
    args.use_param_file("@%s", use_always = True)

    direct_inputs = srcs + resources + analyzer_assemblies + additionalfiles + [toolchain.compiler]
    direct_inputs += [keyfile] if keyfile else []

    # dotnet.exe csc.dll /noconfig <other csc args>
    # https://docs.microsoft.com/en-us/dotnet/csharp/language-reference/compiler-options/command-line-building-with-csc-exe
    actions.run(
        mnemonic = "CSharpCompile",
        progress_message = "Compiling " + name,
        inputs = depset(
            direct = direct_inputs,
            transitive = [refs] + [native_dlls],
        ),
        outputs = [out_file, refout, pdb],
        executable = toolchain.runtime,
        arguments = [
            toolchain.compiler.path,

            # This can't go in the response file (if it does it won't be seen
            # until it's too late).
            "/noconfig",
            args,
        ],
    )

    return CSharpAssemblyInfo[target_framework](
        out = out_file,
        refout = refout,
        pdb = pdb,
        native_dlls = native_dlls,
        deps = deps,
        transitive_refs = refs,
        transitive_runfiles = runfiles,
        actual_tfm = target_framework,
    )
