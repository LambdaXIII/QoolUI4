// QML 测试单元：tst_dialogbuttonbox（Qool.Dialogs 模块）
// 独立 target（tst_dialogbuttonbox_qml）——Qt Creator 扫描器从 CMake project macros 读
// QUICK_TEST_SOURCE_DIR（本单元目录）定位 QML 文件（一 cpp 一 target 一宏值）。
#include <QtQuickTest>

#include <QQmlEngine>

class QoolTestSetup: public QObject {
  Q_OBJECT

public:
  QoolTestSetup() {
    // Qool.Dialogs 的 DialogButtonBox 基座在 QtQuick.Controls 样式层：import
    // 该模块会加载所选风格插件。测试锚死 Basic（Qt 必装，DLL 已部署），
    // 平台默认的 Windows 风格插件在测试 exe 目录不可加载。
    qputenv("QT_QUICK_CONTROLS_STYLE", "Basic");
  }

public slots:
  void qmlEngineAvailable(QQmlEngine* engine) {
    engine->addImportPath(QStringLiteral(QOOLUI_TEST_QML_IMPORT_PATH));
  }
};

QUICK_TEST_MAIN_WITH_SETUP(tst_dialogbuttonbox, QoolTestSetup)

#include "tst_dialogbuttonbox.moc"
