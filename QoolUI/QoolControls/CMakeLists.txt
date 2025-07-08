
add_subdirectory("Components")


qt_add_qml_module(QoolControls
    URI Qool.Controls
    VERSION ${QOOLUI_VERSION_QML}
    NAMESPACE ${QOOL_NS}

    IMPORTS Qool
    QML_FILES ControlFrame.qml
    QML_FILES BasicButton.qml
    QML_FILES
    QML_FILES ClickableText.qml
    QML_FILES
    QML_FILES SplitView.qml
    QML_FILES ProgressBar.qml



)




set_target_properties(QoolControls PROPERTIES
    MACOSX_BUNDLE_GUI_IDENTIFIER org.qoolui.controls
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_compile_definitions(QoolControls
    PRIVATE $<$<OR:$<CONFIG:Debug>,$<CONFIG:RelWithDebInfo>>:QT_QML_DEBUG>)
target_link_libraries(QoolControls
    PRIVATE Qt6::Quick
    PRIVATE QoolCommon
)

target_include_directories(QoolControls
    PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}
)
