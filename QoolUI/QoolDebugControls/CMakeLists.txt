

qt_add_qml_module(QoolDebugControls
    URI Qool.DebugControls
    RESOURCE_PREFIX /qoolui
    NAMESPACE ${QOOL_NS}

    QML_FILES PointIndicator.qml
    QML_FILES NumberSlider.qml

)

set_target_properties(QoolDebugControls PROPERTIES
    MACOSX_BUNDLE_GUI_IDENTIFIER org.qoolui.debugcontrols
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_compile_definitions(QoolDebugControls
    PRIVATE $<$<OR:$<CONFIG:Debug>,$<CONFIG:RelWithDebInfo>>:QT_QML_DEBUG>)
target_link_libraries(QoolDebugControls
    PRIVATE Qt6::Quick
    PRIVATE QoolCommon
)

target_include_directories(QoolDebugControls
    PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}
)
