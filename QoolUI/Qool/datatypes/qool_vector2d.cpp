#include "qool_vector2d.h"

QOOL_NS_BEGIN

Vector2D::Vector2D(const QPointF& from, const QPointF& to)
  : m_from{from}
  , m_vector{to - from} { }

Vector2D::Vector2D(const QVector2D& vector)
  : m_vector(vector) { }

Vector2D Vector2D::fromVector(const QVector2D vector, const QPointF& from) {
  auto result = Vector2D(vector);
  result.set_from(from);
  return result;
}

Vector2D Vector2D::fromWayPoints(const QList<QPointF>& wayPoints) {
  auto from = wayPoints.value(0, {});
  auto to = wayPoints.isEmpty() ? from : wayPoints.constLast();
  return Vector2D(from, to);
}

Vector2D Vector2D::fromVectors(const QList<QVector2D>& vectors) {
  QVector2D sum =
      std::accumulate(vectors.cbegin(), vectors.cend(), QVector2D(0, 0));
  return Vector2D(sum);
}

Vector2D::Vector2D(const Vector2D& other)
  : m_from{other.m_from}
  , m_vector{other.m_from} { }

Vector2D::Vector2D(Vector2D&& other)
  : m_from{std::move(other.m_from)}
  , m_vector{std::move(other.m_vector)} { }

Vector2D& Vector2D::operator=(const Vector2D& other) {
  m_from = other.m_from;
  m_vector = other.m_vector;
  return *this;
}

Vector2D& Vector2D::operator=(Vector2D&& other) {
  m_from = std ::move(other.m_from);
  m_vector = std::move(other.m_vector);
  return *this;
}

Vector2D::operator QVector2D() const { return vector(); }

Vector2D::operator QPointF() const { return to(); }

Vector2D::operator qreal() const { return length(); }

bool Vector2D::isZero() const {
  return m_from == QPointF(0, 0) && m_vector == QVector2D(0, 0);
}

QPointF Vector2D::to() const { return m_from + m_vector.toPointF(); }

void Vector2D::set_to(const QPointF& x) { m_vector = QVector2D(x - m_from); }

qreal Vector2D::length() const { return m_vector.length(); }

void Vector2D::set_length(const qreal& new_length) {
  const auto old_length = m_vector.length();
  if (new_length == old_length) return;
  if (new_length == 0) {
    m_vector = QVector2D(0, 0);
    return;
  }
  if (old_length == 0) {
    m_vector = QVector2D(new_length, 0);
    return;
  }
  const qreal factor = new_length / old_length;
  m_vector *= factor;
}

QOOL_COMPARE_FUNCTION_IMPL(Vector2D, a, b, {
  if (a.from() == b.from() && a.vector() == b.vector()) return 0;
  return -1;
})

QOOL_EQUAL_COMPARE_IMPL(Vector2D)

QOOL_NS_END
