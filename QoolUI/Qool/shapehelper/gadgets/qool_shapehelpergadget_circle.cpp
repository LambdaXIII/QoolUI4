#include "qool_shapehelpergadget_circle.h"

#include "datatypes/qool_polar2d.h"
#include "qoolcommon/math.hpp"

#include <QPointF>

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

Polar2D ShapeHelperGadget_Circle::polar2d(const QPointF& p) const {
  return { vectorFromCenter(p) };
}

QPointF ShapeHelperGadget_Circle::keepInside(const QPointF& p) const {
  const auto r = radius();
  const auto polar = Polar2D(vectorFromCenter(p));
  if (polar.radius() <= r)
    return p;
  return polar.withRadius(r).toPointF();
}

QOOL_NS_END
