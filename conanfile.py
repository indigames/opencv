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

    def requirements(self):
        if (self.settings.os == "Windows") and (self.name != "zlib"):
            self.requires("zlib/1.2.11@ige/test")
        self.requires("Python/3.7.6@ige/test")
        self.requires("numpy/1.19.5@ige/test")

    def build(self):
        self._generateCMakeProject()
        self._buildCMakeProject()
        self._package()

    def package(self):
        self.copy('*', src='build/install')

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

    def _package(self):
        os.chdir(Path(self.build_folder).parent.absolute())
        error_code = self.run(f'conan export-pkg . {self.name}/{self.version}@ige/test --profile=cmake/profiles/{str(self.settings.os).lower()}_{str(self.settings.arch).lower()} --force', ignore_errors=True)
        if(error_code != 0):
            print(f'Conan export failed, error code: {error_code}')
            exit(1)

