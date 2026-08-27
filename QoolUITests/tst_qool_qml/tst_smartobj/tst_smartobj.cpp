// QML 测试单元：tst_smartobj（Qool 模块）
// 独立 target（tst_smartobj_qml）。
#include <QtQuickTest>

#include <QQmlEngine>

class QoolTestSetup : public QObject {
  Q_OBJECT

public:
  QoolTestSetup() {}

public slots:
  void qmlEngineAvailable(QQmlEngine* engine) {
    engine->addImportPath(QStringLiteral(QOOLUI_TEST_QML_IMPORT_PATH));
  }
};

QUICK_TEST_MAIN_WITH_SETUP(tst_smartobj, QoolTestSetup)

#include "tst_smartobj.moc"
