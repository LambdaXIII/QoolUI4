#ifndef QOOL_SHAPEGADGET_CIRCLEPOINT_H
#define QOOL_SHAPEGADGET_CIRCLEPOINT_H

#include "qool_shapecontrol_gadget.h"
#include "qool_shapegadget_circle.h"
#include "qoolcommon/qbindable_property_macros.hpp"
#include "qoolcommon/qobject_property_macros.hpp"
#include "qoolns.hpp"
#include <QObject>
#include <QQmlEngine>

QOOL_NS_BEGIN

class CirclePoint : public ShapeControlGadget {
  Q_OBJECT
  QML_ELEMENT
public:
  explicit CirclePoint(QObject* parent = nullptr);
  QBindable<qreal> bindable_radians();
  QBindable<qreal> bindable_angle();

protected:
  void componentComplete() override;

  QBINDABLE_WRITABLE_PROPERTY(CirclePoint, CircleGadget*, attachedCircle)
  QBINDABLE_WRITABLE_PROPERTY(CirclePoint, QPointF, center)
  QBINDABLE_WRITABLE_PROPERTY(CirclePoint, qreal, radius)

  QOBJECT_WRITABLE_PROPERTY_DECLARE(qreal, angle)
  QOBJECT_WRITABLE_PROPERTY(qreal, radians, 0)

  QBINDABLE_READONLY_PROPERTY(CirclePoint, QPointF, position)
  QBINDABLE_READONLY_PROPERTY(CirclePoint, qreal, x)
  QBINDABLE_READONLY_PROPERTY(CirclePoint, qreal, y)
};

QOOL_NS_END

#endif // QOOL_SHAPEGADGET_CIRCLEPOINT_H
