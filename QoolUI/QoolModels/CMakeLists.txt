
qt_add_qml_module(QoolModels
    URI Qool.Models
    VERSION ${QOOLUI_VERSION_QML}
    NAMESPACE ${QOOL_NS}

    SOURCES qool_multirowselectionmodel.h qool_multirowselectionmodel.cpp
    SOURCES
    QML_FILES
    SOURCES qool_objectpropertylistmodel.h qool_objectpropertylistmodel.cpp


)


set_target_properties(QoolModels PROPERTIES
    MACOSX_BUNDLE_GUI_IDENTIFIER org.qoolui.models
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_compile_definitions(QoolModels
    PRIVATE $<$<OR:$<CONFIG:Debug>,$<CONFIG:RelWithDebInfo>>:QT_QML_DEBUG>)
target_link_libraries(QoolModels
    PRIVATE Qt6::Quick
    PRIVATE QoolCommon
)

target_include_directories(QoolModels
    PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}
)
