file(GLOB_RECURSE QOOL_COMMON_HEADERS "${CMAKE_CURRENT_SOURCE_DIR}/qoolcommon/*.hpp")
file(GLOB_RECURSE QOOL_INTERFACE_HEADERS "${CMAKE_CURRENT_SOURCE_DIR}/interfaces/*.h")

add_library(QoolCommon INTERFACE
    public_headers/qoolns.hpp.config
    public_headers/qoolversion.hpp.config
    ${QOOL_COMMON_HEADERS}
    ${QOOL_INTERFACE_HEADERS}
)

target_include_directories(QoolCommon
    INTERFACE ${CMAKE_CURRENT_SOURCE_DIR}
    INTERFACE ${CMAKE_CURRENT_SOURCE_DIR}/public_headers
    INTERFACE ${CMAKE_CURRENT_BINARY_DIR}/includes
)

target_link_libraries(QoolCommon INTERFACE Qt6::Core)
target_compile_features(QoolCommon INTERFACE cxx_std_17)


include_directories(${CMAKE_CURRENT_BINARY_DIR}/includes)
configure_file(public_headers/qoolversion.hpp.config includes/qoolversion.hpp)
configure_file(public_headers/qoolns.hpp.config includes/qoolns.hpp)
