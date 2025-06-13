#ifndef QOOL_SHAPEHELPERGADGET_CIRCLE_H
#define QOOL_SHAPEHELPERGADGET_CIRCLE_H

#include "qool_shapehelpergadget.h"

#include <QObject>
#include <QQmlEngine>

QOOL_NS_BEGIN

class ShapeHelperGadget_Circle: public ShapeHelperGadget {
  Q_OBJECT
  QML_NAMED_ELEMENT(CircleGadget)

  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE(
    ShapeHelperGadget_Circle, QPointF, center)
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE(
    ShapeHelperGadget_Circle, qreal, radius)

public:
  explicit ShapeHelperGadget_Circle(QObject* parent = nullptr);
  ~ShapeHelperGadget_Circle() = default;

  Q_INVOKABLE QVector2D vectorFromCenter(const QPointF& p) const;
  Q_INVOKABLE qreal distanceFromCenter(const QPointF& p) const;
  Q_INVOKABLE bool isInside(const QPointF& p) const;
  Q_INVOKABLE bool isOnCircle(const QPointF& p) const;
};

QOOL_NS_END

#endif // QOOL_SHAPEHELPERGADGET_CIRCLE_H
