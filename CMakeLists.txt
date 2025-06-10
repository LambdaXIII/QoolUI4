cmake_minimum_required(VERSION 3.21)

project(QoolUI VERSION 4.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
# set(QT_QML_OUTPUT_DIRECTORY  ${CMAKE_BINARY_DIR})

find_package(Qt6 6.2 COMPONENTS Core Quick REQUIRED)

qt_standard_project_setup(REQUIRES 6.5)

if(QT_KNOWN_POLICY_QPT0004)
  qt_policy(SET QPT0004 NEW)
endif()

add_library(GENERAL_HELP INTERFACE EXCLUDE_FROM_ALL
  .clang-format
  README.md
  qool_qml_project_setup.cmake
  .gitignore
)

if(NOT DEFINED QOOLUI_QML_PROJECT_SETUP_LOADED)
    include(qool_qml_project_setup.cmake)
endif()

load_qoolui_standard_options()

# set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})
# set(QT_QML_OUTPUT_DIRECTORY ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/qml)
# set(QOOLUI_PLUGIN_OUTPUT_DIRECTORY ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/qoolplugins)

append_qml_dir("${CMAKE_CURRENT_SOURCE_DIR}/QoolUI")

set(CMAKE_INSTALL_PREFIX "${CMAKE_BINARY_DIR}/install" CACHE PATH "deployment output dir" FORCE)



add_subdirectory(QoolUI/QoolCommon)
add_subdirectory(QoolUI/Qool)
add_subdirectory(QoolUIExample)
