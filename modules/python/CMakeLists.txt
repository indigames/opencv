# ----------------------------------------------------------------------------
#  CMake file for python support
# ----------------------------------------------------------------------------
if(DEFINED OPENCV_INITIAL_PASS)  # OpenCV build
# [IGE]: always build satic python binding
    if (NOT BUILD_SHARED_LIBS AND DEFINED NUMPY_INCLUDE_DIRS)
        set (PYTHON_INCLUDE_DIRS "${CMAKE_CURRENT_SOURCE_DIR}/../../igeLibs/Python/Include")
        set (NUMPY_INCLUDE_DIRS 
                "${CMAKE_CURRENT_SOURCE_DIR}/../../igeLibs/numpy/include"
                "${CMAKE_CURRENT_SOURCE_DIR}/../../igeLibs/numpy/include/numpy"
                "${CMAKE_CURRENT_SOURCE_DIR}/../../igeLibs/numpy/include/numpy/core"
                "${CMAKE_CURRENT_SOURCE_DIR}/../../igeLibs/numpy/include/numpy/core/include"
                "${CMAKE_CURRENT_SOURCE_DIR}/../../igeLibs/numpy/include/numpy/core/include/numpy"
                "${CMAKE_CURRENT_SOURCE_DIR}/../../igeLibs/numpy/include/numpy/core/include/numpy/random"
            )
        if (MSVC)
            list(APPEND PYTHON_INCLUDE_DIRS "${CMAKE_CURRENT_SOURCE_DIR}/../../igeLibs/Python/PC")
        elseif (OSX)
            list(APPEND PYTHON_INCLUDE_DIRS "${CMAKE_CURRENT_SOURCE_DIR}/../../igeLibs/Python/Mac")
        elseif (ANDROID)
            list(APPEND PYTHON_INCLUDE_DIRS "${CMAKE_CURRENT_SOURCE_DIR}/../../igeLibs/Python/Android")
        elseif (IOS)
            list(APPEND PYTHON_INCLUDE_DIRS "${CMAKE_CURRENT_SOURCE_DIR}/../../igeLibs/Python/IOS")
        endif ()
        
        set(cv2_src src2/cv2.cpp)
        
        add_library(cv2_python STATIC ${cv2_src})
        
        target_include_directories(cv2_python PRIVATE
            ${CMAKE_BINARY_DIR}
            ${PYTHON_INCLUDE_DIRS}
            ${NUMPY_INCLUDE_DIRS}       
            ${CMAKE_CURRENT_SOURCE_DIR}/../../include
            ${CMAKE_CURRENT_SOURCE_DIR}/../python_bindings_generator
            ${CMAKE_CURRENT_SOURCE_DIR}/../core/include
            ${CMAKE_CURRENT_SOURCE_DIR}/../flann/include
            ${CMAKE_CURRENT_SOURCE_DIR}/../imgproc/include
            ${CMAKE_CURRENT_SOURCE_DIR}/../ml/include
            ${CMAKE_CURRENT_SOURCE_DIR}/../photo/include
            ${CMAKE_CURRENT_SOURCE_DIR}/../dnn/include
            ${CMAKE_CURRENT_SOURCE_DIR}/../features2d/include
            ${CMAKE_CURRENT_SOURCE_DIR}/../imgcodecs/include
            ${CMAKE_CURRENT_SOURCE_DIR}/../videoio/include
            ${CMAKE_CURRENT_SOURCE_DIR}/../calib3d/include
            ${CMAKE_CURRENT_SOURCE_DIR}/../highgui/include
            ${CMAKE_CURRENT_SOURCE_DIR}/../objdetect/include
            ${CMAKE_CURRENT_SOURCE_DIR}/../stitching/include
            ${CMAKE_CURRENT_SOURCE_DIR}/../video/include
        )
        
        target_link_libraries(cv2_python opencv_calib3d opencv_core opencv_dnn opencv_features2d
                        opencv_flann opencv_highgui opencv_imgcodecs opencv_imgproc
                        opencv_ml opencv_objdetect opencv_photo opencv_stitching
                        opencv_video opencv_videoio)
    endif()
# [/IGE]

if(ANDROID OR APPLE_FRAMEWORK OR WINRT)
  ocv_module_disable_(python2)
  ocv_module_disable_(python3)
  return()
elseif(BUILD_opencv_world OR (WIN32 AND CMAKE_BUILD_TYPE STREQUAL "Debug"))
  if(NOT DEFINED BUILD_opencv_python2)
    set(__disable_python2 ON)
  endif()
  if(NOT DEFINED BUILD_opencv_python3)
    set(__disable_python3 ON)
  endif()
endif()

add_subdirectory(bindings)

add_subdirectory(test)

if(NOT OPENCV_SKIP_PYTHON_LOADER)
  include("./python_loader.cmake")
  message(STATUS "OpenCV Python: during development append to PYTHONPATH: ${CMAKE_BINARY_DIR}/python_loader")
endif()

if(__disable_python2)
  ocv_module_disable_(python2)
endif()
if(__disable_python3)
  ocv_module_disable_(python3)
endif()
if(__disable_python2 AND __disable_python3)
  return()
endif()

add_subdirectory(python2)
add_subdirectory(python3)

else()  # standalone build

cmake_minimum_required(VERSION 2.8.12)
include("./standalone.cmake")

endif()
