// QML 测试单元：tst_channelcrystalslider（Qool.Color 模块）
// 独立 target（tst_channelcrystalslider_qml）——Qt Creator 扫描器从 CMake project macros 读
// QUICK_TEST_SOURCE_DIR（本单元目录）定位 QML 文件（一 cpp 一 target 一宏值）。
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

QUICK_TEST_MAIN_WITH_SETUP(tst_channelcrystalslider, QoolTestSetup)

#include "tst_channelcrystalslider.moc"
