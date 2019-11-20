#include <iostream>
#include <cstring>
#include <process.h>
#include <string>
#include "tools/cpp/runfiles/runfiles.h"

using bazel::tools::cpp::runfiles::Runfiles;

int main(int argc, char** argv) {
  std::string error;

  auto runfiles = Runfiles::Create(argv[0], &error);

  if (runfiles == nullptr) {
    std::cerr << "Couldn't load runfiles: " << error << std::endl;
    return 1;
  }

  auto dotnet = runfiles->Rlocation("{DotnetExe}");

  if (dotnet.empty()) {
    std::cerr << "Couldn't find the .NET runtime" << std::endl;
    return 1;
  }

  auto dotnet_argv = new char*[argc + 2];
  char *envp[] =
  {
      "HOME=/root/",
      "DOTNET_CLI_HOME=/root/",
      "APPDATA=/root/",
      "PROGRAMFILES=/root/",
      0
  };

  // dotnet wants this to either be dotnet or dotnet.exe but doesn't have a
  // preference otherwise.
  dotnet_argv[0] = (char*)"dotnet";
  for (int i = 1; i < argc; i++) {
    dotnet_argv[i] = argv[i];
  }

  dotnet_argv[argc + 1] = 0;
  return _execve(dotnet.c_str(), dotnet_argv, envp);
}