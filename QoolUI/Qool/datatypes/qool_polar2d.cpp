#include "qool_polar2d.h"

#include "qoolcommon/math/geometry.hpp"

QOOL_NS_BEGIN

Polar2D::Polar2D(const QVector2D& vec) {
  if (vec.length() != 0) {
    m_radius = math::hypotenuse(vec.x(), vec.y());
    m_radians = std::atan2(vec.y(), vec.x());
  }
}

Polar2D::Polar2D(const QPointF& from, const QPointF& to)
  : Polar2D{QVector2D(to - from)} { }

Polar2D::Polar2D(qreal radius, qreal radians) {
  m_radius = std::abs(radius);
  m_radians = radians;
  if (radius < 0) {
    m_radians += M_PI;
    // 归一化角度到[-π, π)范围
    m_radians = std::fmod(m_radians + M_PI, 2 * M_PI) - M_PI;
  }
}

Polar2D::Polar2D(const Polar2D& other)
  : m_radius{other.m_radius}
  , m_radians{other.m_radians} { }

Polar2D::Polar2D(Polar2D&& other)
  : m_radius{std::move(other.m_radius)}
  , m_radians{std::move(other.m_radians)} { }

Polar2D& Polar2D::operator=(const Polar2D& other) {
  m_radius = other.m_radius;
  m_radians = other.m_radians;
  return *this;
}

Polar2D& Polar2D::operator=(Polar2D&& other) {
  m_radius = std::move(other.m_radius);
  m_radians = std::move(other.m_radians);
  return *this;
}

Polar2D::operator QVector2D() const { return vector(); }

Polar2D::operator QPointF() const { return vector().toPointF(); }

bool Polar2D::isZero() const { return m_radius == 0; }

Polar2D Polar2D::normalized() const { return Polar2D{1, m_radians}; }

qreal Polar2D::degrees() const { return math::degrees_from_radians(m_radians); }

QVector2D Polar2D::vector() const {
  auto [x, y] = math::xy_from_polar(m_radius, m_radians);
  return {x, y};
}

int __compare__(const Polar2D& a, const Polar2D& b) {
  if (a.isZero() && b.isZero()) return 0;
  if (a.radians() == b.radians() && a.radius() == b.radius()) return 0;
  return -1;
}

QOOL_EQUAL_COMPARE_IMPL(Polar2D, __compare__)

QOOL_NS_END
