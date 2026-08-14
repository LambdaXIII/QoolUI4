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

# Qool 模块的 PRIVATE include 目录清单（与 Qool/CMakeLists.txt 的
# target_include_directories PRIVATE 同步）——直接编译被测源时的必需面：
# 被测头内部可能引用这些目录下的头（实例：gadgets/*.h → "qool_shapecontrol_gadget.h"
# （shapecontrol/）、"qool_smartobj.h"（utils/）、"qool_literals.h"（qore/）），
# 而 Qool target 的 PRIVATE include 不传播给测试 target——漏一层断一层
# （C1083 逐个暴露）。新增 core 测试一律对本变量做 PRIVATE include。
set(QOOL_SRC_PRIVATE_INCLUDES
    "${QOOL_SRC}/shapecontrol"
    "${QOOL_SRC}/shapecontrol/gadgets"
    "${QOOL_SRC}/datatypes"
    "${QOOL_SRC}/style"
    "${QOOL_SRC}/utils"
    "${QOOL_SRC}/qore"
    "${QOOL_SRC}/models"
)

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
target_include_directories(tst_qool_vector2d PRIVATE ${QOOL_SRC_PRIVATE_INCLUDES})
target_link_libraries(tst_qool_vector2d PRIVATE Qool QoolCommon QoolUITestSupport Qt6::Quick)

qoolui_add_cpp_test(
  tst_qool_numberranger
  tst_numberranger.cpp
  "${QOOL_SRC}/utils/qool_numberranger.cpp"
  "${QOOL_SRC}/utils/qool_smartobj.cpp"
)
target_include_directories(tst_qool_numberranger PRIVATE ${QOOL_SRC_PRIVATE_INCLUDES})
target_link_libraries(tst_qool_numberranger PRIVATE Qool QoolCommon QoolUITestSupport Qt6::Quick)

qoolui_add_cpp_test(
  tst_qool_polar2d
  tst_polar2d.cpp
  "${QOOL_SRC}/datatypes/qool_polar2d.cpp"
)
target_include_directories(tst_qool_polar2d PRIVATE ${QOOL_SRC_PRIVATE_INCLUDES})
target_link_libraries(tst_qool_polar2d PRIVATE Qool QoolCommon QoolUITestSupport Qt6::Quick)

qoolui_add_cpp_test(
  tst_qool_multirowselectionmodel
  tst_multirowselectionmodel.cpp
  "${QOOL_SRC}/models/qool_multirowselectionmodel.cpp"
)
target_include_directories(tst_qool_multirowselectionmodel PRIVATE ${QOOL_SRC_PRIVATE_INCLUDES})
target_link_libraries(tst_qool_multirowselectionmodel PRIVATE Qool QoolCommon QoolUITestSupport Qt6::Quick)

# CrystalGadget（八点几何 + contains 精确命中）——链依赖：
# ShapeControl（target→control 几何链）+ ShapeControlGadget 基类 + SmartObject
qoolui_add_cpp_test(
  tst_qool_crystalgadget
  tst_crystalgadget.cpp
  "${QOOL_SRC}/shapecontrol/qool_shapecontrol.cpp"
  "${QOOL_SRC}/shapecontrol/qool_shapecontrol_gadget.cpp"
  "${QOOL_SRC}/shapecontrol/gadgets/qool_shapegadget_crystal.cpp"
  "${QOOL_SRC}/utils/qool_smartobj.cpp"
)
target_include_directories(tst_qool_crystalgadget PRIVATE ${QOOL_SRC_PRIVATE_INCLUDES})
target_link_libraries(tst_qool_crystalgadget PRIVATE Qool QoolCommon QoolUITestSupport Qt6::Quick)

# QoolBoxGadget（八点 + shrink 半平面交集 + contains + referenceBox）——
# 链依赖：ShapeControl + ShapeControlGadget 基类 + SmartObject
qoolui_add_cpp_test(
  tst_qool_qoolboxgadget
  tst_qoolboxgadget.cpp
  "${QOOL_SRC}/shapecontrol/qool_shapecontrol.cpp"
  "${QOOL_SRC}/shapecontrol/qool_shapecontrol_gadget.cpp"
  "${QOOL_SRC}/shapecontrol/gadgets/qool_shapegadget_qoolbox.cpp"
  "${QOOL_SRC}/utils/qool_smartobj.cpp"
)
target_include_directories(tst_qool_qoolboxgadget PRIVATE ${QOOL_SRC_PRIVATE_INCLUDES})
target_link_libraries(tst_qool_qoolboxgadget PRIVATE Qool QoolCommon QoolUITestSupport Qt6::Quick)

