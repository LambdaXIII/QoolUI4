set(QOOL_NS "qoolui")

file(GLOB QOOL_INTERNAL_QML_FILES "${CMAKE_CURRENT_SOURCE_DIR}/_private/*.qml")
set_source_files_properties(
    ${QOOL_INTERNAL_QML_FILES}
    PROPERTIES
        QT_QML_INTERNAL_TYPE TRUE
)

# qt_add_library(Qool STATIC)
qt_add_qml_module(Qool
    URI Qool
    RESOURCE_PREFIX /qoolui
    # OUTPUT_DIRECTORY QOOLUI/Qool
    VERSION 4.0
    NAMESPACE ${QOOL_NS}

    QML_FILES _private/QoolWindowCloseButtonFace.qml

    SOURCES shapehelper/qool_octagonsettings.h shapehelper/qool_octagonsettings.cpp
    SOURCES shapehelper/qool_abstractshapehelper.h shapehelper/qool_abstractshapehelper.cpp
    SOURCES shapehelper/qool_octagonshapehelper.h shapehelper/qool_octagonshapehelper.cpp
    SOURCES shapehelper/qool_shapehelper.h shapehelper/qool_shapehelper.cpp
    QML_FILES OctagonShape.qml
    SOURCES shapehelper/gadgets/qool_shapehelpergadget.h shapehelper/gadgets/qool_shapehelpergadget.cpp
    SOURCES datatypes/qool_vector.h datatypes/qool_vector.cpp
    SOURCES shapehelper/gadgets/qool_shapehelpergadget_circle.h shapehelper/gadgets/qool_shapehelpergadget_circle.cpp
    SOURCES datatypes/qool_polar2d.h datatypes/qool_polar2d.cpp
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
    PRIVATE Qt6::Quick
    PRIVATE QoolCommon
)

target_include_directories(Qool
    PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}
    PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/shapehelper"
    PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/shapehelper/gadgets"
    PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/datatypes"
)
