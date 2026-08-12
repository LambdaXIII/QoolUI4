// QML 测试 harness（Qt Quick Test）
//
// - QUICK_TEST_SOURCE_DIR（编译期注入）：递归扫描的 tst_*.qml 源码目录
// - QOOLUI_TEST_QML_IMPORT_PATH（编译期注入）：Qool 模块构建输出目录
//   （build/qml），qmlEngineAvailable 时注入引擎——tst_*.qml 即可
//   `import Qool` 并使用真实模块（含 C++ 注册类型）
//
// 扩展方式（当测试需要 C++ 前置时）：
// - 注册测试用类型：qmlRegisterType(...) 放在 qmlEngineAvailable 中
// - 注入 context property：engine->rootContext()->setContextProperty(...)
// 各 tst_*.qml 独立引擎，qmlEngineAvailable 对每个文件各调用一次。

#include <QtQuickTest>

#include <QQmlEngine>

class QoolTestSetup : public QObject {
  Q_OBJECT

public:
  QoolTestSetup() = default;

public slots:
  void qmlEngineAvailable(QQmlEngine* engine) {
    engine->addImportPath(QStringLiteral(QOOLUI_TEST_QML_IMPORT_PATH));
  }
};

QUICK_TEST_MAIN_WITH_SETUP(qoolqml, QoolTestSetup)

#include "tst_qml_main.moc"
