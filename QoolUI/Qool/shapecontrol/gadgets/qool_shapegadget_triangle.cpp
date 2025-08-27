#include "qool_shapegadget_triangle.h"
#include "qool_vector2d.h"
#include "qoolcommon/math/utils.hpp"

QOOL_NS_BEGIN

TriangleGadget::TriangleGadget(QObject* parent)
  : ShapeControlGadget{parent} {

  QBINDABLE_SET_BINDING(isTriangle, [&] {
    const auto a = bindable_pointA().value();
    const auto b = bindable_pointB().value();
    if (a == b) return false;
    const auto c = bindable_pointC().value();
    if (a == c || b == c) return false;
    return true;
  });

  QBINDABLE_SET_BINDING(area, [&] {
    const auto is_tri = bindable_isTriangle().value();
    if (! is_tri) return 0.0;
    const auto a = bindable_pointA().value();
    const auto b = bindable_pointB().value();
    const auto c = bindable_pointC().value();
    auto cross = crossProduct({a, b}, {a, c});
    return std::abs(cross) / 2;
  })

  QBINDABLE_SET_BINDING(centroid, [&] {
    const auto x = math::average({bindable_pointAx().value(),
      bindable_pointBx().value(), bindable_pointCx().value()});
    const auto y = math::average({bindable_pointAy().value(),
      bindable_pointBy().value(), bindable_pointCy().value()});
    return QPointF(x, y);
  });
}

bool __is_point_in_triangle(
    const QPointF& a, const QPointF& b, const QPointF& c, const QPointF& p) {

  const Vector2D ap(a, p);
  const Vector2D bp(b, p);
  const Vector2D cp(c, p);

  const Vector2D ab(a, b);
  const Vector2D bc(b, c);
  const Vector2D ca(c, a);

  const std::array<qreal, 3> crosses{
    crossProduct(ab, ap), crossProduct(bc, bp), crossProduct(ca, cp)};

  bool hasPos(false), hasNeg(false);
  for (const auto& x : crosses) {
    if (math::is_zero(x)) continue;
    if (x > 0) hasPos = true;
    else hasNeg = true;
  }

  return ! (hasPos & hasNeg);
}

bool TriangleGadget::contains(const QPointF& point) const {
  return __is_point_in_triangle(pointA(), pointB(), pointC(), point);
}

QOOL_IMPL_POINT(TriangleGadget, pointA)
QOOL_IMPL_POINT(TriangleGadget, pointB)
QOOL_IMPL_POINT(TriangleGadget, pointC)

QOOL_NS_END
