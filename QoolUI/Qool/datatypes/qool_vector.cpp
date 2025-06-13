#include "qool_vector.h"

#include "qoolcommon/math.hpp"

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

QVector2D Vector::normalizedVector() const {
  return vector2d().normalized();
}

float Vector::x() const {
  return m_data->at(2).x();
}

float Vector::y() const {
  return m_data->at(2).y();
}

float Vector::length() const {
  return m_data->at(3).length();
}

float Vector::radians() const {
  const auto& x = m_data->at(3).x();
  const auto& y = m_data->at(3).y();
  return math::vector_radians(x, y);
}

float Vector::degrees() const {
  const auto rad = radians();
  return qRadiansToDegrees(rad);
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

Vector Vector::withNewFrom(const QPointF& f) const {
  return { QVector2D(f), m_data->at(1) };
}

Vector Vector::withNewTo(const QPointF& t) const {
  return { m_data->at(0), QVector2D(t) };
}

Vector Vector::withNewLength(float new_length) const {
  const auto length1 = length();
  if (length1 == 0) {
    return Vector(QPointF(new_length, 0));
  }
  const float factor = new_length / length1;
  const float _x = m_data->at(1).x() * factor;
  const float _y = m_data->at(1).y() * factor;
  return Vector(m_data->at(0), QVector2D(_x, _y));
}

Vector Vector::withNewRadians(float new_rad) const {
  const float old_length = length();
  const auto xy = math::vector_from_radians(old_length, new_rad);
  QVector2D vec { xy.first, xy.second };
  return withNewVector2D(vec);
}

Vector Vector::withNewDegrees(float deg) const {
  const float rad = qDegreesToRadians(deg);
  return withNewRadians(rad);
}

Vector Vector::withNewVector2D(const QVector2D& vector) const {
  const auto v1 = from();
  const auto v2 = v1 + vector;
  return Vector(v1, v2);
}

Vector::Vector(const QVector2D& v1, const QVector2D& v2)
  : m_data { new Data({ v1, v2, v2 - v1 }) } {
}

QOOL_NS_END
