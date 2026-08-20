// Style 主题切换/边界契约测试（C++ 驱动 QML 场景）
//
// 被测面（docs/articles/style-system.md「行为契约」）：
// - C2 覆盖持久：节点显式 Style.accent = x 后根主题切换——accent 保留 x
//   （节点设计意图），未覆盖属性跟随新主题
// - C3 主题边界：显式设置 theme 的节点成为子树主题源——祖先 theme 变化
//   不穿透，子区域保持自身主题（set_theme 置 m_explicitTheme，inherit 拒绝
//   显式源节点的父级传播）
//
// 为何 C++ 驱动：QML 测试批次无主题插件（仅 system），且 Theme 值类型
// 不可从 QML 构造——经 context property 从 C++ 注入主题（tst_singleton_write
// 同款模式），场景内 ThemeHQ.installTheme 安装后切换。
//
// 主题数据经 QVariant(QColor) 存储，断言用 QColor::name() 规范化比较
//（QColor 整值 compare 因 spec 差异不可靠——同仓库惯例）。
//
// 摩擦规避（测试设施）：Q_OBJECT 类内禁用 R"(...)" 原始字符串字面量——
// moc 对原始字符串解析有缺陷（内容含 "#..." 或 // 注释时 Q_OBJECT 类
// 不被收集，链接缺 metaObject 符号）；一律用普通字符串拼接。

#include <QtTest>

#include "qool_test.hpp"

#include "style/qool_theme.h"

#include <QQmlComponent>
#include <QQmlContext>
#include <QQmlEngine>

using namespace qoolui;

namespace {
// 三个测试主题：active 组提供 accent/base，三主题值互不相同
Theme makeTheme(const QString& name, const char* accent, const char* base) {
  QVariantMap active;
  active.insert(QStringLiteral("accent"), QColor(QString::fromLatin1(accent)));
  active.insert(QStringLiteral("base"), QColor(QString::fromLatin1(base)));
  return Theme(name, QVariantMap(), active, QVariantMap(), QVariantMap());
}
} // namespace

namespace {
// QML 场景字符串（C2：节点覆盖 accent；C3：子节点独立 theme）——普通
// 字符串拼接（非原始字符串，见文件头摩擦规避）
const char* kSceneOverride =
  "import QtQuick\n"
  "import Qool\n"
  "Item {\n"
  "    objectName: \"scene\"\n"
  "    function setupThemes() {\n"
  "        ThemeHQ.installTheme(_themeA)\n"
  "        ThemeHQ.installTheme(_themeB)\n"
  "        ThemeHQ.installTheme(_themeC)\n"
  "        Style.theme = \"tst_a\"\n"
  "    }\n"
  "    function switchRootTheme(name) { Style.theme = name }\n"
  "    Item {\n"
  "        objectName: \"node\"\n"
  "        property color accentProbe: Style.accent\n"
  "        property color baseProbe: Style.base\n"
  "        Style.accent: \"red\"\n"
  "    }\n"
  "}\n";

const char* kSceneBoundary =
  "import QtQuick\n"
  "import Qool\n"
  "Item {\n"
  "    objectName: \"scene\"\n"
  "    function setupThemes() {\n"
  "        ThemeHQ.installTheme(_themeA)\n"
  "        ThemeHQ.installTheme(_themeB)\n"
  "        ThemeHQ.installTheme(_themeC)\n"
  "        Style.theme = \"tst_a\"\n"
  "        sub.Style.theme = \"tst_b\"\n"
  "    }\n"
  "    function switchRootTheme(name) { Style.theme = name }\n"
  "    Item {\n"
  "        id: sub\n"
  "        objectName: \"sub\"\n"
  "        property color accentProbe: Style.accent\n"
  "        property color baseProbe: Style.base\n"
  "    }\n"
  "}\n";
} // namespace

class TestStyleThemeSwitch : public QObject {
  Q_OBJECT

