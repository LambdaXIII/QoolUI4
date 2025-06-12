#include "qool_vector.h"

#include <cmath>

QOOL_NS_BEGIN

std::shared_ptr<Vector::Data> Vector::m_zero_data { new Vector::Data(
  { QVector2D(0, 0), QVector2D(0, 0), QVector2D(0, 0) }) };

Vector::Vector(qreal xpos, qreal ypos) {
  QVector2D v(xpos, ypos);
  m_data = std::shared_ptr<Data>(new Data({ QVector2D(0, 0), v, v }));
}

Vector::Vector(const QVector2D& vector) {
  m_data = std::shared_ptr<Data>(
    new Data({ QVector2D(0, 0), vector, vector }));
}

Vector::Vector(const QPointF& point)
  : Vector(QVector2D(point)) {
}

Vector::Vector(const Vector& other)
  : m_data { other.m_data } {
}

Vector::Vector(const QPointF& from, const QPointF& to) {
  QVector2D v1(from);
  QVector2D v2(to);
  QVector2D v3 { v2.toPointF() - v1.toPointF() };
  m_data = std::shared_ptr<Data>(new Data({ v1, v2, v3 }));
}

const QVector2D& Vector::from() const {
  return m_data->at(0);
}

const QVector2D& Vector::to() const {
  return m_data->at(1);
}

const QVector2D& Vector::vector2d() const {
  return m_data->at(3);
}

float Vector::length() const {
  return m_data->at(3).length();
}

// 测算象限
int __quadrant(float x, float y) {
  if (x >= 0 && y >= 0)
    return 1;
  if (x < 0 && y >= 0)
    return 2;
  if (x < 0 && y < 0)
    return 3;
  if (x >= 0 && y < 0)
    return 4;
  return 0;
}

float __normalize_radian(float rad) {
  while (rad >= M_PI * 2 || rad < 0) {
    if (rad >= M_PI * 2)
      rad -= M_PI * 2;
    if (rad < 0)
      rad += M_PI * 2;
  }
  return rad;
}

float Vector::radian() const {
  const auto& x = m_data->at(3).x();
  const auto& y = m_data->at(3).y();
  float atan = std::atan(y / x);
  int q = __quadrant(x, y);
  float result = atan;
  if (q == 2 || q == 3)
    result = atan + M_PI;
  if (q == 4)
    result = atan + M_PI * 2;
  return __normalize_radian(result);
}

float Vector::angle() const {
  static const qreal ONE_CIRCLE_RADIAN { M_PI * 2 };
  return radian() / ONE_CIRCLE_RADIAN;
}

Vector::operator QVector2D() const {
  return vector2d();
}

Vector::operator QPointF() const {
  return m_data->at(3).toPointF();
}

bool Vector::operator==(const Vector& other) const {
  if (m_data == other.m_data)
    return true;
  if (m_data->at(1) == other.m_data->at(1)
      && m_data->at(2) == m_data->at(2))
    return true;
  return false;
}

bool Vector::operator!=(const Vector& other) const {
  return ! operator==(other);
}

bool Vector::qFuzzyCompare(const Vector& v1, const Vector& v2) {
  return qFuzzyCompare(v1.from(), v2.from())
         && qFuzzyCompare(v1.to(), v2.to());
}

Vector Vector::operator+(const Vector& other) const {
  QVector2D new_to = to() + other.vector2d();
  return { from().toPointF(), new_to.toPointF() };
}

Vector Vector::operator+(const QVector2D& other) const {
  QVector2D new_to = to() + other;
  return { from().toPointF(), new_to.toPointF() };
}

Vector Vector::operator*(qreal factor) const {
  QPointF new_to = to().toPointF() * factor;
  return { from().toPointF(), new_to };
}

QOOL_NS_END
