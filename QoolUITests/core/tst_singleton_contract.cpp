// Qool 单例契约修复测试：跨 QQmlEngine 契约（QML 面走模块插件）
//
// 被测面：4 个 HQ（ThemeHQ/ColorNameHQ/FileIconHQ/FileInfoHQ）在多
// engine 场景的行为——engine1 加载含 HQ 绑定的内联 QML → 析构 →
// engine2 加载同组件，断言不崩 + 返回值一致（原崩溃序列的确定性复现：
// 进程级 C++ 单例经 QML_SINGLETON 暴露在第二 engine 即 SEGFAULT）。
//
// 注意：本测试走 Qool/QoolColor/QoolFile 模块插件（QML 类型注册在
// Qool.dll 等内），import path 由 QOOLUI_TEST_QML_IMPORT_PATH 注入
// （构建树 build/build-<kit>-<Type>/qml）。QML 类型随插件注册，跨 engine 由 Qt 原生
// 机制重新实例化——本测试验证的正是该契约。

#include <QtTest>

#include "qool_test.hpp"

#include <QQmlComponent>
#include <QQmlEngine>
#include <QUrl>
#include <QVariant>

class TestSingletonContract : public QObject {
  Q_OBJECT

private:
  QVariant runOnce(const QString& qmlSource) {
    QQmlEngine engine;
    engine.addImportPath(QStringLiteral(QOOLUI_TEST_QML_IMPORT_PATH));
    QQmlComponent component(&engine);
    component.setData(
      qmlSource.toUtf8(), QUrl::fromLocalFile("tst_singleton_contract.qml"));
    if (! component.isReady()) {
      qWarning() << "component not ready:" << component.errorString();
      return {};
    }
    QScopedPointer<QObject> obj(component.create());
    if (! obj)
      return {};
    return obj->property("v");
  }

  void checkExpected(const QVariant& value, const QVariant& expected) {
    if (QTest::currentDataTag() == QStringLiteral("FileInfoHQ.getFileInfo"))
      QCOMPARE(value.toMap().value("fileName").toString(),
        expected.toString());
    else
      QCOMPARE(value, expected);
  }

  QOOL_TEST_CASE(contract) {
    QFETCH(QString, qmlSource);
    QFETCH(QVariant, expected);

    // engine1：加载 → 断言值 → 析构（局部对象离开作用域）
    const QVariant v1 = runOnce(qmlSource);
    QVERIFY(v1.isValid());
    checkExpected(v1, expected);

    // engine2：同一组件重新加载——原崩溃序列的第二步
    const QVariant v2 = runOnce(qmlSource);
    QVERIFY(v2.isValid());
    checkExpected(v2, expected);
  }

  QOOL_TEST_CASE(contract_data) {
    QTest::addColumn<QString>("qmlSource");
    QTest::addColumn<QVariant>("expected");

    QTest::newRow("ThemeHQ.recommendForeground")
      << QStringLiteral("import QtQuick\nimport Qool\n"
                        "Item { property color v: "
                        "ThemeHQ.recommendForeground(\"#ff0000\") }")
      << QVariant(QColor("#ffffff"));

    QTest::newRow("ColorNameHQ.color")
      << QStringLiteral("import QtQuick\nimport Qool.Color\n"
                        "Item { property color v: "
                        "ColorNameHQ.color(\"qoolui_no_such_color\", "
                        "\"#123456\") }")
      << QVariant(QColor("#123456"));

    // FileIconHQ.iconUrl 的 C++ 侧契约 = compileUrl(fileUrl.toString(
    // QUrl::PreferLocalFile))；Linux 上 fromLocalFile("C:/x/y.png") 会带
    // 前导斜杠，故期望值不能用 Windows 硬编码，按同一公式现算。
    const QUrl iconFileUrl(QStringLiteral("file:///C:/x/y.png"));
    const QUrl iconExpected(
      QStringLiteral("image://qoolfileicon/")
      + QString::fromLatin1(QUrl::toPercentEncoding(
          iconFileUrl.toString(QUrl::PreferLocalFile))));
    QTest::newRow("FileIconHQ.iconUrl")
      << QStringLiteral("import QtQuick\nimport Qool.File\n"
                        "Item { property url v: "
                        "FileIconHQ.iconUrl(\"file:///C:/x/y.png\") }")
      << QVariant(iconExpected);

    // 以测试 exe 旁的 qt.conf 为样本文件（Windows 配置期生成；Linux 上
    // 该文件不一定存在，但本行只断言 fileName 从 URL 路径解析，故无碍）
    const QString sample =
      QCoreApplication::applicationDirPath() + QStringLiteral("/qt.conf");
    QTest::newRow("FileInfoHQ.getFileInfo")
      << QStringLiteral("import QtQuick\nimport Qool.File\n"
                        "Item { property var v: "
                        "FileInfoHQ.getFileInfo(\"file:///")
            + sample + QStringLiteral("\") }")
      << QVariant(QString("qt.conf"));
  }
};

QTEST_MAIN(TestSingletonContract)

#include "tst_singleton_contract.moc"
