#include <fstream>
#include <iostream>
#include <sstream>
#include <string>

#ifdef _WIN32
#include <errno.h>
#include <process.h>
#include <windows.h>
#else  // not _WIN32
#include <stdlib.h>
#include <unistd.h>
#endif  // _WIN32

#include "tools/cpp/runfiles/runfiles.h"

using bazel::tools::cpp::runfiles::Runfiles;

std::string evprintf(std::string name, std::string path) {
  std::stringstream ss;
  ss << name << "=" << path;
  return ss.str();
}

std::string slurp(std::ifstream& in) {
  std::stringstream sstr;
  sstr << in.rdbuf();
  return sstr.str();
}

int main(int argc, char** argv) {
  std::string error;

  auto runfiles = Runfiles::Create(argv[0], &error);

  if (runfiles == nullptr) {
    std::cerr << "Couldn't load runfiles: " << error << std::endl;
    return 101;
  }

  // dotnet wrapper executable
  auto dotnet = runfiles->Rlocation("{DotnetExe}");
  if (dotnet.empty()) {
    std::cerr << "Couldn't find the .NET runtime" << std::endl;
    return 404;
  }

  // Get the name of the directory containing dotnet.exe
  auto dotnetDir = dotnet.substr(0, dotnet.find_last_of("/\\"));

  /*
  dotnet and nuget require these environment variables to be set
  without them we cannot build/run anything with dotnet.

  dotnet: HOME, DOTNET_CLI_HOME, APPDATA, PROGRAMFILES
  nuget: TMP, TEMP, USERPROFILE
  */
  std::vector<std::string> envvars;

  // dotnet wants this to either be dotnet or dotnet.exe but doesn't have a
  // preference otherwise.

  // Write the csproj to disk
  // then use that for all of this
  auto template = runfiles->Rlocation("{CsProjTemplateFile}");
  ifstream ifs(template.c_str(), ios::in | ios::ate);
  auto contents = slurp(ifs);

  std::string netFramework = string(getenv("BAZEL_CSHARP_RESX_FRAMEWORK"));
  std::string resXFile = string(getenv("BAZEL_CSHARP_RESX_FILE"));
  std::string manifestName = string(getenv("BAZEL_CSHARP_RESX_MANIFEST"));

  contents.replace(contents.find("NET_FRAMEWORK", 0), netFramework.size(),
                   netFramework);
  contents.replace(contents.find("RESX_FILE", 0), resXFile.size(), resXFile);
  contents.replace(contents.find("MANIFEST", 0), manifestName.size(),
                   manifestName);

  auto csproj = "template.csproj";
  ofstream csprojfile;
  csprojfile.open(csproj);
  csprojfile << contents;
  csprojfile.close();

  // This needs to be a list like so:
  // dotnetw build --project <path-to-project>
  auto dotnet_argv = new char* [4] { "dotnet", "build", csproj, nullptr };

#ifdef _WIN32
  // run `dotnet.exe` and wait for it to complete
  // the output from this cmd will be emitted to stdout
  auto result = _spawnv(_P_WAIT, dotnet.c_str(), dotnet_argv);
#else
  // run `dotnet.exe` and wait for it to complete
  // the output from this cmd will be emitted to stdout
  auto result = execv(dotnet.c_str(), const_cast<char**>(dotnet_argv));
#endif  // _WIN32
  if (result != 0) {
    std::cout << "dotnet failed: " << errno << std::endl;
    return -1;
  }

  return result;
}