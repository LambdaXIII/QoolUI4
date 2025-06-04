cmake_minimum_required(VERSION 3.16)

project(QoolUI VERSION 4.0 LANGUAGES CXX)

set(CMAKE_AUTOMOC ON)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(QT_QML_OUTPUT_DIRECTORY  ${CMAKE_BINARY_DIR})

find_package(Qt6 6.2 COMPONENTS Quick REQUIRED)

add_library(GENERAL_HELP INTERFACE EXCLUDE_FROM_ALL
  .clang-format
  README.md
)

add_subdirectory(Qool)
add_subdirectory(QoolUIExample)
