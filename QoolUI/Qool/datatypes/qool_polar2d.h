#ifndef QOOL_POLAR2D_H
#define QOOL_POLAR2D_H

#include "qoolns.hpp"

#include "qoolcommon/compare_delegate.hpp"
#include "qoolcommon/qgadget_property_macros.hpp"
#include <QObject>
#include <QPoint>
#include <QPointF>
#include <QQmlEngine>
#include <QSharedData>
#include <QSharedDataPointer>
#include <QVector2D>

QOOL_NS_BEGIN

class Polar2D {
  Q_GADGET
  QML_VALUE_TYPE(qoolpolar)
  QML_STRUCTURED_VALUE

public:
  Polar2D() = default;
  Q_INVOKABLE Polar2D(const QVector2D& vec);
  Polar2D(const QPointF& from, const QPointF& to);
  Polar2D(qreal radius, qreal radians);

  Polar2D(const Polar2D& other);
  Polar2D(Polar2D&& other);

  Polar2D& operator=(const Polar2D& other);
  Polar2D& operator=(Polar2D&& other);

  operator QVector2D() const;
  operator QPointF() const;

  Q_INVOKABLE bool isZero() const;
  Q_INVOKABLE Polar2D normalized() const;

  QGADGET_CONSTANT_PROPERTY(qreal, radius, 0)
  QGADGET_CONSTANT_PROPERTY(qreal, radians, 0)
  QGADGET_CONSTANT_PROPERTY_DECLARE(qreal, degrees)
  QGADGET_CONSTANT_PROPERTY_DECLARE(QVector2D, vector)
};

QOOL_EQUAL_COMPARE_DECL(Polar2D)

Polar2D operator-(const Polar2D&);

Polar2D operator+(const Polar2D&, const Polar2D&);
Polar2D operator-(const Polar2D&, const Polar2D&);
Polar2D operator+(const Polar2D&, const QVector2D&);
Polar2D operator-(const Polar2D&, const QVector2D&);
Polar2D operator*(const Polar2D&, qreal);
Polar2D operator/(const Polar2D&, qreal);

QOOL_NS_END

#endif // QOOL_POLAR2D_H
