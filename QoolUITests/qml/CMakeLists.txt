# QML 测试批次层（Qt Quick Test）
#
# 组织模型：每个 Qool 模块 = 一个
# QML 测试批次 = 一个 harness target（命名 tst_<模块>_qml），共享
# qml_test_main.cpp 模板，各自注入 QUICK_TEST_SOURCE_DIR 与共享的
# QOOLUI_TEST_QML_IMPORT_PATH。
#
# 批次目录：tst_<模块>_qml/ 子目录，含该批次全部 tst_*.qml；测试资源放
# 该目录下 assets/ 子目录（以文件系统相对路径访问，如 "assets/foo.png"）；
# assets/ 内文件不得以 tst_ 开头——harness 递归扫描会把 tst_ 前缀文件误当测试。
#
# 新增 QML 测试批次：复制 tst_qool_qml 段（add_executable + 编译定义 +
# add_test + 注册表登记），QUICK_TEST_SOURCE_DIR 指向新批次目录即可。
#
# 运行：add_test 统一带 -platform offscreen（无头；目视渲染直接跑 exe 无参）
#
# 输出树下沉（定案见 AGENTS.md「CMake 组织」）：本层 exe 输出到
# build/build-<kit>-<Type>/QoolUITests/qml/。本层与 core 层是唯二需要 qt.conf 的层（QML 测试
# 加载平台插件与 Qool QML 模块；core 层链接 Qt6::Quick → QTEST_MAIN 展开为
# QGuiApplication 构造加载平台插件；common 层纯 QCoreApplication 无需）。
# qt.conf 生成目标 = 本层输出目录。目录级变量只影响本目录树，不碰主设置。

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/QoolUITests/qml")

# qt.conf（Qt 官方自包含机制）：仅 Windows 需要——DLL 复制使 Qt 前缀
# 推导失效，需 qt.conf 覆盖。Linux/macOS 系统 Qt 按标准路径定位插件与
# QML 模块，生成 Prefix=/usr 的 qt.conf 反而破坏 QLibraryInfo 路径推导，
# 故跳过。改模板后需重新 configure 生效。
if(WIN32)
  file(MAKE_DIRECTORY "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}")
  configure_file(
    "${CMAKE_CURRENT_LIST_DIR}/../qt.conf.in"
    "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/qt.conf"
    @ONLY
  )
endif()

# ---- Qool 模块的 QML 测试批次 ----
# 加入默认构建（all）：
# QtCreator 测试面板运行前构建 all，被排除的测试 exe 缺失 → 全红
add_executable(tst_qool_qml qml_test_main.cpp)

target_link_libraries(
  tst_qool_qml PRIVATE Qt6::QuickTest Qt6::Qml
)

# Qool.dll 更新必须触发 exe 重链：Qool 是 DLL 且绝不动态导出，exe 不链接
# Qool.lib（且 MSVC 导出未变时导入库不更新，链接 Qool.lib 也无法感知内容
# 变化）——QML 修改只更新 Qool.dll 的 qrc 资源。无此依赖时 exe 不重链，
# POST_BUILD 复制不执行，exe 旁 Qool.dll 副本过期 → QML 测试静默加载旧组件。
# LINK_DEPENDS 把 Qool.dll 本体声明为链接规则实依赖（implicit input）：
# DLL 更新 → exe 重链 → POST_BUILD 复制重跑 → 副本同步。
set_property(TARGET tst_qool_qml APPEND PROPERTY
  LINK_DEPENDS "$<TARGET_FILE:Qool>")

target_compile_definitions(
  tst_qool_qml
  PRIVATE QUICK_TEST_SOURCE_DIR="${CMAKE_CURRENT_SOURCE_DIR}/tst_qool_qml"
  PRIVATE QOOLUI_TEST_QML_IMPORT_PATH="${QT_QML_OUTPUT_DIRECTORY}"
)

add_test(NAME tst_qool_qml COMMAND tst_qool_qml -platform offscreen)

# 注册进聚合 run-tests（注册表驱动，见 QoolUITests/CMakeLists.txt）：
# QML 测试需要 -platform offscreen 无头运行（目视渲染直接跑 exe 无参）
list(APPEND QOOLUI_TEST_TARGETS tst_qool_qml)
set(QOOLUI_TEST_TARGETS ${QOOLUI_TEST_TARGETS} CACHE INTERNAL "")
set(QOOLUI_TEST_ARGS_tst_qool_qml "-platform;offscreen" CACHE INTERNAL "")

