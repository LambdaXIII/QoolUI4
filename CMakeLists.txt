cmake_minimum_required(VERSION 3.30)

set(QOOLUI_VERSION_MAJOR 4)
set(QOOLUI_VERSION_MINOR 0)
set(QOOLUI_VERSION_PATCH 0)

set(QOOLUI_VERSION_FULL
    ${QOOLUI_VERSION_MAJOR}.${QOOLUI_VERSION_MINOR}.${QOOLUI_VERSION_PATCH}
)
set(QOOLUI_VERSION_QML ${QOOLUI_VERSION_MAJOR}.${QOOLUI_VERSION_MINOR})


set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)



if(NOT DEFINED QOOLUI_QML_PROJECT_SETUP_LOADED)
  include(qool_qml_project_setup.cmake)
endif()

load_qoolui_standard_options()



set(CMAKE_INSTALL_PREFIX
    "${CMAKE_BINARY_DIR}/install"
    CACHE PATH "deployment output dir" FORCE
)

set(QOOL_NS "qoolui")
set(QOOL_PLUGIN_DIR "qoolplugins")




project(QoolUIBundle
        VERSION ${QOOLUI_VERSION_FULL}
        LANGUAGES CXX
)

add_library(
  GENERAL_HELP
  INTERFACE
  EXCLUDE_FROM_ALL
  .clang-format
  README.md
  qool_qml_project_setup.cmake
  .gitignore
  .cmake-format.py
)

add_subdirectory(QoolUI)
add_subdirectory(QoolUIExample)

dump_list(QML_IMPORT_PATH)
