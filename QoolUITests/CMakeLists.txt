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
# Windows 前缀解析策略（qt.conf 自包含方案）：
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
# - Linux/macOS：系统 Qt 安装在标准路径，无需任何注入——qt.conf 仅
#   if(WIN32) 生成（Linux 上生成 Prefix=/usr 的 qt.conf 反而破坏
#   QLibraryInfo 路径推导），QOOLUI_QT6_PREFIX 在标准安装下亦正确
# - 勿引入 ENVIRONMENT/ENVIRONMENT_MODIFICATION 设 PATH 的 Windows 魔法：
#   ENVIRONMENT 的值按 ';' 拆分，多路径注入会损坏（CTest 已知陷阱）。

# project() 独立声明（定案见 AGENTS.md「CMake 组织」）：
# PROJECT_SOURCE_DIR/BINARY_DIR 指向本树；子目录 project() 重置 PROJECT_*
# 变量——本树内部引用模块路径一律相对路径，不引用 QoolUI 的 PROJECT_*。
# VERSION 来自父作用域变量（非 PROJECT_*）。
# CTest 注册：enable_testing 由顶层 include(CTest)（QOOL_BUILD_TESTS 内）
# 提供——ctest --preset dev 从顶层递归发现本树测试（落地修正：内聚到本树
# 时全新 configure 后顶层无 CTestTestfile，ctest 找不到测试）。
project(QoolUITests VERSION ${QOOLUI_VERSION_FULL} LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

# 共享测试头（INTERFACE 库，仅头文件承载 include 路径——类似 QoolCommon 模式）
add_library(QoolUITestSupport INTERFACE)
target_include_directories(
  QoolUITestSupport INTERFACE ${CMAKE_CURRENT_SOURCE_DIR}
)

# Qt 安装前缀（Qt6_DIR = <prefix>/lib/cmake/Qt6，上三级回到前缀）。
# 供各层 qt.conf 模板（qt.conf.in）与依赖复制使用。
find_package(
  Qt6 REQUIRED COMPONENTS Test QuickTest Qml Quick QuickShapes QuickControls2
)
get_filename_component(QOOLUI_QT6_PREFIX "${Qt6_DIR}/../../.." ABSOLUTE)

# 测试 target 注册表（供聚合 run-tests target 收集）
set(QOOLUI_TEST_TARGETS "" CACHE INTERNAL "QoolUI test executables")

# 统一注册 C++ 测试 target：add_executable + Qt6::Test + CTest + DLL 部署
# 测试加入默认构建（all）：
# QtCreator 测试面板运行前构建 all，EXCLUDE_FROM_ALL 的测试不构建 → exe
# 缺失 → 「启动测试失败/无预期输出」全红。run-tests 仍为聚合运行通道
# （DEPENDS 常规依赖）。
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
  # 依赖 DLL 复制到 exe 目录（仅 Windows 需要；$<TARGET_RUNTIME_DLLS>
  # 在非 Windows 平台展开为空，必须整段跳过，否则 copy_if_different
  # 只剩目标目录一个参数而报错）
  if(WIN32)
    add_custom_command(
      TARGET ${name} POST_BUILD
      COMMAND ${CMAKE_COMMAND} -E copy_if_different
              $<TARGET_RUNTIME_DLLS:${name}> $<TARGET_FILE_DIR:${name}>
      COMMAND_EXPAND_LISTS
    )
  endif()
  list(APPEND QOOLUI_TEST_TARGETS ${name})
  set(QOOLUI_TEST_TARGETS ${QOOLUI_TEST_TARGETS} CACHE INTERNAL "")
endfunction()

# 统一注册 QML 测试单元：每单元独立 target（一 cpp 一 target 一宏值）。
# Qt Creator QuickTest 扫描器从 CMake project macros 读取 QUICK_TEST_SOURCE_DIR
# （quicktestparser.cpp quickTestSrcDir：parts.at(0)->projectMacros）——共享 cpp
# 多 target 编译生成多 projectPart、扫描器只取第一个是「exe↔QML 目录」关联歧义
# 根因；每单元独立 cpp 后宏值唯一，Tests 面板逐测试可发现/运行/调试。
# 参数：<target> <单元目录> <模块依赖...>
#   target     = tst_<组件>_qml（独立可执行名，同时是 ctest/run-tests 名）
#   单元目录   = 相对当前 CMakeLists 的单元子目录（含 tst_<组件>.qml +
#                tst_<组件>.cpp，cpp 文件名 = 目录名）
#   模块依赖   = 被测模块 target（Qool/QoolControls/QoolControlsComponents/
#                QoolColor...）：进 LINK_DEPENDS（模块 DLL 更新触发重链 +
#                POST_BUILD 复制重跑，副本同步）+ DLL 复制（RUNTIME_DLLS +
#                TARGET_FILE——Qoolplugin.dll 从 qml 输出目录加载，其依赖链
#                须在 exe 目录；copy_if_different 幂等）
function(qoolui_add_qml_test name unit_dir)
  # 单元目录解析：支持两种结构 ——
  # (a) 批次文件调用：unit_dir 为相对本文件子目录（cpp 在其下）
  # (b) 单元独立 CMakeLists 调用：本文件位于单元目录（cpp 就在当前目录）
  # 判据：当前目录下存在 <name去tst_前缀? 不——用 cpp 同名探测：
  #   单元目录名 = cpp 基名 = 目录名；当前目录含 <目录名>.cpp 即单元模式
  get_filename_component(_unit_name "${unit_dir}" NAME)
  if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${_unit_name}.cpp")
    set(_unit_dir "${CMAKE_CURRENT_SOURCE_DIR}")
  else()
    set(_unit_dir "${CMAKE_CURRENT_SOURCE_DIR}/${unit_dir}")
  endif()
  add_executable(${name} "${_unit_dir}/${_unit_name}.cpp")
  target_link_libraries(${name} PRIVATE Qt6::QuickTest Qt6::Qml)

  # QUICK_TEST_SOURCE_DIR：绝对路径指向本单元目录（扫描器从此宏定位 QML）
  target_compile_definitions(${name} PRIVATE
    QUICK_TEST_SOURCE_DIR="${_unit_dir}"
    QOOLUI_TEST_QML_IMPORT_PATH="${QT_QML_OUTPUT_DIRECTORY}")

  # LINK_DEPENDS：模块 DLL 更新 → 重链 → POST_BUILD 复制重跑 → exe 旁副本
  # 同步（QML 修改只更新 DLL 的 qrc 资源，无此依赖时 exe 不重链、副本过期
  # 静默加载旧组件）
  set(_link_depends "")
  foreach(_mod IN LISTS ARGN)
    list(APPEND _link_depends "$<TARGET_FILE:${_mod}>")
  endforeach()
  set_property(TARGET ${name} APPEND PROPERTY LINK_DEPENDS ${_link_depends})

  # offscreen 无头运行（目视渲染直接跑 exe 无参）——ctest 与 run-tests 双通道注入
  set(QOOLUI_TEST_ARGS_${name} "-platform;offscreen" CACHE INTERNAL "")

  add_test(NAME ${name} COMMAND ${name} ${QOOLUI_TEST_ARGS_${name}})

  # 注册进聚合 run-tests（注册表驱动）
  list(APPEND QOOLUI_TEST_TARGETS ${name})
  set(QOOLUI_TEST_TARGETS ${QOOLUI_TEST_TARGETS} CACHE INTERNAL "")

  # DLL 部署（Windows）：Qt DLL（本 target RUNTIME_DLLS）+ 模块 DLL 集
  if(WIN32)
    set(_copy_cmds
      COMMAND ${CMAKE_COMMAND} -E copy_if_different
              $<TARGET_RUNTIME_DLLS:${name}> $<TARGET_FILE_DIR:${name}>)
    foreach(_mod IN LISTS ARGN)
      list(APPEND _copy_cmds
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
                $<TARGET_RUNTIME_DLLS:${_mod}> $<TARGET_FILE_DIR:${name}>
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
                $<TARGET_FILE:${_mod}> $<TARGET_FILE_DIR:${name}>)
    endforeach()
    add_custom_command(TARGET ${name} POST_BUILD ${_copy_cmds} COMMAND_EXPAND_LISTS)
  else()
    # Linux/macOS：$<TARGET_RUNTIME_DLLS> 为空，只复制模块库本体
    set(_copy_cmds "")
    foreach(_mod IN LISTS ARGN)
      list(APPEND _copy_cmds
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
                $<TARGET_FILE:${_mod}> $<TARGET_FILE_DIR:${name}>)
    endforeach()
    add_custom_command(TARGET ${name} POST_BUILD ${_copy_cmds})
  endif()

  # QML 插件 DLL（QuickShapes/QuickLayouts）：引擎运行时 import 才加载的插件
  # 依赖，非任何 target 链接依赖——find_file 定位（全局缓存，仅首次搜索）+
  # 存在时复制（Release 无 debug 后缀文件则跳过）。QuickShapes 供 Shape 组件
  # （Crystal/HalfCrystal），QuickLayouts 供 import QtQuick.Layouts 的单元。
  if(NOT DEFINED QOOLUI_QT6_QUICKSHAPES_DBG)
    find_file(QOOLUI_QT6_QUICKSHAPES_DBG NAMES Qt6QuickShapesd.dll
      HINTS "${QOOLUI_QT6_PREFIX}/bin" NO_DEFAULT_PATH)
    set(QOOLUI_QT6_QUICKSHAPES_DBG ${QOOLUI_QT6_QUICKSHAPES_DBG} CACHE INTERNAL "")
  endif()
  if(NOT DEFINED QOOLUI_QT6_QUICKSHAPES_REL)
    find_file(QOOLUI_QT6_QUICKSHAPES_REL NAMES Qt6QuickShapes.dll
      HINTS "${QOOLUI_QT6_PREFIX}/bin" NO_DEFAULT_PATH)
    set(QOOLUI_QT6_QUICKSHAPES_REL ${QOOLUI_QT6_QUICKSHAPES_REL} CACHE INTERNAL "")
  endif()
  if(NOT DEFINED QOOLUI_QT6_QUICKLAYOUTS_DBG)
    find_file(QOOLUI_QT6_QUICKLAYOUTS_DBG NAMES Qt6QuickLayoutsd.dll
      HINTS "${QOOLUI_QT6_PREFIX}/bin" NO_DEFAULT_PATH)
    set(QOOLUI_QT6_QUICKLAYOUTS_DBG ${QOOLUI_QT6_QUICKLAYOUTS_DBG} CACHE INTERNAL "")
  endif()
  if(NOT DEFINED QOOLUI_QT6_QUICKLAYOUTS_REL)
    find_file(QOOLUI_QT6_QUICKLAYOUTS_REL NAMES Qt6QuickLayouts.dll
      HINTS "${QOOLUI_QT6_PREFIX}/bin" NO_DEFAULT_PATH)
    set(QOOLUI_QT6_QUICKLAYOUTS_REL ${QOOLUI_QT6_QUICKLAYOUTS_REL} CACHE INTERNAL "")
  endif()
  # QtQuick.Controls Basic 风格插件依赖（qtquickcontrols2basicstyleplugin 运行时
  # 加载——import QtQuick.Controls 即触发默认 Basic 风格；其依赖
  # Qt6QuickControls2Basic.dll 非任何 target 链接依赖，缺则插件加载失败）
  if(NOT DEFINED QOOLUI_QT6_QUICKCONTROLS2_BASIC_DBG)
    find_file(QOOLUI_QT6_QUICKCONTROLS2_BASIC_DBG NAMES Qt6QuickControls2Basicd.dll
      HINTS "${QOOLUI_QT6_PREFIX}/bin" NO_DEFAULT_PATH)
    set(QOOLUI_QT6_QUICKCONTROLS2_BASIC_DBG ${QOOLUI_QT6_QUICKCONTROLS2_BASIC_DBG} CACHE INTERNAL "")
  endif()
  if(NOT DEFINED QOOLUI_QT6_QUICKCONTROLS2_BASIC_REL)
    find_file(QOOLUI_QT6_QUICKCONTROLS2_BASIC_REL NAMES Qt6QuickControls2Basic.dll
      HINTS "${QOOLUI_QT6_PREFIX}/bin" NO_DEFAULT_PATH)
    set(QOOLUI_QT6_QUICKCONTROLS2_BASIC_REL ${QOOLUI_QT6_QUICKCONTROLS2_BASIC_REL} CACHE INTERNAL "")
  endif()
  foreach(_dll IN ITEMS QOOLUI_QT6_QUICKSHAPES_DBG QOOLUI_QT6_QUICKSHAPES_REL
                       QOOLUI_QT6_QUICKLAYOUTS_DBG QOOLUI_QT6_QUICKLAYOUTS_REL
                       QOOLUI_QT6_QUICKCONTROLS2_BASIC_DBG QOOLUI_QT6_QUICKCONTROLS2_BASIC_REL)
    if(EXISTS "${${_dll}}")
      add_custom_command(TARGET ${name} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
                "${${_dll}}" $<TARGET_FILE_DIR:${name}>)
    endif()
  endforeach()
endfunction()

add_subdirectory(common)
add_subdirectory(core)
add_subdirectory(tst_qool_qml)
add_subdirectory(tst_qoolcolor_qml)
add_subdirectory(tst_qoolcontrols_qml)

# ---- 聚合运行 target：cmake --build build --target run-tests ----
# 注册表驱动：COMMAND 从 QOOLUI_TEST_TARGETS 自动生成——新增测试（经
# qoolui_add_cpp_test 注册）自动纳入，无需手改本列表。
# 逐个运行全部测试 exe（顺序执行，任一失败即中止并返回非零——开发时
# 快速定位第一个失败；规模化/并行/筛选走 ctest 通道，见 QoolUITests/AGENTS.md）。
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
