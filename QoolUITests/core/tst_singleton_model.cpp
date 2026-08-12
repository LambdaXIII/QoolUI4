// Qool 单例契约修复测试：ThemeHQModel 模型代理（C++ 本地副本）
//
// 被测面：ThemeHQModel（QIdentityProxyModel 挂接 ThemeDB::instance()）
// ——rowCount/data/roles 与源模型一致；installTheme 触发 rowsInserted
// 经代理原生转发（视图实时性，无需手动刷新）；双实例数据一致
// （多视图场景无分歧）。源模型为测试 target 内直接编译的 ThemeDB
// 副本（模块插件内的另一份不受影响）。
//
// 插件环境注意：测试 exe 目录无 qoolplugins/，ThemeDB 仅含 SystemTheme
// （≥1 行）。断言一律相对（before/after 对比），不依赖绝对主题数。

#include <QtTest>

#include "qool_test.hpp"

#include "style/qool_theme_db.h"
#include "style/qool_theme_hqmodel.h"

#include <QSignalSpy>
#include <QUuid>

using namespace qoolui;

namespace {

QString uniqueThemeName() {
  return QStringLiteral("tst_model_%1")
    .arg(QUuid::createUuid().toString(QUuid::WithoutBraces).left(8));
}

} // namespace

class TestSingletonModel : public QObject {
  Q_OBJECT

  QOOL_TEST_CASE(basic_model_contract) {
    auto* db = ThemeDB::instance();
    ThemeHQModel model;
    QCOMPARE(model.rowCount(), db->rowCount());
    QVERIFY(model.rowCount() >= 1);

    const QModelIndex src = db->index(0, 0);
    const QModelIndex proxy = model.index(0, 0);
    QCOMPARE(model.data(proxy, Qt::DisplayRole),
      db->data(src, Qt::DisplayRole));
    QCOMPARE(model.data(proxy, Qt::DisplayRole).toString(),
      db->themes().constFirst());

    // roles 与源模型一致（ThemeDB::Roles 起点 Qt::UserRole + 100）
    const auto roles = model.roleNames();
    QVERIFY(roles.contains(Qt::UserRole + 100)); // name
    QVERIFY(roles.contains(Qt::UserRole + 101)); // theme
  }

  QOOL_TEST_CASE(install_forwards_rows_inserted) {
    auto* db = ThemeDB::instance();
    ThemeHQModel model;
    const int before = model.rowCount();

    QSignalSpy spy(&model, &QAbstractItemModel::rowsInserted);
    const QString name = uniqueThemeName();
    db->installTheme(Theme(name, {}, {}, {}, {}));

    QCOMPARE(spy.count(), 1);
    QCOMPARE(model.rowCount(), before + 1);
    const int last = model.rowCount() - 1;
    QCOMPARE(model.index(last, 0).data(Qt::DisplayRole).toString(),
      name);
  }

  QOOL_TEST_CASE(dual_instances_consistent) {
    ThemeHQModel a;
    ThemeHQModel b;
    QCOMPARE(a.rowCount(), b.rowCount());
    for (int r = 0; r < a.rowCount(); ++r) {
      QCOMPARE(a.index(r, 0).data(Qt::DisplayRole),
        b.index(r, 0).data(Qt::DisplayRole));
    }
  }
};

QTEST_MAIN(TestSingletonModel)

#include "tst_singleton_model.moc"
