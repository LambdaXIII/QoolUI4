
configure_file(includes/qoolns.hpp.config includes/qoolns.hpp)
configure_file(includes/qoolversion.hpp.config includes/qoolversion.hpp)

file(GLOB QOOL_INTERFACE_HEADERS ${CMAKE_CURRENT_SOURCE_DIR}/interfaces/*.h)
# file(COPY ${QOOL_INTERFACE_HEADERS} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/includes)

# include_directories(${CMAKE_CURRENT_BINARY_DIR}/includes)

add_library(QoolIncludes INTERFACE
    includes/qoolns.hpp.config
    includes/qoolversion.hpp.config
    ${QOOL_INTERFACE_HEADERS}
)
target_include_directories(QoolIncludes
    INTERFACE ${CMAKE_CURRENT_BINARY_DIR}/includes
    INTERFACE ${CMAKE_CURRENT_SOURCE_DIR}/interfaces
)

# target_link_libraries(QoolIncludes
# INTERFACE Qt6::Qml
# )

add_subdirectory(QoolCommon)

add_subdirectory(Qool)
add_subdirectory(QoolControls)
add_subdirectory(QoolChat)
add_subdirectory(QoolDebug)

add_subdirectory(plugins)
