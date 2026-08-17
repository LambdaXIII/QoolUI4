#include "qool_theme_hq.h"

#include "qool_theme_db.h"

QOOL_NS_BEGIN

ThemeHQ::ThemeHQ(QObject* parent)
  : QObject(parent) {
  // 信号重发：DB 是进程级单例（构造先于本类——instance() 首次调用
  // 即构造），跨 engine 的安装动作在各自 HQ 的 engine 内重发信号；
  // AutoConnection 处理跨线程自动排队（单线程契约，见 ThemeDB 注释）。
  // 注：themes/count 属性读 DB 但无变化通知——DB 的 themesChanged/
  // countChanged 从不发射（installTheme 只发 themeInstalled，与改造前
  // 行为一致）；QML 侧绑定 themes/count 不随安装刷新，需要实时列表请
  // 使用 ThemeHQModel。
  auto* db = ThemeDB::instance();
  connect(db, &ThemeDB::themeInstalled, this, &ThemeHQ::themeInstalled);
}

Theme ThemeHQ::theme(const QString& name) const {
  return ThemeDB::instance()->theme(name);
}

void ThemeHQ::installTheme(Theme theme) {
  ThemeDB::instance()->installTheme(std::move(theme));
}

QVariant ThemeHQ::anyValue(Theme::Groups group,
  const QString& key, const QVariant& defvalue) const {
  return ThemeDB::instance()->anyValue(group, key, defvalue);
}

QVariant ThemeHQ::anyValue(
  const QString& key, const QVariant& defvalue) const {
  return ThemeDB::instance()->anyValue(key, defvalue);
}

qreal ThemeHQ::visualBrightness(QColor color) {
  return ThemeDB::visualBrightness(color);
}

QColor ThemeHQ::recommendForeground(
  const QColor& bgColor, const QColor& light, const QColor& dark) {
  return ThemeDB::recommendForeground(bgColor, light, dark);
}

QStringList ThemeHQ::themes() const {
  return ThemeDB::instance()->themes();
}

int ThemeHQ::count() const {
  return ThemeDB::instance()->count();
}

QOOL_NS_END
