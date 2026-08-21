#ifndef QOOL_SHAPEGADGET_CIRCLE_H
#define QOOL_SHAPEGADGET_CIRCLE_H

#include "qool_shape_macros.hpp"
#include "qool_shapecontrol_gadget.h"
#include "qoolcommon/macro_foreach.hpp"
#include "qoolcommon/qbindable_property_macros.hpp"
#include <QObject>
#include <QQmlEngine>

QOOL_NS_BEGIN

class CircleGadget : public ShapeControlGadget {
  Q_OBJECT
  QML_ELEMENT
  Q_CLASSINFO("ShapeControlGadgetName", "Triangle")

public:
  explicit CircleGadget(QObject* parent = nullptr);
  Q_INVOKABLE bool contains(const QPointF& point) const override;

  Q_INVOKABLE QPointF pointFromAngle(qreal degrees) const;
  Q_INVOKABLE QPointF pointFromRadians(qreal radians) const;

  Q_SIGNAL void circleChanged();

protected:
  QOOL_DECL_POINT(center)
  QBINDABLE_WRITABLE_PROPERTY(CircleGadget, qreal, radius)
  QBINDABLE_READONLY_PROPERTY(CircleGadget, qreal, area)

#define DECL(ANGLE)                                               \
  QOBJECT_READONLY_PROPERTY_DECLARE(QPointF, point##ANGLE)         \
public:                                                           \
  QBindable<QPointF> bindable_point##ANGLE();

  QOOL_FOREACH_8(DECL, 0, 45, 90, 135, 180, 225, 270, 315)

#undef DECL
};

QOOL_NS_END

#endif // QOOL_SHAPEGADGET_CIRCLE_H
