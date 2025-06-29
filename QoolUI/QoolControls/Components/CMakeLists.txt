qt_add_qml_module(QoolControlsComponents
    URI Qool.Controls.Components
    VERSION ${QOOLUI_VERSION_QML}
    NAMESPACE ${QOOL_NS}

    IMPORTS Qool

    QML_FILES BasicControlFrame.qml
    QML_FILES BasicControlTitleText.qml
    QML_FILES ParallelVerticalBars.qml
    QML_FILES ControlHighlightCover.qml
    QML_FILES ControlLockedCover.qml

)




set_target_properties(QoolControlsComponents PROPERTIES
    MACOSX_BUNDLE_GUI_IDENTIFIER org.qoolui.controls.components
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_compile_definitions(QoolControlsComponents
    PRIVATE $<$<OR:$<CONFIG:Debug>,$<CONFIG:RelWithDebInfo>>:QT_QML_DEBUG>)
target_link_libraries(QoolControlsComponents
    PRIVATE Qt6::Quick
    PRIVATE QoolCommon
)

target_include_directories(QoolControlsComponents
    PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}
)
