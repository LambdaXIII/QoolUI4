
# set_source_files_properties(
#     _private/BGBox.qml
#     _private/DBGControl.qml
#     PROPERTIES
#     QT_QML_INTERNAL_TYPE TRUE
# )

qt_add_qml_module(QoolDebugControls
    URI Qool.DebugControls
    VERSION ${QOOLUI_VERSION_MAJOR}.${QOOLUI_VERSION_MINOR}
    NAMESPACE ${QOOL_NS}

    IMPORTS QtQuick.Dialogs
    IMPORTS Qool
    # DEPENDENCIES TARGET Qool

    QML_FILES Floater.qml
    QML_FILES PointIndicator.qml
    QML_FILES NumberSlider.qml
    QML_FILES ColorButton.qml
    QML_FILES ActionButton.qml
    QML_FILES _private/BGBox.qml
    QML_FILES _private/DBGControl.qml
    QML_FILES OctagonShapeHud.qml
    QML_FILES RectIndicator.qml
    QML_FILES
    QML_FILES
    QML_FILES _private/PropertyTipText.qml
    QML_FILES
    QML_FILES
    QML_FILES QoolWindowHud.qml

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
