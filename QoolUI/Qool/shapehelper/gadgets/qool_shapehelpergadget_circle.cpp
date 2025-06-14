#include "qool_shapehelpergadget_circle.h"

#include "datatypes/qool_polar2d.h"
#include "qoolcommon/math.hpp"

#include <QPointF>

QOOL_NS_BEGIN

ShapeHelperGadget_Circle::ShapeHelperGadget_Circle(QObject* parent)
  : ShapeHelperGadget { parent } {
  m_topPoint.setBinding([&] {
    const auto c = bindable_center().value();
    const auto r = bindable_radius().value();
    if (r == 0)
      return c;
    return c + QPointF(0, r);
  });

  m_bottomPoint.setBinding([&] {
    const auto c = bindable_center().value();
    const auto r = bindable_radius().value();
    if (r == 0)
      return c;
    return c + QPointF(0, 0 - r);
  });

  m_leftPoint.setBinding([&] {
    const auto c = bindable_center().value();
    const auto r = bindable_radius().value();
    if (r == 0)
      return c;
    return c + QPointF(0 - r, 0);
  });

  m_rightPoint.setBinding([&] {
    const auto c = bindable_center().value();
    const auto r = bindable_radius().value();
    if (r == 0)
      return c;
    return c + QPointF(r, 0);
  });
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

QPointF ShapeHelperGadget_Circle::pointFromRadians(qreal rad) const {
  rad = math::normalize_radians(rad);
  if (math::is_zero(m_radius))
    return m_center;
  if (math::is_zero(rad) || math::is_equal(rad, M_PI * 2))
    return m_rightPoint;
  if (math::is_equal(rad, M_PI / 2))
    return m_topPoint;
  if (math::is_equal(rad, M_PI))
    return m_leftPoint;
  if (math::is_equal(rad, M_PI / 2 * 3))
    return m_bottomPoint;
  Polar2D pol { radius(), rad };
  return center() + pol.toPointF();
}

QPointF ShapeHelperGadget_Circle::pointFromDegrees(qreal degree) const {
  degree = math::normalize_degrees(degree);
  if (math::is_zero(m_radius))
    return m_center;
  if (math::is_zero(degree) || math::is_equal(degree, 360.0))
    return m_rightPoint;
  if (math::is_equal(degree, 90.0))
    return m_topPoint;
  if (math::is_equal(degree, 180.0))
    return m_leftPoint;
  if (math::is_equal(degree, 270.0))
    return m_bottomPoint;
  return pointFromRadians(math::radians_from_degrees(degree));
}

QPointF ShapeHelperGadget_Circle::pointFromPercentage(
  qreal percent) const {
  percent = std::fmod(percent, 1.0);
  if (math::is_zero(m_radius))
    return m_center;
  if (math::is_zero(percent) || math::is_equal(percent, 1.0))
    return m_rightPoint;
  if (math::is_equal(percent, 0.25))
    return m_topPoint;
  if (math::is_equal(percent, 0.5))
    return m_leftPoint;
  if (math::is_equal(percent, 0.75))
    return m_bottomPoint;
  return pointFromRadians(percent / M_PI * 2);
}

QOOL_NS_END
