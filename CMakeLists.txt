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

# ---- 测试设施 ----
# CTest 顶层启用：enable_testing() 必须顶层调用，ctest --preset dev 才在
# build/build-<kit>-<Type>/ 找到 CTestTestfile.cmake 并递归发现 QoolUITests 的测试（落地实测：
# include(CTest) 内聚到测试树时全新 configure 后 ctest 找不到测试——决策 6
# 修正为顶层条件化）。include(CTest) 在 QOOL_BUILD_TESTS 内 → 关闭时宿主
# 仍零 CTest 痕迹；BUILD_TESTING 为标准注册侧开关（-DBUILD_TESTING=OFF =
# 测试仍构建但 ctest 不注册）。构建侧总闸见 load_qoolui_standard_options()。

add_library(
  QOOL_GENERAL
  INTERFACE
  EXCLUDE_FROM_ALL
  .clang-format
  README.md
  qool_qml_project_setup.cmake
  .gitignore
  .cmake-format.py
  AGENTS.md
  CHANGELOG.md
)

add_subdirectory(QoolUI)
if(QOOL_BUILD_EXAMPLEAPP)
  add_subdirectory(QoolUIExample)
endif()
if(QOOL_BUILD_TESTS)
  include(CTest)
  add_subdirectory(QoolUITests)
endif()

dump_list(QML_IMPORT_PATH)
