qt_add_plugin(
  qool_colornameprovider_commonzh
  SHARED
  CLASS_NAME "CommonZhColorNameProvider"

  qool_colornameprovider_commonzh.h
  qool_colornameprovider_commonzh.cpp
  qool_colornameprovider_commonzh.json
)

qt_add_resources(COMMONZH_COLORS
  commonzh_colors/commonzh_color_resource.qrc
)

target_sources(qool_colornameprovider_commonzh PRIVATE ${COMMONZH_COLORS})

set_target_properties(
  qool_colornameprovider_commonzh
  PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY "${QOOLUI_PLUGIN_OUTPUT_DIRECTORY}"
    LIBRARY_OUTPUT_NAME "QoolUIColorNameProviderCommonZh"
)

target_include_directories(
  qool_colornameprovider_commonzh
  PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
)

target_link_libraries(
  qool_colornameprovider_commonzh
  PRIVATE
    Qt6::Core Qt6::Gui
    QoolCommon
)