  // C2：显式覆盖在主题切换后保留；未覆盖属性跟随新主题
  QOOL_TEST_CASE(override_survives_theme_switch) {
    QQmlEngine engine;
    engine.addImportPath(QStringLiteral(QOOLUI_TEST_QML_IMPORT_PATH));

    engine.rootContext()->setContextProperty(
      "_themeA", QVariant::fromValue(makeTheme("tst_a", "#aa0000", "#111111")));
    engine.rootContext()->setContextProperty(
      "_themeB", QVariant::fromValue(makeTheme("tst_b", "#aa1111", "#222222")));
    engine.rootContext()->setContextProperty(
      "_themeC", QVariant::fromValue(makeTheme("tst_c", "#aa2222", "#333333")));

    QQmlComponent component(&engine);
    component.setData(QByteArray(kSceneOverride),
      QUrl::fromLocalFile("tst_style_theme_switch.qml"));
    QVERIFY(component.isReady());
    if (! component.isReady())
      return;
    QScopedPointer<QObject> obj(component.create());
    QVERIFY(obj);
    if (! obj)
      return;
    QObject* node = obj->findChild<QObject*>("node");
    QVERIFY(node);
    if (! node)
      return;

    QMetaObject::invokeMethod(obj.data(), "setupThemes");
    // 覆盖值生效（"red" == #ff0000）、未覆盖属性 = tst_a
    QTRY_COMPARE(node->property("accentProbe").value<QColor>().name(),
      QColor("#ff0000").name());
    QTRY_COMPARE(node->property("baseProbe").value<QColor>().name(),
      QColor("#111111").name());

    // 根切换 tst_b：accent 保留覆盖（节点设计意图），base 跟随新主题
    QMetaObject::invokeMethod(
      obj.data(), "switchRootTheme", Q_ARG(QVariant, QStringLiteral("tst_b")));
    QTRY_COMPARE(node->property("accentProbe").value<QColor>().name(),
      QColor("#ff0000").name());
    QTRY_COMPARE(node->property("baseProbe").value<QColor>().name(),
      QColor("#222222").name());
  }

  // C3：主题边界——子节点显式设置 theme 后，根主题变化不穿透
  QOOL_TEST_CASE(theme_boundary) {
    QQmlEngine engine;
    engine.addImportPath(QStringLiteral(QOOLUI_TEST_QML_IMPORT_PATH));

    engine.rootContext()->setContextProperty(
      "_themeA", QVariant::fromValue(makeTheme("tst_a", "#aa0000", "#111111")));
    engine.rootContext()->setContextProperty(
      "_themeB", QVariant::fromValue(makeTheme("tst_b", "#aa1111", "#222222")));
    engine.rootContext()->setContextProperty(
      "_themeC", QVariant::fromValue(makeTheme("tst_c", "#aa2222", "#333333")));

    QQmlComponent component(&engine);
    component.setData(QByteArray(kSceneBoundary),
      QUrl::fromLocalFile("tst_style_theme_switch.qml"));
    QVERIFY(component.isReady());
    if (! component.isReady())
      return;
    QScopedPointer<QObject> obj(component.create());
    QVERIFY(obj);
    if (! obj)
      return;
    QObject* sub = obj->findChild<QObject*>("sub");
    QVERIFY(sub);
    if (! sub)
      return;

    // 子区域初始 = 自身主题 tst_b（根为 tst_a，子节点独立设置）
    QMetaObject::invokeMethod(obj.data(), "setupThemes");
    QTRY_COMPARE(sub->property("accentProbe").value<QColor>().name(),
      QColor("#aa1111").name());
    QTRY_COMPARE(sub->property("baseProbe").value<QColor>().name(),
      QColor("#222222").name());

    // 根切换 tst_c：契约 = 子区域保持 tst_b（主题边界断裂，祖先不穿透）——
    // 子节点显式设置 theme 后成为源，inherit 拒绝父级传播。
    QMetaObject::invokeMethod(
      obj.data(), "switchRootTheme", Q_ARG(QVariant, QStringLiteral("tst_c")));
    QTRY_COMPARE(sub->property("accentProbe").value<QColor>().name(),
      QColor("#aa1111").name());
    QTRY_COMPARE(sub->property("baseProbe").value<QColor>().name(),
      QColor("#222222").name());
  }
};

QTEST_MAIN(TestStyleThemeSwitch)

#include "tst_style_theme_switch.moc"
