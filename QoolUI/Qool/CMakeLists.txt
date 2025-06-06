qt_add_library(Qool SHARED)
qt_add_qml_module(Qool
    URI Qool
    RESOURCE_PREFIX /qoolui
    # OUTPUT_DIRECTORY QOOLUI/Qool
    VERSION 4.0
    QML_FILES MyItemControls.qml
    SOURCES myitem.cpp myitem.h
)

set_target_properties(Qool PROPERTIES
    MACOSX_BUNDLE_GUI_IDENTIFIER org.qoolui
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_compile_definitions(Qool
    PRIVATE $<$<OR:$<CONFIG:Debug>,$<CONFIG:RelWithDebInfo>>:QT_QML_DEBUG>)
target_link_libraries(Qool
    PRIVATE Qt6::Quick)

target_include_directories(Qool PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
