#ifndef QOOL_COLORNAME_DB_H
#define QOOL_COLORNAME_DB_H

#include "qool_interface_colornameprovider.h"
#include "qoolcommon/singleton.hpp"
#include "qoolns.hpp"

#include <QColor>
#include <QMap>
#include <QObject>
#include <QSet>

QOOL_NS_BEGIN

// 颜色名数据库（进程级 C++ 单例）：provider 表 + 名称缓存 + 查询方法
// 的唯一持有者。不暴露 QML——Qt 契约：共享实例经 QML_SINGLETON 暴露
// 只能被一个 QQmlEngine 访问（多 engine 崩溃）。QML 面由 ColorNameHQ
// （每 engine 独立实例）承载并转发，见 qool_colorname_hq.h。
class ColorNameDB: public QObject {
  Q_OBJECT
  QOOL_SIMPLE_SINGLETON_DECL(ColorNameDB)

protected:
  QMap<qreal, ColorNameProvider*> m_providers;
  QSet<QString> m_nameCache;
  void installPlugins();

  static QColor decode(std::optional<ColorNameProvider::QoolRGBA> rgba);
  static ColorNameProvider::QoolRGBA encode(const QColor& c);

public:
  ~ColorNameDB();

  QStringList names(const QString& category = {}) const;
  QColor color(
    const QString& name, const QColor& def = Qt::white) const;
  QStringList categories() const;
  bool hasColor(const QString& name) const;
  QString name(const QColor& color) const;
};

QOOL_NS_END

#endif // QOOL_COLORNAME_DB_H
