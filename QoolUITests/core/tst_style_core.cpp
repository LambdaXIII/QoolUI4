// Style 核心契约测试（C++ 直编被测源）
//
// 被测面（docs/articles/style-system.md「行为契约」）：
// - C4 set_value 相等守卫：赋相同值应返回 false 且不发 valueChanged
//   （原实现 `m_activeData == value` 为整表与单值比较恒 false——守卫失效，
//   已修为比较该键当前值）
// - C8 修改键按组独立：mark_modified/is_modified 三组互不影响、键独立
// - C9 Theme 查找优先级：Custom > 组自身 > Active 兜底 > Constants >
//   默认值；flatMap 合并序（Constants + Active + 组 + Custom）
// - C10 ThemeDB 契约：重名/空名拒绝、未知名回退首主题、installTheme
//   发 themeInstalled + rowsInserted
// - C11 follow 跟随：目标值变化实时拷贝、本地修改键不被覆盖
//
// 源文件直接编译进测试 target（仓库「绝不动态导出」——模块 DLL 内副本
// 由 QML 面测试覆盖，两侧外部行为等价）。
//
// 注意：Style 构造不依赖 QML 场景（initialize() 无附加父级时无传播），
// set_value/get_value/mark_modified/is_modified/set_follow 均为 public，
// 可直接 C++ 调用。

#include <QtTest>

#include "qool_test.hpp"

#include "style/qool_style.h"
#include "style/qool_theme.h"
#include "style/qool_theme_db.h"

#include <QUuid>

using namespace qoolui;

class TestStyleCore : public QObject {
  Q_OBJECT

  // C4：set_value 相等守卫——相同值必须短路（返回 false、不发信号）
  QOOL_TEST_CASE(set_value_guard) {
    Style s;
    QSignalSpy spy(&s, &Style::valueChanged);

    const QColor red("#ff0000");
    QVERIFY(s.set_value(Style::Active, "accent", red));
    QCOMPARE(spy.count(), 1);

    // 契约：赋相同值 → false + 不发信号（守卫比较该键当前值，短路）
    QVERIFY(! s.set_value(Style::Active, "accent", red));
    QCOMPARE(spy.count(), 1);
  }

  // C8：修改键按组独立、按键独立
  QOOL_TEST_CASE(modified_keys_per_group) {
    Style s;
    QVERIFY(! s.is_modified(Style::Active, "accent"));
    QVERIFY(! s.is_modified(Style::Inactive, "accent"));

    s.mark_modified(Style::Active, "accent");
    QVERIFY(s.is_modified(Style::Active, "accent"));
    QVERIFY(! s.is_modified(Style::Inactive, "accent"));
    QVERIFY(! s.is_modified(Style::Disabled, "accent"));
    QVERIFY(! s.is_modified(Style::Active, "base"));

    s.mark_modified(Style::Inactive, "accent");
    QVERIFY(s.is_modified(Style::Inactive, "accent"));
    QVERIFY(s.is_modified(Style::Active, "accent"));
  }

