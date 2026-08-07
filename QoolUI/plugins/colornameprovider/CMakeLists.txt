# ColorNameProvider 接口包：同接口多插件按包组织，不同 target 共存
# （default：Qt 内置色名，priority 0；commonzh：中文色名，priority -1）——
# 插件组织惯例见 AGENTS.md「插件约定」。

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