# HalfCrystalGadget contains 契约（geometrySource = RectGadget 画布）
qoolui_add_cpp_test(
  tst_qool_halfcrystalgadget
  tst_halfcrystalgadget.cpp
  "${QOOL_SRC}/shapecontrol/qool_shapecontrol.cpp"
  "${QOOL_SRC}/shapecontrol/qool_shapecontrol_gadget.cpp"
  "${QOOL_SRC}/shapecontrol/gadgets/qool_shapegadget_rect.cpp"
  "${QOOL_SRC}/shapecontrol/gadgets/qool_shapegadget_halfcrystal.cpp"
  "${QOOL_SRC}/utils/qool_smartobj.cpp"
)
target_include_directories(tst_qool_halfcrystalgadget PRIVATE ${QOOL_SRC_PRIVATE_INCLUDES})
target_link_libraries(tst_qool_halfcrystalgadget PRIVATE Qool QoolCommon QoolUITestSupport Qt6::Quick)

# RectGadget 派生几何契约（HalfCrystal 画布依赖 + 通用消费面）
qoolui_add_cpp_test(
  tst_qool_rectgadget
  tst_rectgadget.cpp
  "${QOOL_SRC}/shapecontrol/qool_shapecontrol.cpp"
  "${QOOL_SRC}/shapecontrol/qool_shapecontrol_gadget.cpp"
  "${QOOL_SRC}/shapecontrol/gadgets/qool_shapegadget_rect.cpp"
  "${QOOL_SRC}/utils/qool_smartobj.cpp"
)
target_include_directories(tst_qool_rectgadget PRIVATE ${QOOL_SRC_PRIVATE_INCLUDES})
target_link_libraries(tst_qool_rectgadget PRIVATE Qool QoolCommon QoolUITestSupport Qt6::Quick)

# OffsetProjector（位移映射节点：投影/退化/短路/符号规则——直接编译被测源）
qoolui_add_cpp_test(
  tst_qool_offsetprojector
  tst_qool_offsetprojector.cpp
  "${QOOL_SRC}/shapecontrol/qool_offsetprojector.cpp"
)
target_include_directories(tst_qool_offsetprojector PRIVATE ${QOOL_SRC_PRIVATE_INCLUDES})
target_link_libraries(tst_qool_offsetprojector PRIVATE Qool QoolCommon QoolUITestSupport Qt6::Quick)

# QoolBoxShapeControl（重写 gadget 化）——settings 信号同步/替换重挂、
# 16 点转发对照、*Space 公式、contains、referenceBox 链、null 退化、
# 析构安全。链依赖：control + settings 双类型 + ShapeControl + gadget 基类
# + SmartObject（同 tst_qool_qoolboxgadget 模式）
qoolui_add_cpp_test(
  tst_qool_qoolboxshapecontrol
  tst_qoolboxshapecontrol.cpp
  "${QOOL_SRC}/shapecontrol/qool_qoolbox_shapecontrol.cpp"
  "${QOOL_SRC}/shapecontrol/qool_qoolbox_settings_base.cpp"
  "${QOOL_SRC}/shapecontrol/qool_qoolbox_settings.cpp"
  "${QOOL_SRC}/shapecontrol/qool_shapecontrol.cpp"
  "${QOOL_SRC}/shapecontrol/qool_shapecontrol_gadget.cpp"
  "${QOOL_SRC}/shapecontrol/gadgets/qool_shapegadget_qoolbox.cpp"
  "${QOOL_SRC}/utils/qool_smartobj.cpp"
)
target_include_directories(tst_qool_qoolboxshapecontrol PRIVATE ${QOOL_SRC_PRIVATE_INCLUDES})
target_link_libraries(tst_qool_qoolboxshapecontrol PRIVATE Qool QoolCommon QoolUITestSupport Qt6::Quick)

# 端到端命中：QoolBox 直角/圆角变体 containmentMask 判定域与渲染一致
#（真实鼠标路径，tst_hover_e2e 同款——offscreen 由 QOOLUI_TEST_ARGS 注入）
set(QOOLUI_TEST_ARGS_tst_qool_box_hit "-platform;offscreen" CACHE INTERNAL "")
qoolui_add_cpp_test(
  tst_qool_box_hit
  tst_qoolbox_hit.cpp
)
target_link_libraries(tst_qool_box_hit PRIVATE
  Qool QoolCommon QoolUITestSupport Qt6::Quick Qt6::QuickShapes Qt6::Qml)
target_compile_definitions(tst_qool_box_hit PRIVATE
  QOOLUI_TEST_QML_IMPORT_PATH="${QT_QML_OUTPUT_DIRECTORY}")

# 端到端 hover：真实窗口 + QTest::mouseMove 下 HalfCrystal 掩码判定域与
# 渲染一致（QML 测试批次的 TestCase.mouseMove 在 offscreen 不注入事件，
# 引擎真实鼠标路径在本层验证——见 tst_hover_e2e.cpp 头注释）。
# 窗口测试：ctest/run-tests 双通道注入 -platform offscreen（无头；目视
# 渲染直接跑 exe 无参）——避免聚合运行时闪现真实窗口
set(QOOLUI_TEST_ARGS_tst_qool_hover_e2e "-platform;offscreen" CACHE INTERNAL "")
qoolui_add_cpp_test(
  tst_qool_hover_e2e
  tst_hover_e2e.cpp
)
target_link_libraries(tst_qool_hover_e2e PRIVATE
  Qool QoolCommon QoolUITestSupport Qt6::Quick Qt6::QuickShapes Qt6::Qml)
