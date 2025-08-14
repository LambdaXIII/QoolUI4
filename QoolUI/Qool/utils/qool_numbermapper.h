#ifndef QOOL_NUMBERMAPPER_H
#define QOOL_NUMBERMAPPER_H

#include "qoolcommon/macro_foreach.hpp"
#include "qoolcommon/qobject_property_macros.hpp"
#include <QObject>
#include <QQmlEngine>

#include "qoolns.hpp"

QOOL_NS_BEGIN

class NumberMapperStop : public QObject {
  Q_OBJECT
  QML_ELEMENT
public:
  explicit NumberMapperStop(QObject* parent = nullptr);

  QOBJECT_WRITABLE_PROPERTY(qreal, position, 0, FINAL)
  QOBJECT_WRITABLE_PROPERTY(qreal, value, 0, FINAL)
};

class NumberMapper : public QObject {
  Q_OBJECT
  QML_ELEMENT
  Q_CLASSINFO("DefaultProperty", "stops")
  Q_PROPERTY(
      QQmlListProperty<NumberMapperStop> stops READ stopList CONSTANT FINAL)
  QML_LIST_PROPERTY_ASSIGN_BEHAVIOR_REPLACE_IF_NOT_DEFAULT

public:
  explicit NumberMapper(QObject* parent = nullptr);

  Q_INVOKABLE qreal valueAt(qreal position) const;

protected:
  Q_SIGNAL void stopsChanged();
  QList<NumberMapperStop*> m_stops;
  QQmlListProperty<NumberMapperStop> stopList();
  static void __appendFunction(
      QQmlListProperty<NumberMapperStop>* property, NumberMapperStop* stop);
  static void __removeLastFunction(
      QQmlListProperty<NumberMapperStop>* property);
  static qsizetype __countFunction(
      QQmlListProperty<NumberMapperStop>* property);

#define DECL(N)                                           \
  QOBJECT_WRITABLE_PROPERTY(qreal, position##N, (N / 10)) \
  QOBJECT_READONLY_PROPERTY_DECLARE(qreal, value##N)

  QOOL_FOREACH_10(DECL, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9)
#undef DECL
};

QOOL_NS_END

#endif // QOOL_NUMBERMAPPER_H
