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

Polar2D::Polar2D(qreal radius, qreal angle) {
  auto xy = math::xy_from_polar(radius, angle);
  m_data->x = xy.first;
  m_data->y = xy.second;
  m_data->r = radius;
  m_data->a = angle;
}

Polar2D::Polar2D(const Polar2D& other)
  : m_data { other.m_data } {
}

qreal Polar2D::radius() const {
  return m_data->r;
}

qreal Polar2D::angle() const {
  return m_data->a;
}

qreal Polar2D::x() const {
  return m_data->x;
}

qreal Polar2D::y() const {
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

Polar2D Polar2D::withRadius(qreal r) const {
  return Polar2D(r, angle());
}

Polar2D Polar2D::withAngle(qreal a) const {
  return Polar2D(radius(), a);
}

Polar2D Polar2D::fromPos(qreal x, qreal y) {
  return Polar2D(QPointF(x, y));
}

Polar2D Polar2D::fromPos(const std::pair<qreal, qreal>& xy) {
  return fromPos(xy.first, xy.second);
}

Polar2D Polar2D::fromPolar(qreal r, qreal a) {
  return Polar2D(r, a);
}

Polar2D Polar2D::fromPolar(const std::pair<qreal, qreal>& polar) {
  return Polar2D(polar.first, polar.second);
}

QOOL_NS_END

QVector2D operator+(const QVector2D& a, const QOOL_NS::Polar2D& b) {
  return a + b.toVector2D();
}

QVector2D operator-(const QVector2D& a, const QOOL_NS::Polar2D& b) {
  return a - b.toVector2D();
}

QPointF operator+(const QPointF& a, const QOOL_NS::Polar2D& b) {
  return a + b.toPointF();
}

QPointF operator-(const QPointF& a, const QOOL_NS::Polar2D& b) {
  return a - b.toPointF();
}
