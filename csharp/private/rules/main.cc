#include <iostream>
#include <cstring>
#include <process.h>
#include <errno.h>
#include "tools/cpp/runfiles/runfiles.h"

using bazel::tools::cpp::runfiles::Runfiles;

int main(int argc, char **argv)
{
  std::string error;

  auto runfiles = Runfiles::Create(argv[0], &error);

  if (runfiles == nullptr)
  {
    std::cerr << "Couldn't load runfiles: " << error << std::endl;
    return 101;
  }

  auto dotnet = runfiles->Rlocation("{DotnetExe}");
  if (dotnet.empty())
  {
    std::cerr << "Couldn't find the .NET runtime" << std::endl;
    return 404;
  }
  std::cout << dotnet << std::endl;
  auto dotnet_argv = new char *[argc];
  const char *envp[] = {
      "HOME=C:\\Users\\jbeverly\\prototype",
      "DOTNET_CLI_HOME=C:\\Users\\jbeverly\\prototype",
      "APPDATA=C:\\Users\\jbeverly\\prototype",
      "PROGRAMFILES=C:\\Users\\jbeverly\\prototype",
      "TMP=C:\\Users\\jbeverly\\prototype",
      "TEMP=C:\\Users\\jbeverly\\prototype",
      "USERPROFILE=C:\\Users\\jbeverly\\prototype",
      0};

  // dotnet wants this to either be dotnet or dotnet.exe but doesn't have a
  // preference otherwise.
  dotnet_argv[0] = (char *)"dotnet";
  for (int i = 1; i < argc; i++)
  {
    dotnet_argv[i] = argv[i];
  }
  dotnet_argv[argc] = 0;

  //_P_OVERLAY
  //_P_WAIT
  auto result = _spawnve(_P_WAIT, dotnet.c_str(), dotnet_argv, envp);
  if (result != 0)
  {
    std::cout << errno << std::endl;
    return -1;
  }
  std::cout << result << std::endl;

  return result;
}