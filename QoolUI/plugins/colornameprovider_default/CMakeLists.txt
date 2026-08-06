qt_add_plugin(
  qool_colornameprovider_default
  SHARED
  CLASS_NAME "DefaultColorNameProvider"

  qool_colornameprovider_default.h
  qool_colornameprovider_default.cpp
  qool_colornameprovider_default.json
)

set_target_properties(
  qool_colornameprovider_default
  PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY "${QOOLUI_PLUGIN_OUTPUT_DIRECTORY}"
    LIBRARY_OUTPUT_NAME "QoolUIColorNameProviderDefault"
)

target_include_directories(
  qool_colornameprovider_default
  PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
)

target_link_libraries(
  qool_colornameprovider_default
  PRIVATE
    Qt6::Core Qt6::Gui
    QoolCommon
)
