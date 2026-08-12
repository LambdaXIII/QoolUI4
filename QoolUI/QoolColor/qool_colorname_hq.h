#ifndef QOOL_COLORNAME_HQ_H
#define QOOL_COLORNAME_HQ_H

#include "qoolns.hpp"

#include <QColor>
#include <QObject>
#include <QQmlEngine>
#include <QStringList>

QOOL_NS_BEGIN

// 颜色名 QML 面（QML 单例，每 engine 独立实例）：转发 ColorNameDB 的
// 五个查询方法（names/color/categories/hasColor/name），实现调
// ColorNameDB::instance()。进程级数据（provider 表 + 名称缓存）单份在
// ColorNameDB（C++ 全局单例，不暴露 QML）——本类只承载 QML 面。
// 生命周期：create() → new ColorNameHQ(engine)（parent = engine 管
// 生命周期，多 engine 场景各 engine 一份实例，互不共享对象）。
class ColorNameHQ: public QObject {
  Q_OBJECT
  QML_NAMED_ELEMENT(ColorNameHQ)
  QML_SINGLETON

public:
  static ColorNameHQ* create(QQmlEngine* engine, QJSEngine*) {
    return new ColorNameHQ(engine);
  }

  Q_INVOKABLE QStringList names(const QString& category = {}) const;
  Q_INVOKABLE QColor color(
    const QString& name, const QColor& def = Qt::white) const;
  Q_INVOKABLE QStringList categories() const;
  Q_INVOKABLE bool hasColor(const QString& name) const;
  Q_INVOKABLE QString name(const QColor& color) const;

private:
  explicit ColorNameHQ(QObject* parent = nullptr);
};

QOOL_NS_END

#endif // QOOL_COLORNAME_HQ_H
