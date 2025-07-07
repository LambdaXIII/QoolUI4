find_package(Qt6 REQUIRED COMPONENTS Xml)
find_package(Qt6 REQUIRED COMPONENTS Core)

qt_add_plugin(qool_test_plugin SHARED CLASS_NAME "${QOOL_NS}::TestPlugin")

target_link_libraries(qool_test_plugin PRIVATE QoolIncludes Qt6::Core)
target_sources(qool_test_plugin PRIVATE qool_testplugin.h qool_testplugin.cpp
  qool_testplugin.json)

set_target_properties(
  qool_test_plugin
  PROPERTIES LIBRARY_OUTPUT_DIRECTORY "${QOOLUI_PLUGIN_OUTPUT_DIRECTORY}"
             LIBRARY_OUTPUT_NAME "QoolUITestPlugin")
