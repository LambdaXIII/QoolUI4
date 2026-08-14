// QML 测试批次共享 harness 模板（Qt Quick Test）
//
// 每个 Qool 模块 = 一个 QML 测试批次 = 一个 harness target（命名
// tst_<模块>_qml），各自编译本模板。编译期注入（由各 QML 测试批次
// CMakeLists 提供）：
//   QUICK_TEST_SOURCE_DIR       — 批次目录（该 QML 测试批次全部 tst_*.qml
//                                 所在源码目录，递归扫描；assets/ 内文件
//                                 不得以 tst_ 开头）
//   QOOLUI_TEST_QML_IMPORT_PATH — Qool 模块构建输出目录
//                                 （build/build-<kit>-<Type>/qml），
//                                 qmlEngineAvailable 时注入引擎——tst_*.qml
//                                 即可 `import Qool` 并使用真实模块
// 注意：QUICK_TEST_MAIN_WITH_SETUP 的 name 参数（qoolqml）仅为 QTest 显示名，
// 各 QML 测试批次显示相同；target/CTest 名（tst_<模块>_qml）才是运行标识。
//
// 扩展方式（当 QML 测试批次需要 C++ 前置时）：
// - 注册测试用类型：qmlRegisterType(...) 放在 qmlEngineAvailable 中
// - 注入 context property：engine->rootContext()->setContextProperty(...)
// 各 tst_*.qml 独立引擎，qmlEngineAvailable 对每个文件各调用一次。

#include <QtQuickTest>

#include <QQmlEngine>

class QoolTestSetup : public QObject {
  Q_OBJECT

public:
  QoolTestSetup() {
    // 注：Windows Qt 前缀解析已由 qt.conf（exe 旁，configure 期生成）接管
    // ——qt.conf 是 Qt 官方自包含机制（QLibraryInfo 读取），覆盖插件与
    // QML 模块路径，无需环境变量注入（规范见 原 spec 5.2）。
  }

public slots:
  void qmlEngineAvailable(QQmlEngine* engine) {
    engine->addImportPath(QStringLiteral(QOOLUI_TEST_QML_IMPORT_PATH));
  }
};

QUICK_TEST_MAIN_WITH_SETUP(qoolqml, QoolTestSetup)

#include "qml_test_main.moc"
