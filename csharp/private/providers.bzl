"""Define the CSharpAssembly_-prefixed providers

This module defines one provider per target framework and creates some handy
lookup tables for dealing with frameworks.

See docs/MultiTargetingDesign.md for more info.
"""

def _make_csharp_provider(tfm):
    return provider(
        doc = "A (usually C#) DLL or exe, targetting %s." % tfm,
        fields = {
            "out": "a dll (for libraries and tests) or an exe (for binaries).",
            "refout": "A reference-only DLL/exe. See docs/ReferenceAssemblies.md for more info.",
            "pdb": "debug symbols",
            "native_dlls": "A list of native DLLs required to build and run this assembly",
            "deps": "the non-transitive dependencies for this assembly (used by import_multiframework_library).",
            "transitive_refs": "A list of other assemblies to reference when referencing this assembly in a compilation.",
            "transitive_runfiles": "Runfiles from the transitive dependencies.",
            "actual_tfm": "The target framework of the actual dlls",
        },
    )

# Bazel requires that providers be "top level" objects, so this stuff is a bit
# more boilerplate than it could otherwise be.
CSharpAssemblyNetStandard = _make_csharp_provider("netstandard")
CSharpAssemblyNetStandard10 = _make_csharp_provider("netstandard1.0")
CSharpAssemblyNetStandard11 = _make_csharp_provider("netstandard1.1")
CSharpAssemblyNetStandard12 = _make_csharp_provider("netstandard1.2")
CSharpAssemblyNetStandard13 = _make_csharp_provider("netstandard1.3")
CSharpAssemblyNetStandard14 = _make_csharp_provider("netstandard1.4")
CSharpAssemblyNetStandard15 = _make_csharp_provider("netstandard1.5")
CSharpAssemblyNetStandard16 = _make_csharp_provider("netstandard1.6")
CSharpAssemblyNetStandard20 = _make_csharp_provider("netstandard2.0")
CSharpAssemblyNetStandard21 = _make_csharp_provider("netstandard2.1")
CSharpAssemblyNet11 = _make_csharp_provider("net11")
CSharpAssemblyNet20 = _make_csharp_provider("net20")
CSharpAssemblyNet30 = _make_csharp_provider("net30")
CSharpAssemblyNet35 = _make_csharp_provider("net35")
CSharpAssemblyNet40 = _make_csharp_provider("net40")
CSharpAssemblyNet403 = _make_csharp_provider("net403")
CSharpAssemblyNet45 = _make_csharp_provider("net45")
CSharpAssemblyNet451 = _make_csharp_provider("net451")
CSharpAssemblyNet452 = _make_csharp_provider("net452")
CSharpAssemblyNet46 = _make_csharp_provider("net46")
CSharpAssemblyNet461 = _make_csharp_provider("net461")
CSharpAssemblyNet462 = _make_csharp_provider("net462")
CSharpAssemblyNet47 = _make_csharp_provider("net47")
CSharpAssemblyNet471 = _make_csharp_provider("net471")
CSharpAssemblyNet472 = _make_csharp_provider("net472")
CSharpAssemblyNet48 = _make_csharp_provider("net48")
CSharpAssemblyNetCoreApp10 = _make_csharp_provider("netcoreapp1.0")
CSharpAssemblyNetCoreApp11 = _make_csharp_provider("netcoreapp1.1")
CSharpAssemblyNetCoreApp20 = _make_csharp_provider("netcoreapp2.0")
CSharpAssemblyNetCoreApp21 = _make_csharp_provider("netcoreapp2.1")
CSharpAssemblyNetCoreApp22 = _make_csharp_provider("netcoreapp2.2")
CSharpAssemblyNetCoreApp30 = _make_csharp_provider("netcoreapp3.0")

# A dict from TFM to provider. The order of keys is not used.
CSharpAssembly = {
    "netstandard": CSharpAssemblyNetStandard,
    "netstandard1.0": CSharpAssemblyNetStandard10,
    "netstandard1.1": CSharpAssemblyNetStandard11,
    "netstandard1.2": CSharpAssemblyNetStandard12,
    "netstandard1.3": CSharpAssemblyNetStandard13,
    "netstandard1.4": CSharpAssemblyNetStandard14,
    "netstandard1.5": CSharpAssemblyNetStandard15,
    "netstandard1.6": CSharpAssemblyNetStandard16,
    "netstandard2.0": CSharpAssemblyNetStandard20,
    "netstandard2.1": CSharpAssemblyNetStandard21,
    "net11": CSharpAssemblyNet11,
    "net20": CSharpAssemblyNet20,
    "net30": CSharpAssemblyNet30,
    "net35": CSharpAssemblyNet35,
    "net40": CSharpAssemblyNet40,
    "net403": CSharpAssemblyNet403,
    "net45": CSharpAssemblyNet45,
    "net451": CSharpAssemblyNet451,
    "net452": CSharpAssemblyNet452,
    "net46": CSharpAssemblyNet46,
    "net461": CSharpAssemblyNet461,
    "net462": CSharpAssemblyNet462,
    "net47": CSharpAssemblyNet47,
    "net471": CSharpAssemblyNet471,
    "net472": CSharpAssemblyNet472,
    "net48": CSharpAssemblyNet48,
    "netcoreapp1.0": CSharpAssemblyNetCoreApp10,
    "netcoreapp1.1": CSharpAssemblyNetCoreApp11,
    "netcoreapp2.0": CSharpAssemblyNetCoreApp20,
    "netcoreapp2.1": CSharpAssemblyNetCoreApp21,
    "netcoreapp2.2": CSharpAssemblyNetCoreApp22,
    "netcoreapp3.0": CSharpAssemblyNetCoreApp30,
}

