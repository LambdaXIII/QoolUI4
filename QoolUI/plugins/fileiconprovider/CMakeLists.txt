qt_add_plugin(
    qool_fileiconprovider_default
    SHARED
    CLASS_NAME "${QOOL_NS}::DefaultFileIconProvider"

    qool_fileiconprovider_default.h
    qool_fileiconprovider_default.cpp
    qool_fileiconprovider_default.json
)

qoolui_scan_assets_to(QOOL_FILEICONS)
qt_add_resources(
    qool_fileiconprovider_default "qool_fileiconprovider_default"
    PREFIX "/qoolui/fileicons"
    BASE assets
    FILES ${QOOL_FILEICONS}
)

set_target_properties(
    qool_fileiconprovider_default
    PROPERTIES
        LIBRARY_OUTPUT_DIRECTORY "${QOOLUI_PLUGIN_OUTPUT_DIRECTORY}"
        LIBRARY_OUTPUT_NAME "QoolUIFileIconProvider"
)

target_include_directories(
    qool_fileiconprovider_default
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}
)

target_link_libraries(
    qool_fileiconprovider_default
    PRIVATE
        Qt6::Core
        QoolCommon
)
