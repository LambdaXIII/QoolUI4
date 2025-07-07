cmake_minimum_required(VERSION 3.30)

set(QOOLUI_VERSION_MAJOR 4)
set(QOOLUI_VERSION_MINOR 0)
set(QOOLUI_VERSION_PATCH 0)

set(QOOLUI_VERSION_FULL
    ${QOOLUI_VERSION_MAJOR}.${QOOLUI_VERSION_MINOR}.${QOOLUI_VERSION_PATCH})
set(QOOLUI_VERSION_QML ${QOOLUI_VERSION_MAJOR}.${QOOLUI_VERSION_MINOR})

project(
  QoolUI
  VERSION ${QOOLUI_VERSION_FULL}
  LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(
  Qt6 6.8
  COMPONENTS Core Quick QuickControls2 Concurrent Xml
  REQUIRED)

if(NOT DEFINED QOOLUI_QML_PROJECT_SETUP_LOADED)
  include(qool_qml_project_setup.cmake)
endif()

load_qoolui_standard_options()

qt_standard_project_setup(REQUIRES 6.8)

set(CMAKE_INSTALL_PREFIX
    "${CMAKE_BINARY_DIR}/install"
    CACHE PATH "deployment output dir" FORCE)

set(QOOL_NS "qoolui")
set(QOOL_PLUGIN_DIR "qoolplugins")

add_library(
  GENERAL_HELP
  INTERFACE
  EXCLUDE_FROM_ALL
  .clang-format
  README.md
  qool_qml_project_setup.cmake
  .gitignore)

add_subdirectory(QoolUI)
add_subdirectory(QoolUIExample)

dump_list(QML_IMPORT_PATH)