# A dict of target frameworks to the set of other framworks it can compile
# against. This relationship is transitive. The order of this dictionary also
# matters. netstandard should appear first, and keys within a family should
# proceed from oldest to newest
FrameworkCompatibility = {
    # .NET Standard
    "netstandard": [],
    "netstandard1.0": ["netstandard"],
    "netstandard1.1": ["netstandard1.0"],
    "netstandard1.2": ["netstandard1.1"],
    "netstandard1.3": ["netstandard1.2"],
    "netstandard1.4": ["netstandard1.3"],
    "netstandard1.5": ["netstandard1.4"],
    "netstandard1.6": ["netstandard1.5"],
    "netstandard2.0": ["netstandard1.6"],
    "netstandard2.1": ["netstandard2.0"],

    # .NET Framework
    "net11": [],
    "net20": ["net11"],
    "net30": ["net20"],
    "net35": ["net30"],
    "net40": ["net35"],
    "net403": ["net40"],
    "net45": ["net403", "netstandard1.1"],
    "net451": ["net45", "netstandard1.2"],
    "net452": ["net451"],
    "net46": ["net452", "netstandard1.3"],
    "net461": ["net46", "netstandard2.0"],
    "net462": ["net461"],
    "net47": ["net462"],
    "net471": ["net47"],
    "net472": ["net471"],
    "net48": ["net472"],

    # .NET Core
    "netcoreapp1.0": ["netstandard1.6"],
    "netcoreapp1.1": ["netcoreapp1.0"],
    "netcoreapp2.0": ["netcoreapp1.1", "netstandard2.0"],
    "netcoreapp2.1": ["netcoreapp2.0"],
    "netcoreapp2.2": ["netcoreapp2.1"],
    "netcoreapp3.0": ["netcoreapp2.2", "netstandard2.1"],
}

SubsystemVersion = {
    "netstandard": None,
    "netstandard1.0": None,
    "netstandard1.1": None,
    "netstandard1.2": None,
    "netstandard1.3": None,
    "netstandard1.4": None,
    "netstandard1.5": None,
    "netstandard1.6": None,
    "netstandard2.0": None,
    "netstandard2.1": None,
    "net11": None,
    "net20": None,
    "net30": None,
    "net35": None,
    "net40": None,
    "net403": None,
    "net45": "6.00",
    "net451": "6.00",
    "net452": "6.00",
    "net46": "6.00",
    "net461": "6.00",
    "net462": "6.00",
    "net47": "6.00",
    "net471": "6.00",
    "net472": "6.00",
    "net48": "6.00",
    "netcoreapp1.0": None,
    "netcoreapp1.1": None,
    "netcoreapp2.0": None,
    "netcoreapp2.1": None,
    "netcoreapp2.2": None,
    "netcoreapp3.0": None,
}

DefaultLangVersion = {
    "netstandard": "7.3",
    "netstandard1.0": "7.3",
    "netstandard1.1": "7.3",
    "netstandard1.2": "7.3",
    "netstandard1.3": "7.3",
    "netstandard1.4": "7.3",
    "netstandard1.5": "7.3",
    "netstandard1.6": "7.3",
    "netstandard2.0": "7.3",
    "netstandard2.1": "7.3",
    "net11": "7.3",
    "net20": "7.3",
    "net30": "7.3",
    "net35": "7.3",
    "net40": "7.3",
    "net403": "7.3",
    "net45": "7.3",
    "net451": "7.3",
    "net452": "7.3",
    "net46": "7.3",
    "net461": "7.3",
    "net462": "7.3",
    "net47": "7.3",
    "net471": "7.3",
    "net472": "7.3",
    "net48": "7.3",
    "netcoreapp1.0": "7.3",
    "netcoreapp1.1": "7.3",
    "netcoreapp2.0": "7.3",
    "netcoreapp2.1": "7.3",
    "netcoreapp2.2": "7.3",
    "netcoreapp3.0": "8.0",
}

# A convenience used in attributes that need to specify that they accept any
# kind of C# assembly. This is an array of single-element arrays.
AnyTargetFramework = [[a] for a in CSharpAssembly.values()]
