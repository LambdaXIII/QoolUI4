file(GLOB_RECURSE QOOL_COMMON_HEADERS "${CMAKE_CURRENT_SOURCE_DIR}/qoolcommon/*.hpp")
file(GLOB_RECURSE QOOL_INTERFACE_HEADERS "${CMAKE_CURRENT_SOURCE_DIR}/interfaces/*.h")

add_library(QoolCommon INTERFACE
    public_headers/qoolns.hpp
    ${QOOL_COMMON_HEADERS}
    ${QOOL_INTERFACE_HEADERS}
)

target_include_directories(QoolCommon
    INTERFACE ${CMAKE_CURRENT_SOURCE_DIR}
    INTERFACE ${CMAKE_CURRENT_SOURCE_DIR}/public_headers
)

target_compile_features(QoolCommon INTERFACE cxx_std_17)
