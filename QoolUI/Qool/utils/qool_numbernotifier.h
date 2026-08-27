#ifndef QOOL_NUMBERNOTIFIER_H
#define QOOL_NUMBERNOTIFIER_H

#include "qoolcommon/qbindable_property_macros.hpp"
#include "qoolns.hpp"

#include <QObject>
#include <QQmlProperty>
#include <QtQml/qqmlpropertyvaluesource.h>
#include <QtQml/qqmlregistration.h>

class QTimer;

QOOL_NS_BEGIN

class NumberNotifier : public QObject, public QQmlPropertyValueSource {
  Q_OBJECT
  Q_INTERFACES(QQmlPropertyValueSource)
  QML_ELEMENT

public:
  explicit NumberNotifier(QObject* parent = nullptr);

  void setTarget(const QQmlProperty& property) override;

  QBINDABLE_WRITABLE_PROPERTY(NumberNotifier, QObject*, target)
  QBINDABLE_WRITABLE_PROPERTY(NumberNotifier, QString, property)
  QBINDABLE_WRITABLE_PROPERTY(NumberNotifier, int, interval)

  Q_SIGNAL void valueUpdated(qreal newValue, qreal oldValue);
  QBINDABLE_READONLY_PROPERTY(NumberNotifier, qreal, velocity)

private:
  void sample();
  void rebuild_observation();
  void when_targetChanged();
  void when_propertyChanged();
  void when_intervalChanged();

  QQmlProperty m_observed;
  QTimer* m_timer = nullptr;
  bool m_hasLast = false;
  qreal m_lastValue = 0;
};

QOOL_NS_END

#endif // QOOL_NUMBERNOTIFIER_H
