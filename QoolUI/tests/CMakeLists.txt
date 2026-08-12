# QoolUI 测试设施总入口
#
# 分层（与被测面一一对应）：
#   common/ — QoolCommon 纯 C++ 模板库（Qt Test，QCoreApplication，无 GUI）
#   core/   — Qool 核心 C++ 类型（Qt Test，直接编译被测 .cpp）
#   qml/    — QML 行为测试（Qt Quick Test，QUICK_TEST_MAIN harness）
#
# 运行通道（三选一，同一批标准 Qt Test exe）：
#   1. 聚合 target：cmake --build build --target run-tests
#      一条命令运行全部测试并反馈结果（日常首选，无 CTest 机制参与）
#   2. CTest：ctest --preset dev（或 ctest -R tst_）——CI/筛选/并行场景
#   3. 直接运行单个 exe：build/tst_*.exe
#
# Windows 部署与环境策略（本目录最复杂的部分，跨平台对照见下）：
# - POST_BUILD 把依赖 Qt DLL 复制到 exe 目录（$<TARGET_RUNTIME_DLLS>）——
#   exe 可独立运行，任何通道无需 PATH 魔法
# - 副作用：Qt 以 Qt6Core.dll 位置推导「安装前缀」→ 推导结果变成 exe 目录，
#   平台插件（plugins/platforms）与 Qt QML 模块（qml/）都找不到。
#   因此 WIN32 下统一注入：QT_PLUGIN_PATH=<Qt 前缀>/plugins、
#   QML_IMPORT_PATH=<Qt 前缀>/qml（仅 QML 测试需要后者，统一注入无害）。
# - Linux/macOS：系统 Qt 安装在标准路径，无需任何注入——所有 Windows 特有
#   逻辑都包在 if(WIN32) 内，其它平台零污染。
# - 勿引入 ENVIRONMENT/ENVIRONMENT_MODIFICATION 设 PATH 的 Windows 魔法：
#   ENVIRONMENT 的值按 ';' 拆分，多路径注入会损坏（CTest 已知陷阱）。

find_package(
  Qt6 REQUIRED COMPONENTS Test QuickTest Qml Quick
)

# Qt 安装前缀（Qt6_DIR = <prefix>/lib/cmake/Qt6，上三级回到前缀）
get_filename_component(QOOLUI_QT6_PREFIX "${Qt6_DIR}/../../.." ABSOLUTE)

# Windows：Qt 前缀路径注入（插件与 QML 模块）
set(QOOLUI_TEST_ENV "")
if(WIN32)
  set(QOOLUI_TEST_ENV
    "QT_PLUGIN_PATH=${QOOLUI_QT6_PREFIX}/plugins"
    "QML_IMPORT_PATH=${QOOLUI_QT6_PREFIX}/qml"
  )
endif()

# 测试 target 注册表（供聚合 run-tests target 收集）
set(QOOLUI_TEST_TARGETS "" CACHE INTERNAL "QoolUI test executables")

# 统一注册 C++ 测试 target：add_executable + Qt6::Test + CTest + DLL/插件部署
function(qoolui_add_cpp_test name)
  add_executable(${name} ${ARGN})
  target_link_libraries(${name} PRIVATE Qt6::Test)
  add_test(NAME ${name} COMMAND ${name})
  # 依赖 DLL 复制到 exe 目录（Windows 生效，其余平台展开为空）
  add_custom_command(
    TARGET ${name} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            $<TARGET_RUNTIME_DLLS:${name}> $<TARGET_FILE_DIR:${name}>
    COMMAND_EXPAND_LISTS
  )
  if(WIN32)
    # 平台插件目录（qwindows/qoffscreen 等），见本文件头部策略说明
    add_custom_command(
      TARGET ${name} POST_BUILD
      COMMAND ${CMAKE_COMMAND} -E copy_directory
              "${QOOLUI_QT6_PREFIX}/plugins/platforms"
              "$<TARGET_FILE_DIR:${name}>/plugins/platforms"
    )
    # CTest 通道注入 Qt 前缀路径
    set_tests_properties(
      ${name} PROPERTIES ENVIRONMENT_MODIFICATION
      "QT_PLUGIN_PATH=set:${QOOLUI_QT6_PREFIX}/plugins;QML_IMPORT_PATH=set:${QOOLUI_QT6_PREFIX}/qml"
    )
  endif()
  list(APPEND QOOLUI_TEST_TARGETS ${name})
  set(QOOLUI_TEST_TARGETS ${QOOLUI_TEST_TARGETS} CACHE INTERNAL "")
endfunction()

add_subdirectory(common)
add_subdirectory(core)
add_subdirectory(qml)

# ---- 聚合运行 target：cmake --build build --target run-tests ----
# 逐个运行全部测试 exe（顺序执行，任一失败即中止并返回非零）。
# Windows 经 cmake -E env 注入 Qt 前缀路径（插件/QML 模块）。
if(WIN32)
  add_custom_target(
    run-tests
    COMMAND ${CMAKE_COMMAND} -E env ${QOOLUI_TEST_ENV}
            $<TARGET_FILE:tst_qoolcommon_math>
    COMMAND ${CMAKE_COMMAND} -E env ${QOOLUI_TEST_ENV}
            $<TARGET_FILE:tst_qool_vector2d>
    COMMAND ${CMAKE_COMMAND} -E env ${QOOLUI_TEST_ENV}
            $<TARGET_FILE:tst_qool_numberranger>
    COMMAND ${CMAKE_COMMAND} -E env ${QOOLUI_TEST_ENV}
            $<TARGET_FILE:tst_qool_qml> -platform offscreen
    DEPENDS ${QOOLUI_TEST_TARGETS}
    USES_TERMINAL
  )
else()
  add_custom_target(
    run-tests
    COMMAND $<TARGET_FILE:tst_qoolcommon_math>
    COMMAND $<TARGET_FILE:tst_qool_vector2d>
    COMMAND $<TARGET_FILE:tst_qool_numberranger>
    COMMAND $<TARGET_FILE:tst_qool_qml> -platform offscreen
    DEPENDS ${QOOLUI_TEST_TARGETS}
    USES_TERMINAL
  )
endif()
