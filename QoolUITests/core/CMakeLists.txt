# Qool 核心 C++ 类型测试（Qt Test）
# 被测面：Qool 模块的 C++ 类型（值类型 / QObject 属性宏体系产物）
#
# 输出树下沉（原 spec 6.1）：本层 exe 输出到 build/QoolUITests/core/。
# 目录级变量只影响本目录树，不碰主设置。
#
# 链接策略说明（重要）：
# - Qool 为 qt_add_qml_module 共享库（Qool.dll），遵循仓库「绝不动态导出」
#   原则，普通 C++ 类符号不导出——测试无法链接 Qool target 获取实现。
# - 因此被测 .cpp 直接编入测试 target（AUTOMOC 自动处理其 Q_OBJECT）；
#   测试依赖 Qool/QoolCommon/Qt6::Quick 仅取头文件路径。
# - QTEST_MAIN 在未定义 QT_GUI_LIB 时使用 QCoreApplication，本层测试
#   不实例化 QQuickItem，无窗口依赖。

set(QOOL_SRC "${CMAKE_CURRENT_LIST_DIR}/../../QoolUI/Qool")

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/QoolUITests/core")

# qt.conf（原 spec 5.2）：本层测试链接 Qt6::Quick（QT_GUI_LIB）→ QTEST_MAIN
# 展开为 QGuiApplication，构造时加载平台插件——DLL 复制使前缀推导失效，
# 需 qt.conf 覆盖（见总入口策略说明）。common/ 纯 QCoreApplication 无需。
file(MAKE_DIRECTORY "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}")
configure_file(
  "${CMAKE_CURRENT_LIST_DIR}/../qt.conf.in"
  "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/qt.conf"
  @ONLY
)

qoolui_add_cpp_test(
  tst_qool_vector2d
  tst_vector2d.cpp
  "${QOOL_SRC}/datatypes/qool_vector2d.cpp"
)
target_link_libraries(tst_qool_vector2d PRIVATE Qool QoolCommon QoolUITestSupport Qt6::Quick)

qoolui_add_cpp_test(
  tst_qool_numberranger
  tst_numberranger.cpp
  "${QOOL_SRC}/utils/qool_numberranger.cpp"
  "${QOOL_SRC}/utils/qool_smartobj.cpp"
)
target_link_libraries(tst_qool_numberranger PRIVATE Qool QoolCommon QoolUITestSupport Qt6::Quick)
