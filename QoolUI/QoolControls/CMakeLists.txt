
add_subdirectory("Components")


qt_add_qml_module(QoolControls
    URI Qool.Controls
    VERSION ${QOOLUI_VERSION_QML}
    NAMESPACE ${QOOL_NS}

    IMPORTS Qool
    QML_FILES
    QML_FILES
    QML_FILES
    QML_FILES ClickableText.qml
    QML_FILES
    QML_FILES SplitView.qml
    QML_FILES ProgressBar.qml
    QML_FILES
    QML_FILES Button.qml
    QML_FILES ToolButton.qml
    QML_FILES QoolControl.qml
    QML_FILES QoolButton.qml
    QML_FILES ActionInstantiator.qml
    QML_FILES ScrollBar.qml
    QML_FILES ScrollIndicator.qml
    QML_FILES ComboBox.qml
    QML_FILES SpinBox.qml
    QML_FILES Dial.qml
    QML_FILES TextField.qml
)


# _private 私有件：**不注册进模块 qmldir**（不进 QML_FILES）——仅作为普通
# QML 文件打进 qrc（/qt/qml/Qool/Controls/_private/ 路径），模块内文件经
# `import "_private"` 目录 import 使用；宿主 import Qool.Controls 时 qmldir
# 无这些类型 → 不可见。这是 v3 同款机制（目录 import + 普通文件），
# 规避了 Qt 6.11 中 internal 类型无法被其他 internal 文件引用的限制
# （QoolColor 同款；DialRangeArc 曾裸注册进 QML_FILES 被宿主可见，2026-08-07 纠正）。
file(GLOB QOOL_CONTROLS_INTERNAL_QML_FILES
    RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}
    "_private/*.qml"
    "_private/*.js")

# 私有件资源（必须位于 qt_add_qml_module 之后——target 形态的
# qt_add_resources 要求第一个参数是已存在的 target）。
qt_add_resources(QoolControls "controls_private_qml"
    PREFIX "/qt/qml/Qool/Controls"
    BASE ${CMAKE_CURRENT_SOURCE_DIR}
    FILES ${QOOL_CONTROLS_INTERNAL_QML_FILES}
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
