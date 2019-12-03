#include <fstream>
#include <ios>
#include <iostream>
#include <sstream>
#include <stdio.h>
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

  auto num1 = runfiles->Rlocation("csharp_examples/resgen/Strings.resx");
  if (num1.empty()) {
    std::cout << "Couldn't find the resx file" << std::endl;
  }

  char cwd[256];
  if (getcwd(cwd, sizeof(cwd)) != NULL) {
    printf("Current working dir: %s\n", cwd);
  }
  std::cout << std::string(cwd) << "/" << num1 << std::endl;

  ///bazel-out/host/bin/resgen/
  // std::string cmdtext = "ls -a " + std::string(cwd) + "/bazel-out/k8-fastbuild/bin/resgen/Hello.Strings-csproj.runfiles/csharp_examples/resgen/Strings.resx > /tmp/here.txt";
  // system(cmdtext.c_str());
  // std::cout << cmdtext << std::endl;
  // // std::ifstream stm(
  // //     "/root/.cache/bazel/_bazel_root/1a06c90be1eefea8b933cc8429eff806/"
  // //     "execroot/csharp_examples/bazel-out/host/bin/resgen/"
  // //     "Hello.Strings-csproj.runfiles_manifest");
  // // std::ifstream stm(std::string(argv[0]) + ".runfiles/MANIFEST");
  // std::ifstream stm(std::string(cwd) + "bazel-out/host/bin/resgen/Hello.Strings-csproj.runfiles_manifest");
  // // std::ifstream stm("resgen/Hello.Strings-csproj.runfiles_manifest");
  // if (!stm.is_open()) {
  //   return -4527;
  // }

  // std::map<std::string, std::string> result;
  // std::string line;
  // std::getline(stm, line);
  // std::size_t line_count = 1;
  // std::string expected = "csharp_examples/resgen/Strings.resx";
  // while (!line.empty()) {
  //   std::string::size_type idx = line.find_first_of(' ');
  //   if (idx == std::string::npos) {
  //     return -4568;
  //   }

  //   std::string actual = line.substr(0, idx);
  //   if (expected == actual) {
  //     std::cout << "SAME" << std::endl;
  //   }
  //   result[line.substr(0, idx)] = line.substr(idx + 1);
  //   std::cout << line.substr(0, idx) << " = " << line.substr(idx + 1)
  //             << std::endl;
  //   std::getline(stm, line);
  //   ++line_count;
  // }

  // const auto value = result.find(expected);
  // if (value != result.end()) {
  //   std::cout << "FOUND: " << value->second << std::endl;
  // }

  // csproj template for building resx files
  std::cout << "resx ref: "
            << "{ResXFile}" << std::endl;
  auto resx = std::string(cwd) + runfiles->Rlocation("{ResXFile}");
  if (resx.empty()) {
    std::cerr << "Couldn't find the resx file" << std::endl;
    return 404;
  }
  std::cout << "resx: " << resx << std::endl;

  // csproj template for building resx files
  std::cout << "csproj ref: "
            << "{CsProjTemplate}" << std::endl;
  auto csproj = runfiles->Rlocation("{CsProjTemplate}");
  if (csproj.empty()) {
    std::cerr << "Couldn't find the csproj file" << std::endl;
    return 404;
  }
  std::cout << "csproj: " << csproj << std::endl;

  std::ifstream ifs(csproj.c_str());
  std::string contents = slurp(ifs);

  std::string netFramework = "{NetFramework}";
  std::string manifest = "{ResXManifest}";

  std::string t_fmwk = "BazelResXFramework";
  contents.replace(contents.find(t_fmwk, 0), t_fmwk.length(), netFramework);

  std::string t_file = "BazelResXFile";
  contents.replace(contents.find(t_file, 0), t_file.length(), resx);

  std::string t_name = "BazelResXManifestResourceName";
  contents.replace(contents.find(t_name, 0), t_name.length(), manifest);

  auto program = std::string(argv[0]);
  auto programDir = program.substr(0, program.find_last_of("/\\"));
  std::cout << "programDir: " << programDir << std::endl;

  auto template_out = std::string(argv[1]);
  std::cout << "Template: " << template_out << std::endl;
  std::ofstream csprojfile;
  csprojfile.open(template_out);
  csprojfile << contents;
  csprojfile.close();

  // if (result != 0) {
  //   std::cout << "dotnet failed: " << errno << std::endl;
  //   return -1;
  // }

  // return result;
}