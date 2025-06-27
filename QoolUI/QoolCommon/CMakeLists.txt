file(GLOB_RECURSE QOOL_COMMON_HEADERS "${CMAKE_CURRENT_SOURCE_DIR}/qoolcommon/*.hpp")

add_library(QoolCommon INTERFACE
    ${QOOL_COMMON_HEADERS}
)

target_include_directories(QoolCommon
    INTERFACE ${CMAKE_CURRENT_SOURCE_DIR}
)

target_link_libraries(QoolCommon
    INTERFACE Qt6::Core
    INTERFACE QoolIncludes
)

target_compile_features(QoolCommon INTERFACE cxx_std_17)