# 依赖 DLL 复制到 exe 目录（与 qoolui_add_cpp_test 相同的部署策略）。
# 注意：Qool.dll（Qool 模块共享库）不在 $<TARGET_RUNTIME_DLLS:tst_qool_qml>
# 内（非本 target 链接依赖）——QML 引擎从 build/build-<kit>-<Type>/qml/Qool/ 加载
# Qoolplugin.dll，其依赖链（Qool.dll + QuickControls2/Templates2/Xml 等）
# 必须出现在 exe 的 DLL 搜索路径（exe 目录优先）。用 Qool target 自己的
# RUNTIME_DLLS + TARGET_FILE 一并复制：qml 层 DLL 集 = Qt DLL（双源并集，
# copy_if_different 幂等）+ Qool.dll。
# Qt6QuickShapes：非任何 target 的链接依赖（QtQuick.Shapes 为 QML 插件，
# QML import 时才加载 qmlshapesplugin → 其依赖 Qt6QuickShapesd.dll）——
# 测试用到 Shape 组件（Crystal/HalfCrystal）时插件加载失败即缺此 DLL。
# Qt6::QuickShapes 是 INTERFACE target（无 RUNTIME_DLLS），find_file 按
# 构建类型定位 DLL，存在时追加复制（Release 无 debug 后缀文件则跳过）。
find_file(QT6_QUICKSHAPES_DLL_DEBUG
  NAMES Qt6QuickShapesd.dll
  HINTS "${QOOLUI_QT6_PREFIX}/bin"
  NO_DEFAULT_PATH
)
find_file(QT6_QUICKSHAPES_DLL_RELEASE
  NAMES Qt6QuickShapes.dll
  HINTS "${QOOLUI_QT6_PREFIX}/bin"
  NO_DEFAULT_PATH
)
if(WIN32)
  add_custom_command(
    TARGET tst_qool_qml POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            $<TARGET_RUNTIME_DLLS:tst_qool_qml> $<TARGET_FILE_DIR:tst_qool_qml>
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            $<TARGET_RUNTIME_DLLS:Qool> $<TARGET_FILE_DIR:tst_qool_qml>
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            $<TARGET_FILE:Qool> $<TARGET_FILE_DIR:tst_qool_qml>
    COMMAND_EXPAND_LISTS
  )
else()
  # Linux/macOS：$<TARGET_RUNTIME_DLLS> 为空，只复制模块库本体
  add_custom_command(
    TARGET tst_qool_qml POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            $<TARGET_FILE:Qool> $<TARGET_FILE_DIR:tst_qool_qml>
  )
endif()
if(EXISTS "${QT6_QUICKSHAPES_DLL_DEBUG}")
  add_custom_command(
    TARGET tst_qool_qml POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${QT6_QUICKSHAPES_DLL_DEBUG}" $<TARGET_FILE_DIR:tst_qool_qml>
  )
elseif(EXISTS "${QT6_QUICKSHAPES_DLL_RELEASE}")
  add_custom_command(
    TARGET tst_qool_qml POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${QT6_QUICKSHAPES_DLL_RELEASE}" $<TARGET_FILE_DIR:tst_qool_qml>
  )
endif()

# ---- Qool.Controls 模块的 QML 测试批次 ----
# 覆盖 Qool.Controls（含 Qool.Controls.Components）消费方迁移回归：QoolBGBox
# 与 BasicLabel 的 *Space 语义（spec「Testing Decisions」消费方迁移回归段）。
# 除 Qool 外，本批次 QML 还实例化 Qool.Controls 与 Qool.Controls.Components
# 模块类型——QML 引擎从 build/build-<kit>-<Type>/qml/Qool/Controls*/ 加载其插件
# （QoolControlsplugin.dll / QoolControlsComponentsplugin.dll），插件依赖的
# 模块 DLL（QoolControls.dll / QoolControlsComponents.dll）不在
# $<TARGET_RUNTIME_DLLS:tst_qoolcontrols_qml> 内（非本 target 链接依赖），
# 须随 Qool 同款策略复制到 exe 目录。QoolControls/QoolControlsComponents
# 是普通模块库（qt_add_qml_module 目标），$<TARGET_RUNTIME_DLLS> +
# $<TARGET_FILE> 直接可用；Qt6QuickShapes 复用上方 find_file 结果（同文件
# 作用域）。LINK_DEPENDS 声明三个模块 DLL——QML 修改只更新 DLL 的 qrc
# 资源，无此依赖时 exe 不重链、POST_BUILD 不执行，副本过期静默加载旧组件。
add_executable(tst_qoolcontrols_qml qml_test_main.cpp)

