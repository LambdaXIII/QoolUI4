#ifndef QOOL_VECTOR2D_H
#define QOOL_VECTOR2D_H

#include "qoolcommon/compare_delegate.hpp"
#include "qoolcommon/qgadget_property_macros.hpp"
#include "qoolns.hpp"
#include <QObject>
#include <QPointF>
#include <QQmlEngine>
#include <QVector2D>

QOOL_NS_BEGIN

class Vector2D {
  Q_GADGET
  QML_VALUE_TYPE(qoolvector)
  QML_CONSTRUCTIBLE_VALUE
public:
  Vector2D() = default;
  Vector2D(const QPointF& from, const QPointF& to);
  Vector2D(const QPointF& from, const QVector2D& vector);
  Q_INVOKABLE Vector2D(const QVector2D& vector);

  static Vector2D fromVector(const QVector2D vector, const QPointF& from = {});
  static Vector2D fromWayPoints(const QList<QPointF>& wayPoints);
  static Vector2D fromVectors(const QList<QVector2D>& vectors);

  Vector2D(const Vector2D& other);
  Vector2D(Vector2D&& other);

  Vector2D& operator=(const Vector2D& other);
  Vector2D& operator=(Vector2D&& other);

  operator QPointF() const;
  operator QVector2D() const;
  operator qreal() const;

  Q_INVOKABLE bool isZero() const;
  Q_INVOKABLE QVector2D normalized() const;

  Vector2D operator+(const QVector2D& vector) const;

  Vector2D operator+(qreal extra_length) const;
  Vector2D operator-(qreal extra_length) const;
  Vector2D operator*(qreal factor) const;
  Vector2D operator/(qreal divisor) const;

  Vector2D operator-() const;

  QPointF operator[](qsizetype index) const;

  QGADGET_CONSTANT_PROPERTY(QPointF, from, QPointF(0, 0))
  QGADGET_CONSTANT_PROPERTY(QVector2D, vector, QVector2D(0, 0))
  QGADGET_CONSTANT_PROPERTY_DECLARE(QPointF, to)
  QGADGET_CONSTANT_PROPERTY_DECLARE(qreal, length)
  QGADGET_CONSTANT_PROPERTY_DECLARE(qreal, x)
  QGADGET_CONSTANT_PROPERTY_DECLARE(qreal, y)
};

QOOL_EQUAL_COMPARE_DECL(Vector2D)

qreal crossProduct(const Vector2D& a, const Vector2D b);

QOOL_NS_END

#endif // QOOL_VECTOR2D_H
