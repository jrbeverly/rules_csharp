#include <fstream>
#include <ios>
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

  // csproj template for building resx files
  std::cout << "resx ref: "
            << "{ResXFile}" << std::endl;
  auto resx = runfiles->Rlocation("{ResXFile}");
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
  std::stringstream templateFileName;
  templateFileName << programDir << "\\" << "{TemplateName}";
  auto template_out = templateFileName.str();

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