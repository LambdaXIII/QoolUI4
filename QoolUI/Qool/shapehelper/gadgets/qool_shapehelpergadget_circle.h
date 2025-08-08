#ifndef QOOL_SHAPEHELPERGADGET_CIRCLE_H
#define QOOL_SHAPEHELPERGADGET_CIRCLE_H

#include "datatypes/qool_polar2d.h"
#include "qool_shapehelpergadget.h"

#include <QObject>
#include <QQmlEngine>

QOOL_NS_BEGIN

class ShapeHelperGadget_Circle: public ShapeHelperGadget {
  Q_OBJECT
  QML_NAMED_ELEMENT(CircleGadget)

  QBINDABLE_WRITABLE_PROPERTY(
    ShapeHelperGadget_Circle, QPointF, center)
  QBINDABLE_WRITABLE_PROPERTY(
    ShapeHelperGadget_Circle, qreal, radius)

  QBINDABLE_READONLY_PROPERTY(
    ShapeHelperGadget_Circle, QPointF, topPoint)
  QBINDABLE_READONLY_PROPERTY(
    ShapeHelperGadget_Circle, QPointF, bottomPoint)
  QBINDABLE_READONLY_PROPERTY(
    ShapeHelperGadget_Circle, QPointF, leftPoint)
  QBINDABLE_READONLY_PROPERTY(
    ShapeHelperGadget_Circle, QPointF, rightPoint)

public:
  explicit ShapeHelperGadget_Circle(QObject* parent = nullptr);
  ~ShapeHelperGadget_Circle() = default;

  Q_INVOKABLE QVector2D vectorFromCenter(const QPointF& p) const;
  Q_INVOKABLE qreal distanceFromCenter(const QPointF& p) const;
  Q_INVOKABLE bool isInside(const QPointF& p) const;
  Q_INVOKABLE bool isOnCircle(const QPointF& p) const;
  Q_INVOKABLE Polar2D polar2d(const QPointF&) const;

  Q_INVOKABLE QPointF keepInside(const QPointF&) const;

  Q_INVOKABLE QPointF pointFromRadians(qreal rad) const;
  Q_INVOKABLE QPointF pointFromDegrees(qreal degree) const;
  Q_INVOKABLE QPointF pointFromPercentage(qreal percent) const;
};

QOOL_NS_END

#endif // QOOL_SHAPEHELPERGADGET_CIRCLE_H
