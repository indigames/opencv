@echo off

SET LIB_NAME=OpenCV

SET BUILD_DEBUG=0
SET BUILD_X86=0

echo COMPILING ...
SET PROJECT_DIR=%~dp0..

SET BUILD_DIR=%PROJECT_DIR%\build\pc
SET OUTPUT_DIR=%PROJECT_DIR%\igeLibs\%LIB_NAME%
SET OUTPUT_HEADER=%OUTPUT_DIR%\include
SET OUTPUT_LIBS_DEBUG=%OUTPUT_DIR%\libs\pc\Debug
SET OUTPUT_LIBS_RELEASE=%OUTPUT_DIR%\libs\pc

SET CALL_DIR=%CD%

if not exist "%PROJECT_DIR%\igeLibs" (
    mklink /J "%PROJECT_DIR%\igeLibs" "%IGE_LIBS%"
)

if not exist "%PROJECT_DIR%\igeLibs" (
    echo IGE_LIBS was not set, please clone igeLibs and set IGE_LIBS to the cloned path!
    goto ERROR
)

if not exist %OUTPUT_DIR% (
    mkdir %OUTPUT_DIR%
)

if not exist %BUILD_DIR% (
    mkdir %BUILD_DIR%
)

echo Cleaning up...
    if exist %OUTPUT_HEADER% (
        rmdir /s /q %OUTPUT_HEADER%
    )
    mkdir %OUTPUT_HEADER%

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

echo Fetching include headers...
    xcopy /q /s /y %~dp0..\include\*.h?? %OUTPUT_HEADER%\include\
    xcopy /q /s /y %~dp0..\modules\*.h?? %OUTPUT_HEADER%\modules\

cd %PROJECT_DIR%
if [%BUILD_X86%]==[1] (
    echo Compiling x86...
    if not exist %BUILD_DIR%\x86 (
        mkdir %BUILD_DIR%\x86
    )
    cd %BUILD_DIR%\x86
    echo Generating x86 CMAKE project ...
    cmake %PROJECT_DIR% -A Win32
    if %ERRORLEVEL% NEQ 0 goto ERROR

    if [%BUILD_DEBUG%]==[1] (
        echo Compiling x86 - Debug...
        cmake --build . --config Debug -- -m
        if %ERRORLEVEL% NEQ 0 goto ERROR
        xcopy /q /s /y lib\Debug\*.lib %OUTPUT_LIBS_DEBUG%\x86\
        xcopy /q /s /y bin\Debug\*.dll %OUTPUT_LIBS_DEBUG%\x86\
        REM xcopy /q /s /y lib\python3\Debug\*.pyd %OUTPUT_LIBS_DEBUG%\x86\
        xcopy /q /s /y 3rdparty\lib\Debug\*.lib %OUTPUT_LIBS_DEBUG%\x86\
    )

    echo Compiling x86 - Release...
    cmake --build . --config Release -- -m
    if %ERRORLEVEL% NEQ 0 goto ERROR
    xcopy /q /s /y lib\Release\*.lib %OUTPUT_LIBS_RELEASE%\x86\
    xcopy /q /s /y bin\Release\*.dll %OUTPUT_LIBS_RELEASE%\x86\
    REM xcopy /q /s /y lib\python3\Release\*.pyd %OUTPUT_LIBS_RELEASE%\x86\
    xcopy /q /s /y 3rdparty\lib\Release\*.lib %OUTPUT_LIBS_RELEASE%\x86\

    echo Compiling x86 DONE
)

cd %PROJECT_DIR%
echo Compiling x64...
    if not exist %BUILD_DIR%\x64 (
        mkdir %BUILD_DIR%\x64
    )
    echo Generating x64 CMAKE project ...
    cd %BUILD_DIR%\x64
    cmake %PROJECT_DIR% -A x64
    if %ERRORLEVEL% NEQ 0 goto ERROR

    if [%BUILD_DEBUG%]==[1] (
        echo Compiling x64 - Debug...
        cmake --build . --config Debug -- -m
        if %ERRORLEVEL% NEQ 0 goto ERROR
        xcopy /q /s /y lib\Debug\*.lib %OUTPUT_LIBS_DEBUG%\x64\
        xcopy /q /s /y bin\Debug\*.dll %OUTPUT_LIBS_DEBUG%\x64\
        REM xcopy /q /s /y lib\python3\Debug\*.pyd %OUTPUT_LIBS_DEBUG%\x64\
        xcopy /q /s /y 3rdparty\lib\Debug\*.lib %OUTPUT_LIBS_DEBUG%\x64\
    )

    echo Compiling x64 - Release...
    cmake --build . --config Release -- -m
    if %ERRORLEVEL% NEQ 0 goto ERROR
    xcopy /q /s /y lib\Release\*.lib %OUTPUT_LIBS_RELEASE%\x64\
    xcopy /q /s /y bin\Release\*.dll %OUTPUT_LIBS_RELEASE%\x64\
    REM xcopy /q /s /y lib\python3\Release\*.pyd %OUTPUT_LIBS_RELEASE%\x64\
    xcopy /q /s /y 3rdparty\lib\Release\*.lib %OUTPUT_LIBS_RELEASE%\x64\
echo Compiling x64 DONE

goto ALL_DONE

:ERROR
    echo ERROR OCCURED DURING COMPILING!

:ALL_DONE
    cd %CALL_DIR%
    echo COMPILING DONE!