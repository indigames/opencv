@echo off
setlocal enabledelayedexpansion

SET LIB_NAME=OpenCV

SET BUILD_DEBUG=0

echo COMPILING PC...
SET PROJECT_DIR=%~dp0..

SET BUILD_DIR=%PROJECT_DIR%\build\android
SET OUTPUT_DIR=%PROJECT_DIR%\igeLibs\%LIB_NAME%
SET OUTPUT_LIBS_DEBUG=%OUTPUT_DIR%\libs\Debug\android
SET OUTPUT_LIBS_RELEASE=%OUTPUT_DIR%\libs\Release\android

if not exist "%ANDROID_SDK_ROOT%" (
    if exist "%ANDROID_HOME%" (
        set ANDROID_SDK_ROOT=%ANDROID_HOME%
    ) else (
        if exist "%USERPROFILE%\AppData\Local\Android\sdk" (
            set ANDROID_SDK_ROOT=%USERPROFILE%\AppData\Local\Android\sdk
        ) else (
            echo ERROR: SDK NOT FOUND!
            goto ERROR
        )
    )
)
echo SDK: !ANDROID_SDK_ROOT!

if not exist "%ANDROID_NDK_ROOT%" (
    if exist "%ANDROID_SDK_ROOT%\ndk-bundle" (
        set ANDROID_NDK_ROOT=%ANDROID_SDK_ROOT%\ndk-bundle
    ) else (
        if exist "%ANDROID_SDK_ROOT%\ndk\20.1.5948944" (
            set ANDROID_NDK_ROOT=%ANDROID_SDK_ROOT%\ndk\20.1.5948944
        ) else  (
            if exist "%ANDROID_SDK_ROOT%\ndk\21.0.6113669" (
                set ANDROID_NDK_ROOT=%ANDROID_SDK_ROOT%\ndk\21.0.6113669
            ) else (
                echo ERROR: NDK NOT FOUND!
                goto ERROR
            )
        )
    )
)

echo NDK: !ANDROID_NDK_ROOT!

set ANDROID_TOOLCHAIN=!ANDROID_NDK_ROOT!\build\cmake\android.toolchain.cmake

if not exist %OUTPUT_DIR% (
    mkdir %OUTPUT_DIR%
)

if not exist %BUILD_DIR% (
    mkdir %BUILD_DIR%
)

echo Cleaning up...
    if [%BUILD_DEBUG%]==[1] (
        if exist %OUTPUT_LIBS_DEBUG% (
            rmdir /s /q %OUTPUT_LIBS_DEBUG%
        )
        mkdir %OUTPUT_LIBS_DEBUG%
    )

    if exist %OUTPUT_LIBS_RELEASE% (
        rmdir /s /q %OUTPUT_LIBS_RELEASE%
    )
    mkdir %OUTPUT_LIBS_RELEASE%

cd %PROJECT_DIR%
echo Compiling armeabi-v7a...
    if [%BUILD_DEBUG%]==[1] (
        if not exist %BUILD_DIR%\armeabi-v7a\Debug (
            mkdir %BUILD_DIR%\armeabi-v7a\Debug
        )
        cd %BUILD_DIR%\armeabi-v7a\Debug
        echo Generating armeabi-v7a Debug CMAKE project ...
        cmake -G Ninja -DCMAKE_TOOLCHAIN_FILE=!ANDROID_TOOLCHAIN! -DANDROID_ABI=armeabi-v7a -DANDROID_PLATFORM=android-21 -DCMAKE_BUILD_TYPE=Debug %PROJECT_DIR%
        if %ERRORLEVEL% NEQ 0 goto ERROR

        echo Compiling armeabi-v7a - Debug...
        cmake --build .
        if %ERRORLEVEL% NEQ 0 goto ERROR
        xcopy /q /y lib\armeabi-v7a\*.a %OUTPUT_LIBS_DEBUG%\armeabi-v7a\
        xcopy /q /y lib\armeabi-v7a\*.so %OUTPUT_LIBS_DEBUG%\armeabi-v7a\
    )
    
    if not exist %BUILD_DIR%\armeabi-v7a\Release (
        mkdir %BUILD_DIR%\armeabi-v7a\Release
    )
    cd %BUILD_DIR%\armeabi-v7a\Release
    echo Generating armeabi-v7a Release CMAKE project ...
    cmake -G Ninja -DCMAKE_TOOLCHAIN_FILE=!ANDROID_TOOLCHAIN! -DANDROID_ABI=armeabi-v7a -DANDROID_PLATFORM=android-21 -DCMAKE_BUILD_TYPE=Release %PROJECT_DIR%

    echo Compiling armeabi-v7a - Release...
    cmake --build .
    if %ERRORLEVEL% NEQ 0 goto ERROR
    xcopy /q /y lib\armeabi-v7a\*.a %OUTPUT_LIBS_RELEASE%\armeabi-v7a\
    xcopy /q /y lib\armeabi-v7a\*.so %OUTPUT_LIBS_RELEASE%\armeabi-v7a\
echo Compiling armeabi-v7a DONE

