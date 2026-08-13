#ifndef QOOL_OFFSETPROJECTOR_H
#define QOOL_OFFSETPROJECTOR_H

#include "qoolcommon/qbindable_property_macros.hpp"
#include "qoolcommon/qobject_property_macros.hpp"
#include "qoolns.hpp"
#include <QObject>
#include <QQmlEngine>
#include <QVector2D>

QOOL_NS_BEGIN

class OffsetProjector : public QObject {
  Q_OBJECT
  QML_ELEMENT
public:
  explicit OffsetProjector(QObject* parent = nullptr);

  QBindable<QVector2D> bindable_direction();
  QBindable<QVector2D> bindable_refDirection();
  QBindable<qreal> bindable_refDistance();

protected:
  QOBJECT_WRITABLE_PROPERTY(QVector2D, direction, QVector2D(1, 0), FINAL)
  QOBJECT_WRITABLE_PROPERTY(QVector2D, refDirection, QVector2D(1, 0), FINAL)
  QOBJECT_WRITABLE_PROPERTY(qreal, refDistance, 0, FINAL)

  QBINDABLE_READONLY_PROPERTY(OffsetProjector, QVector2D, offset, FINAL)
};

QOOL_NS_END

#endif // QOOL_OFFSETPROJECTOR_H
