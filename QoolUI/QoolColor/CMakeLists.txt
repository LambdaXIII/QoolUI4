# Qool.Color — v3 Color 模块迁移（ticket 01 骨架）
# 后续 ticket 逐步填充 SOURCES / QML_FILES（见 .scratch/color-migration/issues/）



qt_add_qml_module(QoolColor
    URI Qool.Color
    VERSION ${QOOLUI_VERSION_QML}
    NAMESPACE ${QOOL_NS}

    IMPORTS Qool Qool.Controls.Components

    SOURCES qool_colorassistant.h qool_colorassistant.cpp
    SOURCES qool_colorbank.h qool_colorbank.cpp
    SOURCES qool_colorhuecyclemodel.h qool_colorhuecyclemodel.cpp
    SOURCES qool_random_hsv_color_generator.h qool_random_hsv_color_generator.cpp
    SOURCES qool_crystal4containmentmask.h qool_crystal4containmentmask.cpp
    SOURCES qool_colornamedatabase.h qool_colornamedatabase.cpp

    QML_FILES ColorQuickPicker.qml
    QML_FILES ColorEdit.qml
    QML_FILES ColorPreviewer.qml
    QML_FILES HSVPanel.qml
    QML_FILES HSLPanel.qml
    QML_FILES RGBPanel.qml
    QML_FILES CMYKPanel.qml
    QML_FILES ColorNameList.qml
    QML_FILES ColorBankPanel.qml
)

# _private 私有件：**不注册进模块 qmldir**（不进 QML_FILES）——仅作为普通
# QML 文件打进 qrc（/qt/qml/Qool/Color/_private/ 路径），模块内文件经
# `import "_private"` 目录 import 使用；宿主 import Qool.Color 时 qmldir
# 无这些类型 → 不可见。这是 v3 同款机制（目录 import + 普通文件），
# 规避了 Qt 6.11 中 internal 类型无法被其他 internal 文件引用的限制
# （Color 私有件互引密集：滑块族/表面件互为依赖）。
file(GLOB QOOL_COLOR_INTERNAL_QML_FILES
    RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}
    "_private/*.qml"
    "_private/*.js")

# 私有件资源（必须位于 qt_add_qml_module 之后——target 形态的
# qt_add_resources 要求第一个参数是已存在的 target）。
qt_add_resources(QoolColor "color_private_qml"
    PREFIX "/qt/qml/Qool/Color"
    BASE ${CMAKE_CURRENT_SOURCE_DIR}
    FILES ${QOOL_COLOR_INTERNAL_QML_FILES}
)

target_link_libraries(QoolColor
    PRIVATE Qt6::Core Qt6::Quick
    PRIVATE Qool
    PRIVATE QoolCommon
)

target_include_directories(QoolColor
    PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}
)
