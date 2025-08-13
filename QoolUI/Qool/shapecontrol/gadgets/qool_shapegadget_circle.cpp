#include "qool_shapegadget_circle.h"
#include "qool_polar2d.h"
#include "qool_vector2d.h"
#include "qoolcommon/math/geometry.hpp"

QOOL_NS_BEGIN

CircleGadget::CircleGadget(QObject* parent)
  : ShapeControlGadget{parent} {
  bindable_center().setBinding([&] {
    if (auto ctrl = bindable_control().value(); ctrl)
      return ctrl->bindable_center().value();
    if (auto tgt = bindable_target().value(); tgt)
      return QPointF(
          tgt->bindableWidth().value() / 2, tgt->bindableHeight().value() / 2);
    return QPointF();
  });
  bindable_radius().setBinding([&] {
    if (auto ctrl = bindable_control().value(); ctrl)
      return ctrl->bindable_shortEdge().value() / 2;
    if (auto tgt = bindable_target().value(); tgt) {
      const auto w = tgt->bindableWidth().value();
      const auto h = tgt->bindableHeight().value();
      return std::min(w, h) / 2;
    }
    return 0.0;
  });
  QBINDABLE_SET_BINDING(
      area, [&] { return M_PI * std::pow(bindable_radius().value(), 2); });

  connect(
      this, &CircleGadget::centerChanged, this, &CircleGadget::circleChanged);
  connect(
      this, &CircleGadget::radiusChanged, this, &CircleGadget::circleChanged);

#define IMPL(ANGLE)                                 \
  connect(this, &CircleGadget::circleChanged, this, \
      &CircleGadget::point##ANGLE##Changed);
  QOOL_FOREACH_8(IMPL, 0, 45, 90, 135, 180, 225, 270, 315)
#undef IMPL
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

#define IMPL(ANGLE)                                          \
  QPointF CircleGadget::point##ANGLE() const {               \
    const auto rad = math::radians_from_degrees(ANGLE);      \
    const Polar2D p(radius(), rad);                          \
    return Vector2D(center(), p.vector()).to();              \
  }                                                          \
  QBindable<QPointF> CircleGadget::bindable_point##ANGLE() { \
    return QBindable<QPointF>(this, "point" #ANGLE);         \
  }

QOOL_FOREACH_8(IMPL, 0, 45, 90, 135, 180, 225, 270, 315)

#undef IMPL

QOOL_NS_END
