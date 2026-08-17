#include "qool_colorname_hq.h"

#include "qool_colorname_db.h"

QOOL_NS_BEGIN

// 单例生命周期、插件 priority 裁决与名称缓存语义见
// docs/reference/Qool.Color/ColorNameHQ.md；本类仅转发 ColorNameDB。

ColorNameHQ::ColorNameHQ(QObject* parent)
  : QObject(parent) {
}

QStringList ColorNameHQ::names(const QString& category) const {
  return ColorNameDB::instance()->names(category);
}

QColor ColorNameHQ::color(
  const QString& name, const QColor& def) const {
  return ColorNameDB::instance()->color(name, def);
}

QStringList ColorNameHQ::categories() const {
  return ColorNameDB::instance()->categories();
}

bool ColorNameHQ::hasColor(const QString& name) const {
  return ColorNameDB::instance()->hasColor(name);
}

QString ColorNameHQ::name(const QColor& c) const {
  return ColorNameDB::instance()->name(c);
}

QOOL_NS_END
