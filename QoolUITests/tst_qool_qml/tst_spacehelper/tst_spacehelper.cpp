// QML 测试单元：tst_spacehelper（Qool 模块）
// 独立 target（tst_spacehelper_qml）。
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

QUICK_TEST_MAIN_WITH_SETUP(tst_spacehelper, QoolTestSetup)

#include "tst_spacehelper.moc"
