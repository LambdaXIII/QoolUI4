#include "qool_shapegadget_circle.h"
#include "qool_polar2d.h"
#include "qool_vector2d.h"
#include "qoolcommon/math/geometry.hpp"

QOOL_NS_BEGIN

CircleGadget::CircleGadget(QObject* parent)
  : ShapeControlGadget{parent} {
  QBINDABLE_SET_BINDING(
      area, [&] { return M_PI * std::pow(bindable_radius().value(), 2); });
}

bool CircleGadget::contains(const QPointF& point) const {
  const QVector2D vec(point - center());
  return vec.length() <= std::abs(radius());
}

QPointF CircleGadget::pointFromAngle(qreal degrees) const {
  const qreal rad = math::radians_from_degrees(degrees);
  return pointFromRadians(rad);
}

QPointF CircleGadget::pointFromRadians(qreal radians) const {
  auto p = Polar2D(radius(), radians);
  return Vector2D(center(), p.vector()).to();
}

QOOL_IMPL_POINT(CircleGadget, center)

QOOL_NS_END