  // C9：Theme 查找优先级 + flatMap 合并序
  QOOL_TEST_CASE(theme_lookup_precedence) {
    Theme t(QStringLiteral("tst_lookup"),
      { { "constKey", QStringLiteral("constVal") } },
      { { "activeKey", QStringLiteral("activeVal") } },
      { { "inactiveKey", QStringLiteral("inactiveVal") } },
      { { "disabledKey", QStringLiteral("disabledVal") } },
      { { "customKey", QStringLiteral("customVal") } });

    // Custom 最高优先（任意组命中）
    QCOMPARE(t.value(Theme::Active, "customKey").toString(),
      QStringLiteral("customVal"));
    QCOMPARE(t.value(Theme::Disabled, "customKey").toString(),
      QStringLiteral("customVal"));
    // 组自身
    QCOMPARE(t.value(Theme::Active, "activeKey").toString(),
      QStringLiteral("activeVal"));
    QCOMPARE(t.value(Theme::Inactive, "inactiveKey").toString(),
      QStringLiteral("inactiveVal"));
    // Active 兜底（组非 Active 且组内无此键）
    QCOMPARE(t.value(Theme::Inactive, "activeKey").toString(),
      QStringLiteral("activeVal"));
    QCOMPARE(t.value(Theme::Disabled, "activeKey").toString(),
      QStringLiteral("activeVal"));
    // Inactive 不兜底（只有 Active 兜底）
    QCOMPARE(t.value(Theme::Disabled, "inactiveKey"), QVariant());
    // Constants
    QCOMPARE(t.value(Theme::Active, "constKey").toString(),
      QStringLiteral("constVal"));
    // 默认值
    QCOMPARE(t.value(Theme::Active, QStringLiteral("no_such_key"), 42),
      QVariant(42));

    // flatMap(Active) = Constants + Active + Custom
    const auto fa = t.flatMap(Theme::Active);
    QCOMPARE(fa.value("constKey").toString(), QStringLiteral("constVal"));
    QCOMPARE(fa.value("activeKey").toString(), QStringLiteral("activeVal"));
    QCOMPARE(fa.value("customKey").toString(), QStringLiteral("customVal"));
    // flatMap(Inactive) = Constants + Active + Inactive + Custom
    const auto fi = t.flatMap(Theme::Inactive);
    QCOMPARE(fi.value("activeKey").toString(), QStringLiteral("activeVal"));
    QCOMPARE(fi.value("inactiveKey").toString(),
      QStringLiteral("inactiveVal"));
  }

  // C10：ThemeDB 安装/拒绝/回退/通知
  QOOL_TEST_CASE(theme_db_contract) {
    auto* db = ThemeDB::instance();
    const QString name = QStringLiteral("tst_core_%1")
                           .arg(QUuid::createUuid()
                                  .toString(QUuid::WithoutBraces)
                                  .left(8));
    const int before = db->rowCount();
    QSignalSpy spy(db, &ThemeDB::themeInstalled);

    db->installTheme(Theme(name, {}, {}, {}, {}));
    QCOMPARE(spy.count(), 1);
    QCOMPARE(db->rowCount(), before + 1);

    // 重名拒绝
    db->installTheme(Theme(name, {}, {}, {}, {}));
    QCOMPARE(spy.count(), 1);
    QCOMPARE(db->rowCount(), before + 1);
    // 空名拒绝
    db->installTheme(Theme(QString(), {}, {}, {}, {}));
    QCOMPARE(db->rowCount(), before + 1);

    // 未知名回退首主题
    QCOMPARE(db->theme(QStringLiteral("qoolui_no_such_theme")).name(),
      db->themes().constFirst());
  }

  // C11：follow 实时跟随 + 本地修改键跳过
  QOOL_TEST_CASE(follow_contract) {
    QScopedPointer<Style> a(new Style(nullptr));
    QScopedPointer<Style> b(new Style(nullptr));

    b->set_follow(a.data());
    a->set_value(Style::Active, "accent", QColor("#ff0000"));
    QCOMPARE(b->get_value(Style::Active, "accent").value<QColor>(),
      QColor("#ff0000"));

    // 本地修改键不被覆盖（模拟 typed setter：set_value + mark_modified）
    b->set_value(Style::Active, "base", QColor("#000000"));
    b->mark_modified(Style::Active, "base");
    a->set_value(Style::Active, "base", QColor("#ffffff"));
    QCOMPARE(b->get_value(Style::Active, "base").value<QColor>(),
      QColor("#000000"));
    // 未修改键继续跟随
    a->set_value(Style::Inactive, "accent", QColor("#00ff00"));
    QCOMPARE(b->get_value(Style::Inactive, "accent").value<QColor>(),
      QColor("#00ff00"));
  }
};

QTEST_MAIN(TestStyleCore)

#include "tst_style_core.moc"