cd %PROJECT_DIR%
echo Compiling arm64-v8a...
    if [%BUILD_DEBUG%]==[1] (
        if not exist %BUILD_DIR%\arm64-v8a\Debug (
            mkdir %BUILD_DIR%\arm64-v8a\Debug
        )
        cd %BUILD_DIR%\arm64-v8a\Debug
        echo Generating arm64-v8a Debug CMAKE project ...
        cmake -G Ninja -DCMAKE_TOOLCHAIN_FILE=!ANDROID_TOOLCHAIN! -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM=android-21 -DANDROID_ARM_MODE=arm -DANDROID_ARM_NEON=TRUE -DCMAKE_BUILD_TYPE=Debug %PROJECT_DIR%
        if %ERRORLEVEL% NEQ 0 goto ERROR

        echo Compiling arm64-v8a - Debug...
        cmake --build .
        if %ERRORLEVEL% NEQ 0 goto ERROR
        xcopy /q /y lib\arm64-v8a\*.a %OUTPUT_LIBS_DEBUG%\arm64-v8a\
        xcopy /q /y lib\arm64-v8a\*.so %OUTPUT_LIBS_DEBUG%\arm64-v8a\
    )
    
    if not exist %BUILD_DIR%\arm64-v8a\Release (
        mkdir %BUILD_DIR%\arm64-v8a\Release
    )
    cd %BUILD_DIR%\arm64-v8a\Release
    echo Generating arm64-v8a Release CMAKE project ...
    cmake -G Ninja -DCMAKE_TOOLCHAIN_FILE=!ANDROID_TOOLCHAIN! -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM=android-21 -DCMAKE_BUILD_TYPE=Release %PROJECT_DIR%

    echo Compiling arm64-v8a - Release...
    cmake --build .
    if %ERRORLEVEL% NEQ 0 goto ERROR
    xcopy /q /y lib\arm64-v8a\*.a %OUTPUT_LIBS_RELEASE%\arm64-v8a\
    xcopy /q /y lib\arm64-v8a\*.so %OUTPUT_LIBS_RELEASE%\arm64-v8a\
echo Compiling arm64-v8a DONE

cd %PROJECT_DIR%
echo Compiling x86...
    if [%BUILD_DEBUG%]==[1] (
        if not exist %BUILD_DIR%\x86\Debug (
            mkdir %BUILD_DIR%\x86\Debug
        )
        cd %BUILD_DIR%\x86\Debug
        echo Generating x86 Debug CMAKE project ...
        cmake -G Ninja -DCMAKE_TOOLCHAIN_FILE=!ANDROID_TOOLCHAIN! -DANDROID_ABI=x86 -DANDROID_PLATFORM=android-21 -DCMAKE_BUILD_TYPE=Debug %PROJECT_DIR%
        if %ERRORLEVEL% NEQ 0 goto ERROR

        echo Compiling x86 - Debug...
        cmake --build .
        if %ERRORLEVEL% NEQ 0 goto ERROR
        xcopy /q /y lib\x86\*.a %OUTPUT_LIBS_DEBUG%\x86\
        xcopy /q /y lib\x86\*.so %OUTPUT_LIBS_DEBUG%\x86\
    )
    
    if not exist %BUILD_DIR%\x86\Release (
        mkdir %BUILD_DIR%\x86\Release
    )
    cd %BUILD_DIR%\x86\Release
    echo Generating x86 Release CMAKE project ...
    cmake -G Ninja -DCMAKE_TOOLCHAIN_FILE=!ANDROID_TOOLCHAIN! -DANDROID_ABI=x86 -DANDROID_PLATFORM=android-21 -DCMAKE_BUILD_TYPE=Release %PROJECT_DIR%

    echo Compiling x86 - Release...
    cmake --build .
    if %ERRORLEVEL% NEQ 0 goto ERROR
    xcopy /q /y lib\x86\*.a %OUTPUT_LIBS_RELEASE%\x86\
    xcopy /q /y lib\x86\*.so %OUTPUT_LIBS_RELEASE%\x86\
echo Compiling x86 DONE

cd %PROJECT_DIR%
echo Compiling x86_64...
    if [%BUILD_DEBUG%]==[1] (
        if not exist %BUILD_DIR%\x86_64\Debug (
            mkdir %BUILD_DIR%\x86_64\Debug
        )
        cd %BUILD_DIR%\x86_64\Debug
        echo Generating x86_64 Debug CMAKE project ...
        cmake -G Ninja -DCMAKE_TOOLCHAIN_FILE=!ANDROID_TOOLCHAIN! -DANDROID_ABI=x86_64 -DANDROID_PLATFORM=android-21 -DCMAKE_BUILD_TYPE=Debug %PROJECT_DIR%
        if %ERRORLEVEL% NEQ 0 goto ERROR

        echo Compiling x86_64 - Debug...
        cmake --build .
        if %ERRORLEVEL% NEQ 0 goto ERROR
        xcopy /q /y lib\x86_64\*.a %OUTPUT_LIBS_DEBUG%\x86_64\
        xcopy /q /y lib\x86_64\*.so %OUTPUT_LIBS_DEBUG%\x86_64\
    )
    
    if not exist %BUILD_DIR%\x86_64\Release (
        mkdir %BUILD_DIR%\x86_64\Release
    )
    cd %BUILD_DIR%\x86_64\Release
    echo Generating x86_64 Release CMAKE project ...
    cmake -G Ninja -DCMAKE_TOOLCHAIN_FILE=!ANDROID_TOOLCHAIN! -DANDROID_ABI=x86_64 -DANDROID_PLATFORM=android-21 -DCMAKE_BUILD_TYPE=Release %PROJECT_DIR%

    echo Compiling x86_64 - Release...
    cmake --build .
    if %ERRORLEVEL% NEQ 0 goto ERROR
    xcopy /q /y lib\x86_64\*.a %OUTPUT_LIBS_RELEASE%\x86_64\
    xcopy /q /y lib\x86_64\*.so %OUTPUT_LIBS_RELEASE%\x86_64\
echo Compiling x86_64 DONE

goto ALL_DONE

:ERROR
	echo ERROR OCCURED DURING COMPILING

:ALL_DONE
	cd %PROJECT_DIR%
	echo COMPILING DONE!