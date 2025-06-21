file(GLOB QOOL_INTERNAL_QML_FILES "${CMAKE_CURRENT_SOURCE_DIR}/_private/*.qml")
set_source_files_properties(
    ${QOOL_INTERNAL_QML_FILES}
    PROPERTIES
    QT_QML_INTERNAL_TYPE TRUE
)
set_source_files_properties(
    Qore.qml
    QoolConstants.qml
    PixelFont.qml
    PROPERTIES QT_QML_SINGLETON_TYPE TRUE
)

qoolui_scan_assets_to(QOOL_ASSETS)

# qt_add_library(Qool STATIC)
qt_add_qml_module(Qool
    URI Qool
    # RESOURCE_PREFIX /qoolui
    VERSION 4.0
    NAMESPACE ${QOOL_NS}

    RESOURCES ${QOOL_ASSETS}

    QML_FILES Qore.qml
    QML_FILES QoolConstants.qml
    QML_FILES PixelFont.qml

    QML_FILES _private/QoolWindowCloseButton.qml
    QML_FILES _private/QoolWindowBG.qml
    QML_FILES _private/QoolWindowTitleItem.qml

    SOURCES qool_smartobj.h qool_smartobj.cpp

    SOURCES shapehelper/qool_octagonsettings.h shapehelper/qool_octagonsettings.cpp
    SOURCES shapehelper/qool_abstractshapehelper.h shapehelper/qool_abstractshapehelper.cpp
    SOURCES shapehelper/qool_octagonshapehelper.h shapehelper/qool_octagonshapehelper.cpp
    SOURCES shapehelper/qool_shapehelper.h shapehelper/qool_shapehelper.cpp
    QML_FILES OctagonShape.qml
    SOURCES shapehelper/gadgets/qool_shapehelpergadget.h shapehelper/gadgets/qool_shapehelpergadget.cpp
    SOURCES datatypes/qool_vector.h datatypes/qool_vector.cpp
    SOURCES shapehelper/gadgets/qool_shapehelpergadget_circle.h shapehelper/gadgets/qool_shapehelpergadget_circle.cpp
    SOURCES datatypes/qool_polar2d.h datatypes/qool_polar2d.cpp
    SOURCES shapehelper/qool_octagoncontainmentmasker.h shapehelper/qool_octagoncontainmentmasker.cpp
    QML_FILES OctagonRoundedShape.qml
    QML_FILES QoolBox.qml
    QML_FILES DragMoveArea.qml
    QML_FILES BasicColorBehavior.qml BasicNumberBehavior.qml
    QML_FILES PositionLocker.qml
    QML_FILES QoolWindowBasic.qml QoolWindow.qml
    QML_FILES DummyItem.qml
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


# add_subdirectory(HandyControls)
