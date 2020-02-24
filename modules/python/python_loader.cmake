# [IGE]: detect if Python header included
if(DEFINED PYTHON_INCLUDE_DIRS)
  set(PYTHONLIBS_FOUND TRUE)
  set(OPENCV_SKIP_PYTHON_LOADER TRUE)
  return()
endif()
# [/IGE]

ocv_assert(NOT OPENCV_SKIP_PYTHON_LOADER)

set(PYTHON_SOURCE_DIR "${CMAKE_CURRENT_LIST_DIR}")

if(OpenCV_FOUND)
  set(__loader_path "${OpenCV_BINARY_DIR}/python_loader")
  message(STATUS "OpenCV Python: during development append to PYTHONPATH: ${__loader_path}")
else()
  set(__loader_path "${CMAKE_BINARY_DIR}/python_loader")
endif()

set(__python_loader_install_tmp_path "${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/install/python_loader/")
if(DEFINED OPENCV_PYTHON_INSTALL_PATH)
  if(IS_ABSOLUTE "${OPENCV_PYTHON_INSTALL_PATH}")
    set(OpenCV_PYTHON_INSTALL_PATH_RELATIVE_CONFIGCMAKE "${CMAKE_INSTALL_PREFIX}/")
    set(CMAKE_PYTHON_EXTENSION_INSTALL_PATH_BASE "'${CMAKE_INSTALL_PREFIX}'")
  else()
    file(RELATIVE_PATH OpenCV_PYTHON_INSTALL_PATH_RELATIVE_CONFIGCMAKE "${CMAKE_INSTALL_PREFIX}/${OPENCV_PYTHON_INSTALL_PATH}/cv2" ${CMAKE_INSTALL_PREFIX})
    set(CMAKE_PYTHON_EXTENSION_INSTALL_PATH_BASE "os.path.join(LOADER_DIR, '${OpenCV_PYTHON_INSTALL_PATH_RELATIVE_CONFIGCMAKE}')")
  endif()
else()
  set(CMAKE_PYTHON_EXTENSION_INSTALL_PATH_BASE "os.path.join(LOADER_DIR, 'not_installed')")
endif()

set(PYTHON_LOADER_FILES
    "setup.py" "cv2/__init__.py"
    "cv2/load_config_py2.py" "cv2/load_config_py3.py"
)
foreach(fname ${PYTHON_LOADER_FILES})
  get_filename_component(__dir "${fname}" DIRECTORY)
  file(COPY "${PYTHON_SOURCE_DIR}/package/${fname}" DESTINATION "${__loader_path}/${__dir}")
  if(fname STREQUAL "setup.py")
    if(OPENCV_PYTHON_SETUP_PY_INSTALL_PATH)
      install(FILES "${PYTHON_SOURCE_DIR}/package/${fname}" DESTINATION "${OPENCV_PYTHON_SETUP_PY_INSTALL_PATH}" COMPONENT python)
    endif()
  elseif(DEFINED OPENCV_PYTHON_INSTALL_PATH)
    install(FILES "${PYTHON_SOURCE_DIR}/package/${fname}" DESTINATION "${OPENCV_PYTHON_INSTALL_PATH}/${__dir}" COMPONENT python)
  endif()
endforeach()

if(NOT OpenCV_FOUND)  # Ignore "standalone" builds of Python bindings
  if(WIN32)
    if(CMAKE_GENERATOR MATCHES "Visual Studio")
      list(APPEND CMAKE_PYTHON_BINARIES_PATH "'${EXECUTABLE_OUTPUT_PATH}/Release'")  # TODO: CMAKE_BUILD_TYPE is not defined
    else()
      list(APPEND CMAKE_PYTHON_BINARIES_PATH "'${EXECUTABLE_OUTPUT_PATH}'")
    endif()
  else()
    list(APPEND CMAKE_PYTHON_BINARIES_PATH "'${LIBRARY_OUTPUT_PATH}'")
  endif()
  string(REPLACE ";" ",\n    " CMAKE_PYTHON_BINARIES_PATH "${CMAKE_PYTHON_BINARIES_PATH}")
  configure_file("${PYTHON_SOURCE_DIR}/package/template/config.py.in" "${__loader_path}/cv2/config.py" @ONLY)

  # install
  if(DEFINED OPENCV_PYTHON_INSTALL_PATH)
    if(WIN32)
      list(APPEND CMAKE_PYTHON_BINARIES_INSTALL_PATH "os.path.join(${CMAKE_PYTHON_EXTENSION_INSTALL_PATH_BASE}, '${OPENCV_BIN_INSTALL_PATH}')")
    else()
      list(APPEND CMAKE_PYTHON_BINARIES_INSTALL_PATH "os.path.join(${CMAKE_PYTHON_EXTENSION_INSTALL_PATH_BASE}, '${OPENCV_LIB_INSTALL_PATH}')")
    endif()
    string(REPLACE ";" ",\n    " CMAKE_PYTHON_BINARIES_PATH "${CMAKE_PYTHON_BINARIES_INSTALL_PATH}")
    configure_file("${PYTHON_SOURCE_DIR}/package/template/config.py.in" "${__python_loader_install_tmp_path}/cv2/config.py" @ONLY)
    install(FILES "${__python_loader_install_tmp_path}/cv2/config.py" DESTINATION "${OPENCV_PYTHON_INSTALL_PATH}/cv2/" COMPONENT python)
  endif()
endif()
