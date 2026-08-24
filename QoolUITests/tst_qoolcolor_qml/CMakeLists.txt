# Qool.Color 模块 QML 测试批次（模块目录，位于 QoolUITests/ 顶层）
# 组织模型（AGENTS.md「QML 测试单元组织」）：每测试单元一个独立子目录 +
# 独立 target（qoolui_add_qml_test）——一 cpp 一 target 一宏值。
# 依赖链：Qool + QoolControls（EditableText 基础件）+ Qool.Color。
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/QoolUITests/tst_qoolcolor_qml")

# qt.conf（Qt 官方自包含机制）：仅 Windows 需要——DLL 复制使 Qt 前缀推导失效，
# 需 qt.conf 覆盖。Linux/macOS 系统 Qt 按标准路径定位插件与 QML 模块，跳过。
if(WIN32)
  file(MAKE_DIRECTORY "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}")
  configure_file(
    "${CMAKE_CURRENT_LIST_DIR}/../qt.conf.in"
    "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/qt.conf"
    @ONLY
  )
endif()

add_subdirectory(tst_colorchanneledit)
add_subdirectory(tst_colorassistant)
add_subdirectory(tst_hsvwheel)
add_subdirectory(tst_hslbox)
add_subdirectory(tst_colorchannelslider)
add_subdirectory(tst_colorchannelverticalslider)
add_subdirectory(tst_colorchannelcontrol)
