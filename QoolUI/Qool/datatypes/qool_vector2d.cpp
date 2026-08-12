#include "qool_vector2d.h"

QOOL_NS_BEGIN

Vector2D::Vector2D(const QPointF& from, const QPointF& to)
  : m_from{from}
  , m_vector{to - from} { }

Vector2D::Vector2D(const QPointF& from, const QVector2D& vector)
  : m_from{from}
  , m_vector{vector} { }

Vector2D::Vector2D(const QVector2D& vector)
  : m_vector(vector) { }

Vector2D Vector2D::fromVector(const QVector2D vector, const QPointF& from) {
  auto result = Vector2D(vector);
  result.m_from = from;
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

// 拷贝构造：vector 必须复制 other.m_vector——原实现误用 other.m_from
// （QPointF 隐式转 QVector2D 编译通过但语义错误，拷贝后向量丢失、
// 被起点取代；拷贝赋值 operator= 一直是正确的，二者不一致即笔误证据）
Vector2D::Vector2D(const Vector2D& other)
  : m_from{other.m_from}
  , m_vector{other.m_vector} { }

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

Vector2D Vector2D::operator+(const QVector2D& vector) const {
  Vector2D result;
  result.m_from = m_from;
  result.m_vector = m_vector + vector;
  return result;
}

QVector2D Vector2D::normalized() const { return m_vector.normalized(); }

Vector2D Vector2D::operator+(qreal extra_length) const {
  qreal new_length = length() + extra_length;
  Vector2D result;
  result.m_from = m_from;
  result.m_vector = normalized() * new_length;
  return result;
}

Vector2D Vector2D::operator-(qreal extra_length) const {
  return operator+(-1 * extra_length);
}

Vector2D Vector2D::operator*(qreal factor) const {
  Vector2D result;
  result.m_from = m_from;
  result.m_vector = m_vector * factor;
  return result;
}

Vector2D Vector2D::operator/(qreal divisor) const {
  Q_ASSERT(divisor != 0);
  Vector2D result;
  result.m_from = m_from;
  result.m_vector = m_vector / divisor;
  return result;
}

Vector2D Vector2D::operator-() const {
  Vector2D result;
  result.m_from = m_from;
  result.m_vector = m_vector * -1;
  return result;
}

QPointF Vector2D::operator[](qsizetype index) const {
  if (index == 0) return m_from;
  if (index == 1) return to();
  Q_ASSERT(false);
  return {};
}

QPointF Vector2D::to() const { return m_from + m_vector.toPointF(); }

qreal Vector2D::length() const { return m_vector.length(); }

qreal Vector2D::x() const { return m_vector.x(); }
qreal Vector2D::y() const { return m_vector.y(); }

int __compare__(const Vector2D& a, const Vector2D& b) {
  if (a.from() == b.from() && a.vector() == b.vector()) return 0;
  return -1;
}

QOOL_EQUAL_COMPARE_IMPL(Vector2D, __compare__)

qreal crossProduct(const Vector2D& a, const Vector2D b) {
  return a.x() * b.y() - a.y() * b.x();
}

QOOL_NS_END