target_link_libraries(
  tst_qoolcontrols_qml PRIVATE Qt6::QuickTest Qt6::Qml
)

set_property(TARGET tst_qoolcontrols_qml APPEND PROPERTY
  LINK_DEPENDS
    "$<TARGET_FILE:Qool>"
    "$<TARGET_FILE:QoolControls>"
    "$<TARGET_FILE:QoolControlsComponents>")

target_compile_definitions(
  tst_qoolcontrols_qml
  PRIVATE QUICK_TEST_SOURCE_DIR="${CMAKE_CURRENT_SOURCE_DIR}/tst_qoolcontrols_qml"
  PRIVATE QOOLUI_TEST_QML_IMPORT_PATH="${QT_QML_OUTPUT_DIRECTORY}"
)

add_test(NAME tst_qoolcontrols_qml COMMAND tst_qoolcontrols_qml -platform offscreen)

list(APPEND QOOLUI_TEST_TARGETS tst_qoolcontrols_qml)
set(QOOLUI_TEST_TARGETS ${QOOLUI_TEST_TARGETS} CACHE INTERNAL "")
set(QOOLUI_TEST_ARGS_tst_qoolcontrols_qml "-platform;offscreen" CACHE INTERNAL "")

# 依赖 DLL 复制到 exe 目录（与 tst_qool_qml 同款部署策略，双源并集 +
# copy_if_different 幂等）：Qt DLL（本 target + 三模块各自的 RUNTIME_DLLS）
# + 三个模块 DLL（Qool/QoolControls/QoolControlsComponents）本体。
if(WIN32)
  add_custom_command(
    TARGET tst_qoolcontrols_qml POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            $<TARGET_RUNTIME_DLLS:tst_qoolcontrols_qml> $<TARGET_FILE_DIR:tst_qoolcontrols_qml>
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            $<TARGET_RUNTIME_DLLS:Qool> $<TARGET_FILE_DIR:tst_qoolcontrols_qml>
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            $<TARGET_FILE:Qool> $<TARGET_FILE_DIR:tst_qoolcontrols_qml>
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            $<TARGET_RUNTIME_DLLS:QoolControls> $<TARGET_FILE_DIR:tst_qoolcontrols_qml>
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            $<TARGET_FILE:QoolControls> $<TARGET_FILE_DIR:tst_qoolcontrols_qml>
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            $<TARGET_RUNTIME_DLLS:QoolControlsComponents> $<TARGET_FILE_DIR:tst_qoolcontrols_qml>
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            $<TARGET_FILE:QoolControlsComponents> $<TARGET_FILE_DIR:tst_qoolcontrols_qml>
    COMMAND_EXPAND_LISTS
  )
else()
  # Linux/macOS：$<TARGET_RUNTIME_DLLS> 为空，只复制模块库本体
  add_custom_command(
    TARGET tst_qoolcontrols_qml POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            $<TARGET_FILE:Qool> $<TARGET_FILE_DIR:tst_qoolcontrols_qml>
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            $<TARGET_FILE:QoolControls> $<TARGET_FILE_DIR:tst_qoolcontrols_qml>
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            $<TARGET_FILE:QoolControlsComponents> $<TARGET_FILE_DIR:tst_qoolcontrols_qml>
  )
endif()
if(EXISTS "${QT6_QUICKSHAPES_DLL_DEBUG}")
  add_custom_command(
    TARGET tst_qoolcontrols_qml POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${QT6_QUICKSHAPES_DLL_DEBUG}" $<TARGET_FILE_DIR:tst_qoolcontrols_qml>
  )
elseif(EXISTS "${QT6_QUICKSHAPES_DLL_RELEASE}")
  add_custom_command(
    TARGET tst_qoolcontrols_qml POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${QT6_QUICKSHAPES_DLL_RELEASE}" $<TARGET_FILE_DIR:tst_qoolcontrols_qml>
  )
endif()

