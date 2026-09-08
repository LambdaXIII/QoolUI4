qt_add_qml_module(
  QoolDialogs
  URI Qool.Dialogs
  VERSION ${QOOLUI_VERSION_QML}
  NAMESPACE ${QOOL_NS}

  IMPORTS Qool
  IMPORTS Qool.Controls.Components

  QML_FILES DialogSurface.qml
  QML_FILES QoolDialog.qml
  QML_FILES DialogButtonBox.qml
  QML_FILES DialogButton.qml
)

set_target_properties(
  QoolDialogs
  PROPERTIES MACOSX_BUNDLE_GUI_IDENTIFIER org.qoolui.dialogs
             MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
             MACOSX_BUNDLE_SHORT_VERSION_STRING
             ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
             MACOSX_BUNDLE TRUE
             WIN32_EXECUTABLE TRUE
)

target_compile_definitions(
  QoolDialogs
  PRIVATE $<$<OR:$<CONFIG:Debug>,$<CONFIG:RelWithDebInfo>>:QT_QML_DEBUG>
)

target_link_libraries(
  QoolDialogs
  PRIVATE Qt6::Quick
  PRIVATE QoolCommon
)

target_include_directories(
  QoolDialogs
  PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}
)
