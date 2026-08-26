cmake_minimum_required(VERSION 3.30)

set(QOOLUI_VERSION_MAJOR 4)
set(QOOLUI_VERSION_MINOR 0)
set(QOOLUI_VERSION_PATCH 0)

set(QOOLUI_VERSION_FULL
    ${QOOLUI_VERSION_MAJOR}.${QOOLUI_VERSION_MINOR}.${QOOLUI_VERSION_PATCH}
)
set(QOOLUI_VERSION_QML ${QOOLUI_VERSION_MAJOR}.${QOOLUI_VERSION_MINOR})

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(QT_FORCE_CMP0156_TO_VALUE NEW)

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

add_library(QOOL_SETTINGS INTERFACE EXCLUDE_FROM_ALL
  .gitignore
  qool_qml_project_setup.cmake
  .clang-format
  .cmake-format.py
)

file(GLOB QOOL_AGENTS_CONTEXT_FILES
    RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}
    "**/AGENTS.md" "**/WATCHDOG.md" "**/RULES.md" "**/CONTEXT.md"
    "AGENTS.md" "WATCHDOG.md" "RULES.md" "CONTEXT.md"
)

add_library(QOOL_AGENTS INTERFACE EXCLUDE_FROM_ALL
  ${QOOL_AGENTS_CONTEXT_FILES}
)

file(GLOB_RECURSE QOOL_DOCUMENT_FILES
    RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}
    "docs/*.md" "docs/**/*.md" )

add_library(QOOL_DOCS INTERFACE EXCLUDE_FROM_ALL
  README.md
  CHANGELOG.md
  ${QOOL_DOCUMENT_FILES}
)

# workspaces
add_subdirectory(QoolUI)

if(QOOL_BUILD_EXAMPLEAPP)
  add_subdirectory(QoolUIExample)
endif()

if(QOOL_BUILD_TESTS)
  include(CTest)
  add_subdirectory(QoolUITests)
endif()

dump_list(QML_IMPORT_PATH)
