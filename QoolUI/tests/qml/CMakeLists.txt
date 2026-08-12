# QML 行为测试（Qt Quick Test）
# harness（tst_qml_main.cpp）递归扫描本目录下所有 tst_*.qml 并执行；
# 编译期注入：
#   QUICK_TEST_SOURCE_DIR       — tst_*.qml 所在源码目录
#   QOOLUI_TEST_QML_IMPORT_PATH — Qool 模块构建输出目录（build/qml），
#                                 harness 在 qmlEngineAvailable 时注入引擎
# 运行：add_test 统一带 -platform offscreen（无头；目视渲染直接跑 exe 无参）

add_executable(tst_qool_qml tst_qml_main.cpp)

target_link_libraries(
  tst_qool_qml PRIVATE Qt6::QuickTest Qt6::Qml
)

target_compile_definitions(
  tst_qool_qml
  PRIVATE QUICK_TEST_SOURCE_DIR="${CMAKE_CURRENT_SOURCE_DIR}"
  PRIVATE QOOLUI_TEST_QML_IMPORT_PATH="${QT_QML_OUTPUT_DIRECTORY}"
)

add_test(NAME tst_qool_qml COMMAND tst_qool_qml -platform offscreen)

# 注册进聚合 run-tests（注册表驱动，见 tests/CMakeLists.txt）：
# QML 测试需要 -platform offscreen 无头运行（目视渲染直接跑 exe 无参）
list(APPEND QOOLUI_TEST_TARGETS tst_qool_qml)
set(QOOLUI_TEST_TARGETS ${QOOLUI_TEST_TARGETS} CACHE INTERNAL "")
set(QOOLUI_TEST_ARGS_tst_qool_qml "-platform;offscreen" CACHE INTERNAL "")

# 依赖 DLL 复制到 exe 目录（与 qoolui_add_cpp_test 相同的部署策略）
add_custom_command(
  TARGET tst_qool_qml POST_BUILD
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
          $<TARGET_RUNTIME_DLLS:tst_qool_qml> $<TARGET_FILE_DIR:tst_qool_qml>
  COMMAND_EXPAND_LISTS
)

if(WIN32)
  # 平台插件目录（见 tests/CMakeLists.txt 头部策略说明）
  add_custom_command(
    TARGET tst_qool_qml POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory
            "${QOOLUI_QT6_PREFIX}/plugins/platforms"
            "$<TARGET_FILE_DIR:tst_qool_qml>/plugins/platforms"
  )
  set_tests_properties(
    tst_qool_qml PROPERTIES ENVIRONMENT_MODIFICATION
    "QT_PLUGIN_PATH=set:${QOOLUI_QT6_PREFIX}/plugins;QML_IMPORT_PATH=set:${QOOLUI_QT6_PREFIX}/qml"
  )
endif()
