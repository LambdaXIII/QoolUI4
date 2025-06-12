#ifndef QOOL_VECTOR_H
#define QOOL_VECTOR_H

#include "qoolcommon/qoolns.hpp"

#include <QObject>
#include <QPointF>
#include <QQmlEngine>
#include <QSharedDataPointer>
#include <QVector2D>
#include <memory>

QOOL_NS_BEGIN

class Vector {
  Q_GADGET
  QML_VALUE_TYPE(qoolvector)
  QML_STRUCTURED_VALUE

public:
  using Data = std::array<QVector2D, 3>;

  Vector(qreal xpos = 0, qreal ypos = 0);
  Vector(const QVector2D& vector);
  Vector(const QPointF& point);
  Vector(const QPoint& point);
  Vector(const Vector& other);
  Vector(const QPointF& from, const QPointF& to);

  const QVector2D& from() const;
  const QVector2D& to() const;
  const QVector2D& vector2d() const;

  float length() const;
  float radian() const;
  float angle() const;

  operator QVector2D() const;
  operator QPointF() const;

  bool operator==(const Vector& other) const;
  bool operator!=(const Vector& other) const;
  static bool qFuzzyCompare(const Vector& v1, const Vector& v2);

  Vector operator+(const Vector& other) const;
  Vector operator+(const QVector2D& other) const;
  Vector operator*(qreal factor) const;

private:
  std::shared_ptr<Data> m_data;
  static std::shared_ptr<Data> m_zero_data;
};

QOOL_NS_END

#endif // QOOL_VECTOR_H
