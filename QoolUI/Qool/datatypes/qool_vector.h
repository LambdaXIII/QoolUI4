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
  QVector2D normalizedVector() const;
  float x() const;
  float y() const;

  float length() const;
  float radian() const;
  float angle() const;

  operator QVector2D() const;
  operator QPointF() const;

  bool operator==(const Vector& other) const;
  bool operator!=(const Vector& other) const;

  Vector operator+(const Vector& other) const;
  Vector operator+(const QVector2D& other) const;
  Vector operator*(qreal factor) const;

  Q_INVOKABLE Vector withNewFrom(const QPointF&) const;
  Q_INVOKABLE Vector withNewTo(const QPointF&) const;
  Q_INVOKABLE Vector withNewLength(float) const;
  Q_INVOKABLE Vector withNewRadian(float) const;
  Q_INVOKABLE Vector withNewAngle(float) const;

private:
  Vector(const QVector2D& v1, const QVector2D& v2);
  std::shared_ptr<Data> m_data;
  static std::shared_ptr<Data> m_zero_data;
};

QOOL_NS_END

#endif // QOOL_VECTOR_H
