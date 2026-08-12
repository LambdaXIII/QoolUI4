# QoolUI 测试设施总入口
#
# 分层（与被测面一一对应）：
#   common/ — QoolCommon 纯 C++ 模板库（Qt Test，QCoreApplication，无 GUI）
#   core/   — Qool 核心 C++ 类型（Qt Test，直接编译被测 .cpp）
#   qml/    — QML 行为测试（Qt Quick Test，QUICK_TEST_MAIN harness）
#
# 自包含说明：本树位于仓库顶级（与 QoolUI/ 平级），不继承 QoolUI 的
# qt_standard_project_setup() 目录作用域——AUTOMOC 等编译属性需自行声明。
#
# Windows 前缀解析策略（qt.conf 自包含方案，原 spec 5.2）：
# - POST_BUILD 把依赖 Qt DLL 复制到 exe 目录（$<TARGET_RUNTIME_DLLS>）——
#   exe 可独立运行，任何通道无需 PATH 魔法
# - 副作用：Qt 以 Qt6Core.dll 位置推导「安装前缀」→ 推导结果变成 exe 目录，
#   平台插件（plugins/）与 Qt QML 模块（qml/）都找不到
# - 补偿：每层 configure 期生成 qt.conf（exe 旁）——Qt 官方自包含机制
#   （QLibraryInfo 读取），Prefix 覆盖推导，Plugins/QmlImports 路径随之
#   正确。任何运行通道（QtCreator 测试面板/run-tests/ctest/直接运行）
#   无需环境注入；源码不含安装路径（用户约定 5）
# - 需要 qt.conf 的层：qml/（平台插件 + Qool QML 模块）、core/（链接
#   Qt6::Quick → QTEST_MAIN 展开为 QGuiApplication，构造加载平台插件）；
#   common/ 纯 QCoreApplication，不加载插件，无需
# - Linux/macOS：系统 Qt 安装在标准路径，无需任何注入——qt.conf 生成
#   逻辑不依赖平台，但 QOOLUI_QT6_PREFIX 推导在标准安装下亦正确
# - 勿引入 ENVIRONMENT/ENVIRONMENT_MODIFICATION 设 PATH 的 Windows 魔法：
#   ENVIRONMENT 的值按 ';' 拆分，多路径注入会损坏（CTest 已知陷阱）。

# project() 独立声明（原 spec 6.5，定案见 AGENTS.md「CMake 组织」）：
# PROJECT_SOURCE_DIR/BINARY_DIR 指向本树；子目录 project() 重置 PROJECT_*
# 变量——本树内部引用模块路径一律相对路径，不引用 QoolUI 的 PROJECT_*。
# VERSION 来自父作用域变量（非 PROJECT_*）。
# CTest 注册：enable_testing 由顶层 include(CTest)（QOOL_BUILD_TESTS 内）
# 提供——ctest --preset dev 从顶层递归发现本树测试（落地修正：内聚到本树
# 时全新 configure 后顶层无 CTestTestfile，ctest 找不到测试）。
project(QoolUITests VERSION ${QOOLUI_VERSION_FULL} LANGUAGES CXX)

set(CMAKE_AUTOMOC ON)

# 共享测试头（INTERFACE 库，仅头文件承载 include 路径——类似 QoolCommon 模式）
add_library(QoolUITestSupport INTERFACE)
target_include_directories(
  QoolUITestSupport INTERFACE ${CMAKE_CURRENT_SOURCE_DIR}
)

# Qt 安装前缀（Qt6_DIR = <prefix>/lib/cmake/Qt6，上三级回到前缀）。
# 供各层 qt.conf 模板（qt.conf.in）与依赖复制使用。
find_package(
  Qt6 REQUIRED COMPONENTS Test QuickTest Qml Quick QuickShapes
)
get_filename_component(QOOLUI_QT6_PREFIX "${Qt6_DIR}/../../.." ABSOLUTE)

# 测试 target 注册表（供聚合 run-tests target 收集）
set(QOOLUI_TEST_TARGETS "" CACHE INTERNAL "QoolUI test executables")

# 统一注册 C++ 测试 target：add_executable + Qt6::Test + CTest + DLL 部署
# 测试加入默认构建（all）——落地修正（原 spec 6.3 的 EXCLUDE_FROM_ALL）：
# QtCreator 测试面板运行前构建 all，EXCLUDE_FROM_ALL 的测试不构建 → exe
# 缺失 → 「启动测试失败/无预期输出」全红（实测：tst_math 单测进 all 后绿、
# 其余全红，确认根因）。run-tests 仍为聚合运行通道（DEPENDS 常规依赖）。
# 测试特定参数（如窗口测试的 -platform offscreen）：经
# QOOLUI_TEST_ARGS_<target> 变量声明（ctest 与 run-tests 双通道注入——
# 与 qml/ 批次的约定同名同义；无头窗口测试必须声明，否则 ctest/run-tests
# 运行时闪现真实窗口）
function(qoolui_add_cpp_test name)
  add_executable(${name} ${ARGN})
  target_link_libraries(${name} PRIVATE Qt6::Test)
  if(DEFINED QOOLUI_TEST_ARGS_${name})
    add_test(NAME ${name} COMMAND ${name} ${QOOLUI_TEST_ARGS_${name}})
  else()
    add_test(NAME ${name} COMMAND ${name})
  endif()
  # 依赖 DLL 复制到 exe 目录（Windows 生效，其余平台展开为空）
  add_custom_command(
    TARGET ${name} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            $<TARGET_RUNTIME_DLLS:${name}> $<TARGET_FILE_DIR:${name}>
    COMMAND_EXPAND_LISTS
  )
  list(APPEND QOOLUI_TEST_TARGETS ${name})
  set(QOOLUI_TEST_TARGETS ${QOOLUI_TEST_TARGETS} CACHE INTERNAL "")
endfunction()

add_subdirectory(common)
add_subdirectory(core)
add_subdirectory(qml)

# ---- 聚合运行 target：cmake --build build --target run-tests ----
# 注册表驱动：COMMAND 从 QOOLUI_TEST_TARGETS 自动生成——新增测试（经
# qoolui_add_cpp_test 注册）自动纳入，无需手改本列表。
# 逐个运行全部测试 exe（顺序执行，任一失败即中止并返回非零——开发时
# 快速定位第一个失败；规模化/并行/筛选走 ctest 通道，见 QoolUITests/README.md）。
set(RUN_TESTS_COMMANDS "")
foreach(tst IN LISTS QOOLUI_TEST_TARGETS)
  list(APPEND RUN_TESTS_COMMANDS COMMAND $<TARGET_FILE:${tst}>)
  # 测试特定参数（如 QML 测试的 -platform offscreen）：
  # 经 QOOLUI_TEST_ARGS_<target> 变量声明（见 qml/CMakeLists.txt）
  if(DEFINED QOOLUI_TEST_ARGS_${tst})
    list(APPEND RUN_TESTS_COMMANDS ${QOOLUI_TEST_ARGS_${tst}})
  endif()
endforeach()

add_custom_target(
  run-tests
  ${RUN_TESTS_COMMANDS}
  DEPENDS ${QOOLUI_TEST_TARGETS}
  USES_TERMINAL
)
