file(GLOB QOOL_INTERNAL_QML_FILES "_private/*.qml")
set_source_files_properties(
  ${QOOL_INTERNAL_QML_FILES} PROPERTIES QT_QML_INTERNAL_TYPE TRUE
)

set_source_files_properties(
  Qore.qml PixelFont.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE
)

find_package(Qt6 REQUIRED COMPONENTS Core)

qt_add_qml_module(
  Qool
  URI Qool
  VERSION ${QOOLUI_VERSION_QML}
  NAMESPACE ${QOOL_NS}
  QML_FILES _private/OctagonRectangleShape.qml _private/QoolWindowBG.qml
            _private/QoolWindowCloseButton.qml _private/QoolWindowTitleItem.qml
  QML_FILES Qore.qml
  QML_FILES PixelFont.qml
  SOURCES qore/qool_singleton.h
          qore/qool_singleton.cpp
          qore/qool_extension_positions.h
          qore/qool_extension_positions.cpp
          qore/qool_literals.h
          qore/qool_geoutils.h
          qore/qool_geoutils.cpp
          datatypes/qool_vector2d.h
          datatypes/qool_vector2d.cpp
          datatypes/qool_polar2d.h
          datatypes/qool_polar2d.cpp
          utils/qool_smartobj.h
          utils/qool_smartobj.cpp
          utils/qool_spacehelper.h
          utils/qool_spacehelper.cpp
          utils/qool_numberranger.h
          utils/qool_numberranger.cpp
          utils/qool_itemtracker.h
          utils/qool_itemtracker.cpp
          shapecontrol/qool_shapecontrol.h
          shapecontrol/qool_shapecontrol.cpp
          shapecontrol/qool_qoolbox_settings.h
          shapecontrol/qool_qoolbox_settings.cpp
          shapecontrol/qool_shapecontrol_gadget.h
          shapecontrol/qool_shapecontrol_gadget.cpp
          shapecontrol/qool_qoolbox_shapecontrol.h
          shapecontrol/qool_qoolbox_shapecontrol.cpp
          shapecontrol/qool_shapecontainmentmask.h
          shapecontrol/qool_shapecontainmentmask.cpp
          shapecontrol/gadgets/qool_shapegadget_triangle.h
          shapecontrol/gadgets/qool_shapegadget_triangle.cpp
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
          models/qool_multirowselectionmodel.h
          models/qool_multirowselectionmodel.cpp
  QML_FILES OctagonShape.qml
            OctagonRoundedShape.qml
            QoolBox.qml
            DragMoveArea.qml
            BasicColorBehavior.qml
            BasicNumberBehavior.qml
            BasicRotationBehavior.qml
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
            CutSizeBinding.qml
            BasicLabel.qml
            DelayTimer.qml
            TimerLatch.qml
  SOURCES shapecontrol/gadgets/qool_shape_macros.hpp
  SOURCES shapecontrol/gadgets/qool_shapegadget_circle.h
          shapecontrol/gadgets/qool_shapegadget_circle.cpp
  SOURCES shapecontrol/gadgets/qool_shapegadget_rect.h
          shapecontrol/gadgets/qool_shapegadget_rect.cpp
  SOURCES shapecontrol/gadgets/qool_shapegadget_circlepoint.h
          shapecontrol/gadgets/qool_shapegadget_circlepoint.cpp
  SOURCES utils/qool_numbermapper.h utils/qool_numbermapper.cpp
  SOURCES utils/qool_colormapper.h utils/qool_colormapper.cpp
  SOURCES qool_numbernotifier.h qool_numbernotifier.cpp
)

qoolui_collect_assets(QOOL_ASSETS)
qt_add_resources(
  Qool "qoolui_assets"
  PREFIX "/qoolui/assets"
  BASE "assets"
  FILES ${QOOL_ASSETS}
)

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

target_include_directories(
  Qool
  PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}
  PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/shapecontrol"
  PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/shapecontrol/gadgets"
  PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/datatypes"
  PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/style"
  PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/utils"
  PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/qore"
  PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/models"
)
