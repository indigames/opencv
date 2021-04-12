import os
from conans import ConanFile, CMake

class IgeConan(ConanFile):
    name = 'opencv'
    version = '4.1.2'
    license = "MIT"
    author = "Indi Games"
    url = "https://github.com/indigames"
    description = name + " library for IGE Engine"
    topics = ("#Python", "#IGE", "#Games")
    settings = "os", "compiler", "build_type", "arch"
    options = {"shared": [True, False], "fPIC": [True, False]}
    default_options = {"shared": False, "fPIC": True}
    generators = "cmake"
    exports_sources = ""
    requires = []
    short_paths = True

    def requirements(self):
        self.requires("Python/3.7.6@ige/test")
        self.requires("numpy/1.19.5@ige/test")
        if (self.settings.os == "Windows") and (self.name != "zlib"):
            self.requires("zlib/1.2.11@ige/test")

    def package(self):
        output_dir = os.path.normpath(os.path.relpath(os.environ['OUTPUT_DIR'], os.environ['PROJECT_DIR']))
        self.copy("*", dst="include", src=os.path.join(output_dir, "include"))
        if self.settings.os == "Windows":
            if self.settings.arch == "x86":
                self.copy("*", dst="lib", src=os.path.join(output_dir, "libs/windows/x86"))
            else:
                self.copy("*", dst="lib", src=os.path.join(output_dir, "libs/windows/x86_64"))
        elif self.settings.os == "Android":
            if self.settings.arch == "armv7":
                self.copy("*", dst="lib", src=os.path.join(output_dir, "libs/android/armv7"))
            elif self.settings.arch == "armv8":
                self.copy("*", dst="lib", src=os.path.join(output_dir, "libs/android/armv8"))
            elif self.settings.arch == "x86":
                self.copy("*", dst="lib", src=os.path.join(output_dir, "libs/android/x86"))
            elif self.settings.arch == "x86_64":
                self.copy("*", dst="lib", src=os.path.join(output_dir, "libs/android/x86_64"))
        elif self.settings.os == "Macos":
            self.copy("*", dst="lib", src=os.path.join(output_dir, "libs/macos/x64"))
        else:
            self.copy("*", dst="lib", src=os.path.join(output_dir, "libs/ios/arm64"))

    def package_info(self):
        self.cpp_info.libs = self.__collect_lib('lib')
        self.cpp_info.includedirs  = self.__collect_include('include')
        self.cpp_info.defines = [f'USE_{self.name}'.upper()]

    def __collect_lib(self, lib_dir):
        libs = []
        for root, dirs, files in os.walk(lib_dir):
            for file in files:
                if file.endswith(".lib"):
                    fname = os.path.splitext(file)[0]
                    libs.append(fname)
                elif file.endswith(".a"):
                    fname = os.path.splitext(file)[0]
                    if fname.startswith('lib'):
                        fname = fname[fname.find('lib') + 3:]
                    libs.append(fname)
        if (self.settings.os == "Windows") and (self.name != "zlib"):
            libs.append('zlibstatic')
        return libs

    def __collect_include(self, inc_dir):
        inc_dirs = ['include']
        platform_inc_dir = ['include', 'src', 'source']
        if self.settings.os == "Windows":
            platform_inc_dir += ['pc', 'windows', 'win32', 'msvc']
        elif self.settings.os == "Android":
            platform_inc_dir += ['android']
        elif self.settings.os == "Macos":
            platform_inc_dir += ['macos', 'mac', 'osx']
        else:
            platform_inc_dir += ['ios']
        for root, dirs, files in os.walk(inc_dir):
            for d in dirs:
                if d.lower() in platform_inc_dir:
                    inc_dirs.append(os.path.relpath(os.path.join('include', root, d), inc_dir).replace('\\', '/'))
        return inc_dirs