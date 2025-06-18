

qt_add_executable(appQoolUIExample
    main.cpp
)

qt_add_qml_module(appQoolUIExample
    URI QoolUIExample
    VERSION 1.0
    QML_FILES
        Main.qml
        QML_FILES pages/OctagonShapeTestPage.qml
        QML_FILES
        QML_FILES pages/components/OctagonShapeControlPanel.qml
        QML_FILES
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
