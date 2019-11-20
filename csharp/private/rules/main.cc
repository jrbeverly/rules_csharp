#include <iostream>
#include <string>
#include <cstring>
#include <process.h>
#include <sstream>
#include <errno.h>
#include "tools/cpp/runfiles/runfiles.h"

using bazel::tools::cpp::runfiles::Runfiles;

std::string getDotNetDir(std::string path)
{
  return path.substr(0, path.find_last_of("/\\"));
}

std::string getEnvVar(std::string name, std::string path)
{
  std::stringstream ss;
  ss << name << "=" << path;
  return ss.str();
}

//TODO: Refactor the type/casting here
// I am all over the place, as this is a kind of
// amalgamation of multiple experiments
std::vector<std::string> getDotNetEnvList(std::string dotnet)
{
  const int count = 7;
  std::string variables[count] = {
      "HOME",
      "DOTNET_CLI_HOME",
      "APPDATA",
      "PROGRAMFILES",
      "TMP",
      "TEMP",
      "USERPROFILE",
  };

  auto dir = getDotNetDir(dotnet);
  std::vector<std::string> envvars;
  for (int i = 0; i < count; i++)
  {
    envvars.push_back(getEnvVar(variables[i], dir));
  }

  return envvars;
}

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

  auto envvars = getDotNetEnvList(dotnet);

  std::vector<char*> envp{};
  for(auto& envvar : envvars)
    envp.push_back(&envvar.front());
  envp.push_back(0);

  // dotnet wants this to either be dotnet or dotnet.exe but doesn't have a
  // preference otherwise.
  auto dotnet_argv = new char*[argc];
  dotnet_argv[0] = (char *)"dotnet";
  for (int i = 1; i < argc; i++)
  {
    dotnet_argv[i] = argv[i];
  }
  dotnet_argv[argc] = 0;

  auto result = _spawnve(_P_WAIT, dotnet.c_str(), dotnet_argv, envp.data());
  if (result != 0)
  {
    std::cout << "dotnet failed: " << errno << std::endl;
    return -1;
  }

  return result;
}