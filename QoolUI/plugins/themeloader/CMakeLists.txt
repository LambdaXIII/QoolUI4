find_package(Qt6 REQUIRED COMPONENTS Xml)

qt_add_plugin(
  qool_themeloader_default
  SHARED
  CLASS_NAME
  "${QOOL_NS}::DefaultThemeLoader"
  # PRIVATE
  qool_themeloader_default.h
  qool_themeloader_default.cpp
  qool_themeloader_default.json
  qool_xml_theme_loader.h
  qool_xml_theme_loader.cpp
  qool_xml_theme_loader_impl.h
  qool_xml_theme_loader_impl.cpp)

qt_add_resources(qool_themeloader_default "qool_themes" PREFIX "/qoolui/themes"
                 FILES midnight.xml)

# target_sources(qool_themeloader_default)

set_target_properties(
  qool_themeloader_default
  PROPERTIES LIBRARY_OUTPUT_DIRECTORY "${QOOLUI_PLUGIN_OUTPUT_DIRECTORY}"
             LIBRARY_OUTPUT_NAME "QoolUIThemeLoader")

target_include_directories(qool_themeloader_default
                           PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

target_link_libraries(
  qool_themeloader_default
  PRIVATE Qt6::Core Qt6::Gui Qt6::Concurrent Qt6::Xml
  PRIVATE QoolCommon)
