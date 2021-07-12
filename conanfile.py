import os
from pathlib import Path
from conans import ConanFile

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
    generators = "cmake_find_package"
    exports_sources = ""
    requires = []
    short_paths = True
    revision_mode="scm"

    def requirements(self):
        self.requires("Python/3.9.1@ige/test")
        self.requires("numpy/1.19.5@ige/test")

    def build(self):
        self._generateCMakeProject()
        self._buildCMakeProject()

    def package(self):
        self.copy('*', src='build/install')

    def package_info(self):
        self.cpp_info.libs = self.__collect_lib()
        self.cpp_info.includedirs  = self.__collect_include()
        self.cpp_info.defines = [f'USE_{self.name}'.upper()]

    def _generateCMakeProject(self):
        cmake_cmd = f'cmake {self.source_folder}'
        if self.settings.os == "Windows":
            if self.settings.arch == "x86":
                cmake_cmd += f' -A Win32'
            else:
                cmake_cmd += f' -A X64'
        elif self.settings.os == "Android":
            toolchain = Path(os.environ.get("ANDROID_NDK_ROOT")).absolute().as_posix() + '/build/cmake/android.toolchain.cmake'
            if self.settings.arch == "armv7":
                cmake_cmd += f' -G Ninja -DCMAKE_TOOLCHAIN_FILE={toolchain} -DANDROID_ABI=armeabi-v7a -DANDROID_PLATFORM=android-21 -DCMAKE_BUILD_TYPE=Release'
            else:
                cmake_cmd += f' -G Ninja -DCMAKE_TOOLCHAIN_FILE={toolchain} -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM=android-21 -DCMAKE_BUILD_TYPE=Release'
        elif self.settings.os == "iOS":
            toolchain = Path(self.source_folder).absolute().as_posix() + '/cmake/ios.toolchain.cmake'
            cmake_cmd += f' -G Xcode -DCMAKE_TOOLCHAIN_FILE={toolchain} -DIOS_DEPLOYMENT_TARGET=11.0 -DPLATFORM=OS64 -DCMAKE_BUILD_TYPE=Release'
        elif self.settings.os == "Macos":
            cmake_cmd += f' -G Xcode -DOSX=1 -DCMAKE_BUILD_TYPE=Release'
        else:
            print(f'Configuration not supported: platform = {self.settings.os}, arch = {self.settings.arch}')
            exit(1)

        error_code = self.run(cmake_cmd, ignore_errors=True)
        if(error_code != 0):
            print(f'CMake generation failed, error code: {error_code}')
            exit(1)

    def _buildCMakeProject(self):
        error_code = self.run('cmake --build . --config Release --target install', ignore_errors=True)
        if(error_code != 0):
            print(f'CMake build failed, error code: {error_code}')
            exit(1)

    def __collect_lib(self):
        libs = []
        for root, dirs, files in os.walk('lib'):
            for file in files:
                if file.endswith(".lib"):
                    fname = os.path.splitext(file)[0]
                    libs.append(fname)
                elif file.endswith(".a"):
                    fname = os.path.splitext(file)[0]
                    if fname.startswith('lib'):
                        fname = fname[fname.find('lib') + 3:]
                    libs.append(fname)
        for lib in libs:
            print(lib + ' ')
        return libs

    def __collect_include(self):
        inc_dirs = ['include']
        platform_inc_dir = ['include', 'src', 'source']
        if self.settings.os == "Windows":
            platform_inc_dir += ['pc', 'windows', 'win32', 'msvc']
        elif self.settings.os == "Android":
            platform_inc_dir += ['android', 'jni']
        elif self.settings.os == "Macos":
            platform_inc_dir += ['macos', 'mac', 'osx']
        elif self.settings.os == "iOS":
            platform_inc_dir += ['ios', 'iphone', 'iphoneos']
        return inc_dirs
