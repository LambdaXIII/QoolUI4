// Qool 单例契约修复测试：DB 接口保留 + HQ 转发等价（C++ 本地副本）
//
// 被测面：4 个 DB 摘除 QML 暴露后 C++ 面完整可用（ThemeDB 查询/写面/
// 静态工具、ColorNameDB 查询默认路径、FileIconDB 路由与 iconUrl、
// FileInfoDB 缓存查询）；ThemeHQ 转发与 DB 结果一致（US3 等价断言）。
// 源文件直接编译进测试 target（仓库「绝不动态导出」——模块 DLL 内
// 的副本由模块侧测试覆盖，两侧外部行为等价）。
//
// 插件环境注意：测试 exe 目录无 qoolplugins/——ColorNameDB 无插件，
// 走默认值路径；FileIconDB 无 provider，requestPath 返回空。断言
// 均用"必然成立"的未知项（插件色表/图标表不可能覆盖的专有名字）。

#include <QtTest>

#include "qool_test.hpp"

#include "qool_colorname_db.h"
#include "qool_fileicon_db.h"
#include "qool_fileicon_imageprovider.h"
#include "qool_fileinfo_db.h"
#include "style/qool_theme_db.h"
#include "style/qool_theme_hq.h"

#include <QQmlEngine>
#include <QDir>
#include <QTemporaryDir>
#include <QFile>

using namespace qoolui;

class TestSingletonDb : public QObject {
  Q_OBJECT

  QOOL_TEST_CASE(theme_db_contract) {
    auto* db = ThemeDB::instance();
    QVERIFY(db->rowCount() >= 1);
    // Style 路径等价：theme("system") 名称正确
    QCOMPARE(db->theme(QString("system")).name(), QString("system"));
    // 未知名回退已安装首主题
    const QString first = db->themes().constFirst();
    QCOMPARE(db->theme(QStringLiteral("qoolui_no_such_theme")).name(),
      first);
    // anyValue 默认路径
    QCOMPARE(db->anyValue(QStringLiteral("qoolui_no_such_key"), 42),
      QVariant(42));
    QCOMPARE(db->count(), db->themes().length());
  }

  QOOL_TEST_CASE(theme_hq_forwarding_equivalent) {
    QQmlEngine engine;
    // create() 返回实例 parent = engine（生命周期由 engine 管）
    auto* hq = ThemeHQ::create(&engine, nullptr);
    auto* db = ThemeDB::instance();
    QCOMPARE(hq->theme(QString("system")).name(),
      db->theme(QString("system")).name());
    QCOMPARE(hq->anyValue(QStringLiteral("qoolui_no_such_key"), 42),
      QVariant(42));
    QCOMPARE(hq->themes(), db->themes());
    QCOMPARE(hq->count(), db->count());
    QCOMPARE(hq->recommendForeground("#ff0000"),
      ThemeDB::recommendForeground("#ff0000"));
    QCOMPARE(hq->visualBrightness("#ff0000"),
      ThemeDB::visualBrightness("#ff0000"));
  }

  QOOL_TEST_CASE(colorname_db_contract) {
    auto* db = ColorNameDB::instance();
    const QColor def("#123456");
    // 未知名回退 def（默认值路径，任何插件集下成立）
    QCOMPARE(db->color(QStringLiteral("qoolui_no_such_color"), def),
      def);
    QVERIFY(! db->hasColor(QStringLiteral("qoolui_no_such_color")));
    // 无插件匹配时返回 #RRGGBB 文本
    QCOMPARE(db->name(QColor("#123456")), QString("#123456"));
  }

  QOOL_TEST_CASE(fileicon_db_contract) {
    auto* db = FileIconDB::instance();
    // 无 provider 能提供该 id → 空路径
    QVERIFY(db->requestPath(QStringLiteral("qoolui_no_such_icon"))
              .isEmpty());
    QVERIFY(db->requrestUrl(QStringLiteral("qoolui_no_such_icon"))
              .isEmpty());
    // iconUrl 能力面 = compileUrl(fileUrl.toString(QUrl::PreferLocalFile))。
    // 使用可移植的本目录绝对路径，避免 Windows 盘符路径在 Linux 上被
    // fromLocalFile 加前导斜杠导致两边编码不一致。
    const QUrl fileUrl =
      QUrl::fromLocalFile(QDir::current().filePath("x/y.png"));
    QCOMPARE(db->iconUrl(fileUrl),
      FileIconImageProvider::compileUrl(
        fileUrl.toString(QUrl::PreferLocalFile)));
  }

  QOOL_TEST_CASE(fileinfo_db_contract) {
    QTemporaryDir dir;
    QFile file(dir.filePath("tst_info.txt"));
    QVERIFY(file.open(QIODevice::WriteOnly));
    file.write("hello");
    file.close();

    const QVariantMap info = FileInfoDB::instance()->getFileInfo(
      QUrl::fromLocalFile(file.fileName()));
    QCOMPARE(info.value("fileName").toString(), QString("tst_info.txt"));
    QVERIFY(info.value("iconUrl").toUrl().toString().startsWith(
      "image://qoolfileicon/"));

    // 字符串路径重载等价（命中同一缓存）
    const QVariantMap info2 =
      FileInfoDB::instance()->getFileInfo(file.fileName());
    QCOMPARE(info2.value("fileName").toString(),
      QString("tst_info.txt"));
  }
};

QTEST_MAIN(TestSingletonDb)

#include "tst_singleton_db.moc"