target_compile_definitions(tst_qool_hover_e2e PRIVATE
  QOOLUI_TEST_QML_IMPORT_PATH="${QT_QML_OUTPUT_DIRECTORY}")

# ---- 单例契约修复测试（DB/HQ/HQModel 拆分）----# 分层：QML 面测试（contract/write）走模块插件（类型注册在模块 DLL 内），
# 链接模块 target 仅为头文件 + DLL 部署；C++ 面测试（model/db）直接编译
# 被测源（仓库「绝不动态导出」，测试 target 内副本与模块内副本行为等价）。
set(QOOL_COLOR_SRC "${CMAKE_CURRENT_LIST_DIR}/../../QoolUI/QoolColor")
set(QOOL_FILE_SRC "${CMAKE_CURRENT_LIST_DIR}/../../QoolUI/QoolFile")

# 跨 engine 契约（QML 面，4 HQ 参数化）
# 注：QoolFile 是 MODULE_LIBRARY（插件形态），不可被 target_link_libraries
# 链接——QML 引擎经 import path（build/qml）直接加载其插件 DLL，
# 依赖链（Qool.dll/Qt DLL）由 Qool/QoolColor 链接复制到 exe 目录满足。
qoolui_add_cpp_test(
  tst_qool_singleton_contract
  tst_singleton_contract.cpp
)
target_link_libraries(tst_qool_singleton_contract PRIVATE
  Qool QoolColor QoolControls QoolControlsComponents
  QoolCommon QoolUITestSupport Qt6::Quick Qt6::Qml)
target_compile_definitions(tst_qool_singleton_contract PRIVATE
  QOOLUI_TEST_QML_IMPORT_PATH="${QT_QML_OUTPUT_DIRECTORY}")

# QML 写面 + 信号转发（QML 面）
qoolui_add_cpp_test(
  tst_qool_singleton_write
  tst_singleton_write.cpp
  "${QOOL_SRC}/style/qool_theme.cpp"
)
target_include_directories(tst_qool_singleton_write PRIVATE ${QOOL_SRC_PRIVATE_INCLUDES})
target_link_libraries(tst_qool_singleton_write PRIVATE
  Qool QoolColor QoolControls QoolControlsComponents
  QoolCommon QoolUITestSupport Qt6::Quick Qt6::Qml)
target_compile_definitions(tst_qool_singleton_write PRIVATE
  QOOLUI_TEST_QML_IMPORT_PATH="${QT_QML_OUTPUT_DIRECTORY}")

# ThemeHQModel（代理模型：源 = ThemeDB::instance()）
qoolui_add_cpp_test(
  tst_qool_singleton_model
  tst_singleton_model.cpp
  "${QOOL_SRC}/style/qool_theme_db.cpp"
  "${QOOL_SRC}/style/qool_theme.cpp"
  "${QOOL_SRC}/style/qool_system_theme.cpp"
  "${QOOL_SRC}/style/qool_theme_hqmodel.cpp"
)
target_include_directories(tst_qool_singleton_model PRIVATE ${QOOL_SRC_PRIVATE_INCLUDES})
target_link_libraries(tst_qool_singleton_model PRIVATE
  Qool QoolCommon QoolUITestSupport Qt6::Quick Qt6::Qml)

# DB 接口保留 + HQ 转发等价（4 个 DB 全部）
qoolui_add_cpp_test(
  tst_qool_singleton_db
  tst_singleton_db.cpp
  "${QOOL_SRC}/style/qool_theme_db.cpp"
  "${QOOL_SRC}/style/qool_theme.cpp"
  "${QOOL_SRC}/style/qool_system_theme.cpp"
  "${QOOL_SRC}/style/qool_theme_hq.cpp"
  "${QOOL_COLOR_SRC}/qool_colorname_db.cpp"
  "${QOOL_FILE_SRC}/qool_fileicon_db.cpp"
  "${QOOL_FILE_SRC}/qool_fileicon_imageprovider.cpp"
  "${QOOL_FILE_SRC}/qool_fileinfo_db.cpp"
)
target_include_directories(tst_qool_singleton_db PRIVATE
  ${QOOL_SRC_PRIVATE_INCLUDES}
  "${QOOL_COLOR_SRC}"
  "${QOOL_FILE_SRC}")
target_link_libraries(tst_qool_singleton_db PRIVATE
  Qool QoolColor QoolCommon QoolUITestSupport Qt6::Quick Qt6::Qml)
