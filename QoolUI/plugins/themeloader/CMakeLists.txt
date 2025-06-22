

qt_add_plugin(qool_themeloader_default
    CLASS_NAME "${QOOL_NS}::DefaultThemeLoader"
)

target_sources(qool_themeloader_default PRIVATE
    qool_themeloader_default.h
    qool_themeloader_default.cpp
    qool_themeloader_default.json
)

set_target_properties(qool_themeloader_default PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY "${QOOLUI_PLUGIN_OUTPUT_DIRECTORY}"
    LIBRARY_OUTPUT_NAME "QoolUIThemeLoader"
)

target_include_directories(qool_themeloader_default PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
)

target_link_libraries(qool_themeloader_default
    PRIVATE Qt6::Core
    PRIVATE QoolCommon
)
