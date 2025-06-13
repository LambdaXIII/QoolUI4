#include "qool_polar2d.h"

#include "qoolcommon/math.hpp"

QOOL_NS_BEGIN

Polar2D::Polar2D()
  : m_data { new Data } {
}

Polar2D::Polar2D(const QPointF& p)
  : Polar2D() {
  auto x = p.x();
  auto y = p.y();
  auto polar = math::polar_from_xy(x, y);
  m_data->x = x;
  m_data->y = y;
  m_data->r = polar.first;
  m_data->a = polar.second;
}

Polar2D::Polar2D(const QPoint& p)
  : Polar2D() {
  auto x = p.x();
  auto y = p.y();
  auto polar = math::polar_from_xy(x, y);
  m_data->x = x;
  m_data->y = y;
  m_data->r = polar.first;
  m_data->a = polar.second;
}

Polar2D::Polar2D(const QVector2D& p)
  : Polar2D() {
  auto x = p.x();
  auto y = p.y();
  auto polar = math::polar_from_xy(x, y);
  m_data->x = x;
  m_data->y = y;
  m_data->r = polar.first;
  m_data->a = polar.second;
}

Polar2D::Polar2D(float radius, float angle) {
  auto xy = math::xy_from_polar(radius, angle);
  m_data->x = xy.first;
  m_data->y = xy.second;
  m_data->r = radius;
  m_data->a = angle;
}

Polar2D::Polar2D(const Polar2D& other)
  : m_data { other.m_data } {
}

float Polar2D::radius() const {
  return m_data->r;
}

float Polar2D::angle() const {
  return m_data->a;
}

float Polar2D::x() const {
  return m_data->x;
}

float Polar2D::y() const {
  return m_data->y;
}

bool Polar2D::isCenter() const {
  return math::is_zero(m_data->r);
}

QVector2D Polar2D::toVector2D() const {
  return { m_data->x, m_data->y };
}

QPointF Polar2D::toPointF() const {
  return { m_data->x, m_data->y };
}

QPoint Polar2D::toPoint() const {
  return QPointF(m_data->x, m_data->y).toPoint();
}

Polar2D::operator QVector2D() const {
  return toVector2D();
}

Polar2D::operator QPointF() const {
  return toPointF();
}

Polar2D::operator QPoint() const {
  return toPoint();
}

Polar2D Polar2D::withRadius(float r) const {
  return Polar2D(r, angle());
}

Polar2D Polar2D::withAngle(float a) const {
  return Polar2D(radius(), a);
}

Polar2D Polar2D::fromPos(float x, float y) {
  return Polar2D(QPointF(x, y));
}

Polar2D Polar2D::fromPos(const std::pair<float, float>& xy) {
  return fromPos(xy.first, xy.second);
}

Polar2D Polar2D::fromPolar(float r, float a) {
  return Polar2D(r, a);
}

Polar2D Polar2D::fromPolar(const std::pair<float, float>& polar) {
  return Polar2D(polar.first, polar.second);
}

QOOL_NS_END
