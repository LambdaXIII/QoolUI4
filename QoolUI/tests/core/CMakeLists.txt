# Qool 核心 C++ 类型测试（Qt Test）
# 被测面：Qool 模块的 C++ 类型（值类型 / QObject 属性宏体系产物）
#
# 链接策略说明（重要）：
# - Qool 为 qt_add_qml_module 共享库（Qool.dll），遵循仓库「绝不动态导出」
#   原则，普通 C++ 类符号不导出——测试无法链接 Qool target 获取实现。
# - 因此被测 .cpp 直接编入测试 target（AUTOMOC 自动处理其 Q_OBJECT）；
#   测试依赖 Qool/QoolCommon/Qt6::Quick 仅取头文件路径。
# - QTEST_MAIN 在未定义 QT_GUI_LIB 时使用 QCoreApplication，本层测试
#   不实例化 QQuickItem，无窗口依赖。

set(QOOL_SRC "${CMAKE_CURRENT_LIST_DIR}/../../Qool")

qoolui_add_cpp_test(
  tst_qool_vector2d
  tst_vector2d.cpp
  "${QOOL_SRC}/datatypes/qool_vector2d.cpp"
)
target_link_libraries(tst_qool_vector2d PRIVATE Qool QoolCommon Qt6::Quick)

qoolui_add_cpp_test(
  tst_qool_numberranger
  tst_numberranger.cpp
  "${QOOL_SRC}/utils/qool_numberranger.cpp"
  "${QOOL_SRC}/utils/qool_smartobj.cpp"
)
target_link_libraries(tst_qool_numberranger PRIVATE Qool QoolCommon Qt6::Quick)
