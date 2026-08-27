# Qool 模块 QML 测试批次（模块目录，位于 QoolUITests/ 顶层，与 common/core 平级）
# 组织模型（AGENTS.md「QML 测试单元组织」）：每测试单元一个独立子目录 +
# 独立 target（qoolui_add_qml_test）——一 cpp 一 target 一宏值，Qt Creator
# 扫描器从 project macros 读 QUICK_TEST_SOURCE_DIR 定位 QML 目录。
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/QoolUITests/tst_qool_qml")

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

add_subdirectory(tst_centerplacer)
add_subdirectory(tst_itemanimatedresizer)
add_subdirectory(tst_style)
add_subdirectory(tst_cutsizeslocker)
add_subdirectory(tst_halfcrystal)
add_subdirectory(tst_qoolboxsettings)
add_subdirectory(tst_qoolbox)
add_subdirectory(tst_crystal)
add_subdirectory(tst_offsetprojector)
add_subdirectory(tst_timerlatch)
add_subdirectory(tst_dummyitem)
add_subdirectory(tst_positionlocker)
add_subdirectory(tst_cutsizebinding)
add_subdirectory(tst_numbermapper)
add_subdirectory(tst_colormapper)
add_subdirectory(tst_smartobj)
add_subdirectory(tst_spacehelper)
add_subdirectory(tst_positiontracker)
add_subdirectory(tst_itemtracker)
