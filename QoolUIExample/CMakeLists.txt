# set_source_files_properties(
#     PageListModel.qml
#     PROPERTIES
#     QT_QML_INTERNAL_TYPE TRUE
# )


qt_add_executable(appQoolUIExample
    main.cpp
)

qt_add_qml_module(appQoolUIExample
    URI QoolUIExample
    VERSION 1.0
    # IMPORTS Qool
    QML_FILES
    Main.qml
    QML_FILES pages/Page_QoolBox.qml
    QML_FILES pages/PaletteSheet.qml
    QML_FILES pages/components/QoolBoxShapeControlPanel.qml
    QML_FILES
    RESOURCES toc.xml
    QML_FILES PageListModel.qml
    QML_FILES PageListView.qml
    QML_FILES pages/Page_Playground.qml
    QML_FILES PageFrame.qml
    QML_FILES pages/BasicPage.qml
    QML_FILES pages/Page_Welcome.qml
)

qoolui_scan_assets_to(appQoolUIExample)
qt_add_resources(Qool "qoolexample_assets"
    PREFIX "/qoolexample"
    FILES ${QOOL_ASSETS}
)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(appQoolUIExample PROPERTIES
    #    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appQoolUIExample
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appQoolUIExample
    PRIVATE Qt6::Quick
)

# include(GNUInstallDirs)

install(TARGETS appQoolUIExample
    BUNDLE DESTINATION .
    # LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
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
