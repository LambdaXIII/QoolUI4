#include "qool_shapegadget_circlepoint.h"
#include "qool_polar2d.h"
#include "qool_vector2d.h"
#include "qoolcommon/math/geometry.hpp"

QOOL_NS_BEGIN

CirclePoint::CirclePoint(QObject* parent)
  : ShapeControlGadget{parent} {

  QBINDABLE_SET_BINDING(attachedCircle,
      [&] { return qobject_cast<CircleGadget*>(bindableParent().value()); });

  QBINDABLE_SET_BINDING(center, [&] {
    if (auto circle = bindable_attachedCircle().value(); circle)
      return circle->bindable_center().value();
    if (auto control = bindable_control().value(); control)
      return control->bindable_center().value();
    if (auto target = bindable_target().value(); target)
      return QPointF(target->bindableWidth().value() / 2,
          target->bindableHeight().value() / 2);
    return QPointF();
  });

  QBINDABLE_SET_BINDING(radius, [&] {
    if (auto circle = bindable_attachedCircle().value(); circle)
      return circle->bindable_radius().value();
    if (auto control = bindable_control().value(); control)
      return control->bindable_shortEdge().value() / 2;
    if (auto target = bindable_target().value(); target)
      return std::min(target->bindableWidth().value(),
                 target->bindableHeight().value())
           / 2;
    return 0.0;
  });

  QBINDABLE_SET_BINDING(position, [&] {
    const auto r = bindable_radius().value();
    const auto a = bindable_radians().value();
    const auto c = bindable_center().value();
    Polar2D polar(r, a);
    return Vector2D(c, polar.vector()).to();
  });

  QBINDABLE_SET_BINDING(x, [&] { return bindable_position().value().x(); });
  QBINDABLE_SET_BINDING(y, [&] { return bindable_position().value().y(); });
}

QBindable<qreal> CirclePoint::bindable_radians() {
  return QBindable<qreal>(this, "radians");
}

QBindable<qreal> CirclePoint::bindable_angle() {
  return QBindable<qreal>(this, "angle");
}

void CirclePoint::componentComplete() { emit parentChanged(); }

qreal CirclePoint::angle() const {
  return math::degrees_from_radians(m_radians);
}

void CirclePoint::set_angle(const qreal& a) {
  set_radians(math::radians_from_degrees(a));
}

QOOL_NS_END
