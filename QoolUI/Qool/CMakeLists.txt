file(GLOB QOOL_INTERNAL_QML_FILES "_private/*.qml")
set_source_files_properties(
  ${QOOL_INTERNAL_QML_FILES}
  PROPERTIES
  QT_QML_INTERNAL_TYPE TRUE
)

set_source_files_properties(
  Qore.qml
  QoolConstants.qml
  PixelFont.qml
  PROPERTIES
  QT_QML_SINGLETON_TYPE TRUE
)

qt_add_qml_module(Qool
  URI Qool
  VERSION ${QOOLUI_VERSION_QML}
  NAMESPACE ${QOOL_NS}

  QML_FILES

  _private/OctagonRectangleShape.qml
  _private/QoolWindowBG.qml
  _private/QoolWindowCloseButton.qml
  _private/QoolWindowTitleItem.qml

  QML_FILES Qore.qml
  QML_FILES PixelFont.qml

  SOURCES

  datatypes/qool_vector.h
  datatypes/qool_vector.cpp
  datatypes/qool_polar2d.h
  datatypes/qool_polar2d.cpp

  utils/qool_smartobj.h
  utils/qool_smartobj.cpp
  utils/qool_singleton.h
  utils/qool_singleton.cpp
  utils/qool_extension_positions.h
  utils/qool_extension_positions.cpp
  utils/qool_literals.h
  utils/qool_spacehelper.h
  utils/qool_spacehelper.cpp
  utils/qool_numberranger.h
  utils/qool_numberranger.cpp
  utils/qool_itemtracker.h
  utils/qool_itemtracker.cpp
  utils/qool_geoutils.h
  utils/qool_geoutils.cpp
  utils/qool_random_hsv_color_generator.h
  utils/qool_random_hsv_color_generator.cpp

  shapehelper/qool_qoolbox_settings.h
  shapehelper/qool_qoolbox_settings.cpp

  shapehelper/qool_abstractshapehelper.h
  shapehelper/qool_abstractshapehelper.cpp

  shapehelper/qool_qoolbox_shape_control.h
  shapehelper/qool_qoolbox_shape_control.cpp

  shapehelper/qool_shapehelper.h
  shapehelper/qool_shapehelper.cpp

  shapehelper/gadgets/qool_shapehelpergadget.h
  shapehelper/gadgets/qool_shapehelpergadget.cpp

  shapehelper/gadgets/qool_shapehelpergadget_circle.h
  shapehelper/gadgets/qool_shapehelpergadget_circle.cpp

  shapehelper/qool_octagoncontainmentmasker.h
  shapehelper/qool_octagoncontainmentmasker.cpp

  style/qool_style.h
  style/qool_style.cpp
  style/qool_theme.h
  style/qool_theme.cpp
  style/qool_theme_database.h
  style/qool_theme_database.cpp
  style/qool_system_theme.h
  style/qool_system_theme.cpp
  style/qool_stylegroupagent.h
  style/qool_stylegroupagent.cpp

  QML_FILES

  OctagonShape.qml
  OctagonRoundedShape.qml
  QoolBox.qml
  DragMoveArea.qml
  BasicColorBehavior.qml
  BasicNumberBehavior.qml
  BasicTextBehavior.qml
  PositionLocker.qml
  QoolWindowBasic.qml
  QoolWindow.qml
  DummyItem.qml
  QoolPalette.qml
  OctagonInternalShapePath.qml
  OctagonExternalShapePath.qml
  OctagonRoundedExternalShapePath.qml
  OctagonRoundedInternalShapePath.qml
  Floater.qml

)

qoolui_scan_assets_to(QOOL_ASSETS)
qt_add_resources(Qool "qoolui_assets" PREFIX "/qoolui" FILES ${QOOL_ASSETS})

set_target_properties(
  Qool
  PROPERTIES MACOSX_BUNDLE_GUI_IDENTIFIER org.qoolui
  MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
  MACOSX_BUNDLE_SHORT_VERSION_STRING
  ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
  MACOSX_BUNDLE TRUE
  WIN32_EXECUTABLE TRUE
)

target_compile_definitions(
  Qool PRIVATE $<$<OR:$<CONFIG:Debug>,$<CONFIG:RelWithDebInfo>>:QT_QML_DEBUG>
)
target_link_libraries(
  Qool
  PRIVATE Qt6::Core Qt6::Quick
  PRIVATE Qt6::Xml
  PRIVATE QoolCommon
)
target_link_libraries(Qool PRIVATE Qt6::Core Qt6::QuickControls2)
target_link_libraries(Qool PRIVATE Qt6::Core)
target_link_libraries(Qool PRIVATE Qt6::Core)
target_link_libraries(Qool PRIVATE Qt6::Core)
target_link_libraries(Qool PRIVATE Qt6::Core)

target_include_directories(
  Qool
  PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}
  PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/shapehelper"
  PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/shapehelper/gadgets"
  PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/datatypes"
  PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/style"
  PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/utils"
)

# add_subdirectory(HandyControls)
