#include "qool_shapehelpergadget_circle.h"

#include "qoolcommon/math.hpp"

QOOL_NS_BEGIN

ShapeHelperGadget_Circle::ShapeHelperGadget_Circle(QObject* parent)
  : ShapeHelperGadget { parent } {
}

QVector2D ShapeHelperGadget_Circle::vectorFromCenter(
  const QPointF& p) const {
  return { QVector2D(p) - QVector2D(center()) };
}

qreal ShapeHelperGadget_Circle::distanceFromCenter(
  const QPointF& p) const {
  return QVector2D(center()).distanceToPoint(QVector2D(p));
}

bool ShapeHelperGadget_Circle::isInside(const QPointF& p) const {
  return distanceFromCenter(p) <= radius();
}

bool ShapeHelperGadget_Circle::isOnCircle(const QPointF& p) const {
  return math::is_equal(distanceFromCenter(p), radius());
}

QOOL_NS_END
