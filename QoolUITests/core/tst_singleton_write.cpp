// Qool 单例契约修复测试：QML 写面 + 信号转发（QML 面走模块插件）
//
// 被测面：ThemeHQ 的 QML 写面（installTheme）与信号转发
// （themeInstalled 重发）——QML 侧 connect ThemeHQ.themeInstalled 后
// 调用 ThemeHQ.installTheme(theme)，断言信号收到且参数正确、安装
// 结果在 QML 面立即可读。Theme 值类型经 context property 从 C++ 注入
//（QML_STRUCTURED_VALUE 不可从 QML 构造；主题名用 UUID 保证唯一，
// 避免与已有主题冲突导致 installTheme 拒绝）。
//
// 本测试走 Qool 模块插件（QML 面在 Qool.dll 内），与 C++ 直调
// ThemeDB 的测试（tst_singleton_db）覆盖不同副本——外部行为等价。

#include <QtTest>

#include "qool_test.hpp"

#include "style/qool_theme.h"

#include <QQmlComponent>
#include <QQmlContext>
#include <QQmlEngine>
#include <QUuid>

using namespace qoolui;

class TestSingletonWrite : public QObject {
  Q_OBJECT

  QOOL_TEST_CASE(signal_forwarding_and_install) {
    QQmlEngine engine;
    engine.addImportPath(QStringLiteral(QOOLUI_TEST_QML_IMPORT_PATH));

    const QString themeName = QStringLiteral("tst_write_%1")
                                .arg(QUuid::createUuid()
                                       .toString(QUuid::WithoutBraces)
                                       .left(8));
    Theme theme(themeName, { { "marker", "v" } }, {}, {}, {});
    engine.rootContext()->setContextProperty(
      "_tstTheme", QVariant::fromValue(theme));
    engine.rootContext()->setContextProperty("_tstThemeName", themeName);

    QQmlComponent component(&engine);
    component.setData(R"(
import QtQuick
import Qool
Item {
    property string installed: ""
    property string installedName: ""
    Component.onCompleted: {
        ThemeHQ.themeInstalled.connect(function(name) { installed = name })
        ThemeHQ.installTheme(_tstTheme)
        installedName = ThemeHQ.theme(_tstThemeName).name
    }
}
)",
      QUrl::fromLocalFile("tst_singleton_write.qml"));
    QVERIFY(component.isReady());
    if (! component.isReady())
      return;

    QScopedPointer<QObject> obj(component.create());
    QVERIFY(obj);
    if (! obj)
      return;

    // 信号转发：参数 = 安装的主题名
    QCOMPARE(obj->property("installed").toString(), themeName);
    // 写面成功：QML 面读回同名主题（theme() 对未知名回退首主题，
    // 名字对得上即证明安装生效）
    QCOMPARE(obj->property("installedName").toString(), themeName);
  }
};

QTEST_MAIN(TestSingletonWrite)

#include "tst_singleton_write.moc"
