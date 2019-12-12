load("//csharp/private:providers.bzl", "CSharpAssembly")
load("//csharp/private/rules:imports.bzl", "import_library", "import_multiframework_library")

def _import_dll(dll, has_pdb, imports):
    path = dll.split("/")

    tfm = path[1]

    # Ignore frameworks we don't support (like net35)
    if tfm not in CSharpAssembly:
        return

    lib_name = path[-1].rsplit(".", 1)[0]

    target_name = "%s-%s" % (lib_name, tfm)

    if lib_name not in imports:
        imports[lib_name] = {tfm: target_name}
    else:
        imports[lib_name][tfm] = target_name

    if dll in has_pdb:
        import_library(
            name = target_name,
            target_framework = tfm,
            dll = dll,
            pdb = dll[:-3] + "pdb",
        )
    else:
        import_library(
            name = target_name,
            target_framework = tfm,
            dll = dll,
        )

def setup_basic_nuget_package():
    """This macro gets used to implement the default NuGet BUILD file.

       We are limited by the fact that Bazel does not allow the analysis phase to
       read the contents of source files, e.g. to correctly configure deps. For
       more advanced usages a BUILD file will need to be generated outside of
       Bazel. See docs/UsingNuGetPackages.md for more info.

       This has to be public so that packages can call it but you probably
       shouldn't use it directly.
    """
    dlls = native.glob(["lib/*/*.dll"])
    pdbs = native.glob(["lib/*/*.pdb"])

    has_pdb = {(pdb[:-3] + "dll"): 1 for pdb in pdbs}

    # Map from lib name to dict from tfm to target name
    imports = {}

    # Output import_library rules
    for dll in dlls:
        _import_dll(dll, has_pdb, imports)

    # Output import_multiframework_library rules
    for (name, tfms) in imports.items():
        tfm_args = {}
        for tfm in tfms:
            tfm_args[tfm.replace(".", "_")] = tfms[tfm]

        import_multiframework_library(
            name = name,
            visibility = ["//visibility:public"],
            **tfm_args
        )
