#ifndef QOOL_COLORMAPPER_H
#define QOOL_COLORMAPPER_H

#include "qoolcommon/lazy_cache.hpp"
#include "qoolcommon/macro_foreach.hpp"
#include "qoolcommon/qobject_property_macros.hpp"
#include "qoolns.hpp"
#include <QColor>
#include <QObject>
#include <QQmlEngine>

QOOL_NS_BEGIN

class ColorMapperStop : public QObject {
  Q_OBJECT
  QML_ELEMENT
public:
  explicit ColorMapperStop(QObject* parent = nullptr)
    : QObject(parent) { }
  QOBJECT_WRITABLE_PROPERTY(qreal, position, 0)
  QOBJECT_WRITABLE_PROPERTY(QColor, color, )
};

class ColorMapper : public QObject {
  Q_OBJECT
  QML_ELEMENT
  Q_CLASSINFO("DefaultProperty", "stops")
  Q_PROPERTY(
      QQmlListProperty<ColorMapperStop> stops READ stopList CONSTANT FINAL)
  QML_LIST_PROPERTY_ASSIGN_BEHAVIOR_REPLACE_IF_NOT_DEFAULT
public:
  explicit ColorMapper(QObject* parent = nullptr);
  enum Modes { RGB, HSV, HSL, CMYK };
  Q_ENUM(Modes)

  Q_INVOKABLE QColor colorAt(qreal position) const;

protected:
  Q_SIGNAL void updateRequested();
  QList<ColorMapperStop*> m_stops;
  QQmlListProperty<ColorMapperStop> stopList();
  static void __appendFunction(
      QQmlListProperty<ColorMapperStop>* property, ColorMapperStop* stop);
  static void __removeLastFunction(QQmlListProperty<ColorMapperStop>* property);
  static qsizetype __countFunction(QQmlListProperty<ColorMapperStop>* property);

  LazyCache<QList<ColorMapperStop*>> m_sortedStops;

  QOBJECT_WRITABLE_PROPERTY(Modes, mode, RGB, FINAL)

#define DECL(N)                                             \
  QOBJECT_WRITABLE_PROPERTY(qreal, position##N, (N / 10.0)) \
  QOBJECT_READONLY_PROPERTY_DECLARE(QColor, color##N)

  QOOL_FOREACH_10(DECL, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9)
#undef DECL
};

QOOL_NS_END

#endif // QOOL_COLORMAPPER_H
