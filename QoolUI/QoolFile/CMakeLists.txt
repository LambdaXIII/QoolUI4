
find_package(Qt6 REQUIRED COMPONENTS Core)
find_package(Qt6 REQUIRED COMPONENTS Core)
find_package(Qt6 REQUIRED COMPONENTS Core)
find_package(Qt6 REQUIRED COMPONENTS Core)
find_package(Qt6 REQUIRED COMPONENTS Core)
find_package(Qt6 REQUIRED COMPONENTS Core)

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
    SOURCES qool_fileicon_db.h qool_fileicon_db.cpp
    SOURCES qool_fileicon_imageprovider.h qool_fileicon_imageprovider.cpp
    SOURCES qool_fileplugin.h qool_fileplugin.cpp
    SOURCES qool_fileinfolist_model.h qool_fileinfolist_model.cpp
    SOURCES qool_filepathchecker.h qool_filepathchecker.cpp
)

# target_sources(QoolFilePlugin
# PUBLIC
#     qool_fileplugin.h qool_fileplugin.cpp
# )


set_target_properties(QoolFile PROPERTIES
    MACOSX_BUNDLE_GUI_IDENTIFIER org.qoolui.file
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_compile_definitions(QoolFile
    PRIVATE $<$<OR:$<CONFIG:Debug>,$<CONFIG:RelWithDebInfo>>:QT_QML_DEBUG>)
target_link_libraries(QoolFile
    PRIVATE Qt6::Quick
    PRIVATE QoolCommon
)
target_link_libraries(QoolFile PRIVATE Qt6::Core)
target_link_libraries(QoolFile PRIVATE Qt6::Core)
target_link_libraries(QoolFile PRIVATE Qt6::Core)
target_link_libraries(QoolFile PRIVATE Qt6::Core)
target_link_libraries(QoolFile PRIVATE Qt6::Core)
target_link_libraries(QoolFile PRIVATE Qt6::Core)

target_include_directories(QoolFile
    PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}
)
