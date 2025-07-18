project(QoolUIExample
  VERSION ${QOOLUI_VERSION_FULL}
  LANGUAGES CXX
)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(
  Qt6 6.8
  COMPONENTS Core Quick LinguistTools
  REQUIRED
)
find_package(Qt6 REQUIRED COMPONENTS Core)

qt_standard_project_setup(
  REQUIRES 6.8
  I18N_SOURCE_LANGUAGE zh
  I18N_TRANSLATED_LANGUAGES zh en
)

qt_add_executable(appQoolUIExample main.cpp)

qt_add_qml_module(appQoolUIExample
  URI QoolUIExample
  VERSION 1.0
  # RESOURCE_PREFIX /qoolexample

  # IMPORTS Qool
  QML_FILES Main.qml
  QML_FILES pages/Page_QoolBox.qml
  QML_FILES pages/PaletteSheet.qml
  QML_FILES pages/components/QoolBoxShapeControlPanel.qml

  RESOURCES toc.xml
  QML_FILES PageListModel.qml
  QML_FILES PageListView.qml
  QML_FILES pages/Page_Playground.qml
  QML_FILES PageFrame.qml
  QML_FILES pages/BasicPage.qml
  QML_FILES pages/Page_Welcome.qml
  QML_FILES pages/Page_Buttons.qml
  QML_FILES pages/components/QoolTip.qml
  QML_FILES pages/components/QoolTipPanel.qml
  QML_FILES MainWindowToolBar.qml
  QML_FILES pages/components/SectionBar.qml
  QML_FILES pages/components/ExampleBasicButton.qml
)

qoolui_scan_assets_to(appQoolUIExample)
qt_add_resources(Qool "qoolexample_assets" PREFIX "/qoolexample" FILES
  ${QOOL_ASSETS}
)

qt_add_translations(appQoolUIExample
  TS_FILE_BASE qml
  TS_FILE_DIR i18n
  RESOURCE_PREFIX /qt/qml/QoolUIExample/i18n
  LRELEASE_OPTIONS -idbased
)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1. If
# you are developing for iOS or macOS you should consider setting an explicit,
# fixed bundle identifier manually though.
set_target_properties(
  appQoolUIExample
  PROPERTIES
  # MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appQoolUIExample
  MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
  MACOSX_BUNDLE_SHORT_VERSION_STRING
  ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
  MACOSX_BUNDLE TRUE
  WIN32_EXECUTABLE TRUE
)

target_link_libraries(appQoolUIExample PRIVATE Qt6::Quick)
target_link_libraries(appQoolUIExample PRIVATE Qt6::Core)

# include(GNUInstallDirs)

install(TARGETS appQoolUIExample
  BUNDLE DESTINATION . # LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

qt_generate_deploy_qml_app_script(
  TARGET appQoolUIExample
  OUTPUT_SCRIPT exp_dep_script
  DEPLOY_USER_QML_MODULES_ON_UNSUPPORTED_PLATFORM
  MACOS_BUNDLE_POST_BUILD
  NO_UNSUPPORTED_PLATFORM_ERROR
)

install(SCRIPT ${exp_dep_script})
