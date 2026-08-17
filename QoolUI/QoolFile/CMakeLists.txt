

qt_add_qml_module(QoolFile
    URI Qool.File
    VERSION ${QOOLUI_VERSION_QML}
    NAMESPACE ${QOOL_NS}

    IMPORTS Qool

    NO_GENERATE_PLUGIN_SOURCE
    NO_PLUGIN_OPTIONAL
    PLUGIN_TARGET QoolFile
    CLASS_NAME "Qool_FilePlugin"

    SOURCES qool_fileinfo_db.h qool_fileinfo_db.cpp
    SOURCES qool_fileinfo.h qool_fileinfo.cpp
    SOURCES qool_fileinfo_hq.h qool_fileinfo_hq.cpp
    SOURCES qool_fileicon_db.h qool_fileicon_db.cpp
    SOURCES qool_fileicon_hq.h qool_fileicon_hq.cpp
    SOURCES qool_fileicon_imageprovider.h qool_fileicon_imageprovider.cpp
    SOURCES qool_fileplugin.h qool_fileplugin.cpp
    SOURCES qool_fileinfolist_model.h qool_fileinfolist_model.cpp
    SOURCES qool_urlchecker.h qool_urlchecker.cpp

    QML_FILES FileDropper.qml
    QML_FILES FileInfoListViewToolBar.qml
    QML_FILES FileInfoListView.qml
    QML_FILES BasicFileInfoDisplay.qml
    QML_FILES FileInfoDelegate.qml
    QML_FILES FileDropArea.qml
    QML_FILES FileInfoListControl.qml
    QML_FILES SimpleFileItem.qml
)

set_target_properties(QoolFile PROPERTIES
    MACOSX_BUNDLE_GUI_IDENTIFIER org.qoolui.file
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
    # 构建树产物必须带一条 RUNPATH 条目（Linux/macOS）：
    # 当依赖全在系统默认路径（如发行版系统 Qt + QoolCommon 仅头文件）时
    # CMake 不写 RUNPATH；Qt 部署脚本（qt6_deploy_qml_imports）对 QML 插件
    # 用 file(RPATH_SET) 重写 RUNPATH——该命令只能改写既有条目、不能新增，
    # 缺条目即报 "No valid ELF RPATH or RUNPATH entry exists"。
    # $ORIGIN/../../../../ 指向构建根；构建树中该条目实际不被使用，仅作
    # 部署改写所需的既有占位（官方 Qt 安装器场景链非系统路径、CMake 自动
    # 写 RUNPATH，此处冗余但无害，部署时同样被整体重写）。
    BUILD_RPATH "$ORIGIN/../../../../"
)

target_compile_definitions(QoolFile
    PRIVATE $<$<OR:$<CONFIG:Debug>,$<CONFIG:RelWithDebInfo>>:QT_QML_DEBUG>)
target_link_libraries(QoolFile
    PRIVATE Qt6::Quick Qt6::Core
    PRIVATE QoolCommon
)

target_include_directories(QoolFile
    PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}
)
