#ifndef QOOL_POLAR2D_H
#define QOOL_POLAR2D_H

#include "qoolns.hpp"

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
  QML_VALUE_TYPE(polar2d)
  QML_STRUCTURED_VALUE
  QML_CONSTRUCTIBLE_VALUE

public:
  Polar2D();
  Q_INVOKABLE Polar2D(const QPointF&);
  Polar2D(const QPoint&);
  Q_INVOKABLE Polar2D(const QVector2D&);
  Polar2D(qreal radius, qreal angle);

  Polar2D(const Polar2D& other);

  qreal radius() const;
  qreal angle() const;
  qreal x() const;
  qreal y() const;
  bool isCenter() const;

  Q_INVOKABLE QVector2D toVector2D() const;
  Q_INVOKABLE QPointF toPointF() const;
  Q_INVOKABLE QPoint toPoint() const;

  operator QVector2D() const;
  operator QPointF() const;
  operator QPoint() const;

  Q_INVOKABLE Polar2D withRadius(qreal r) const;
  Q_INVOKABLE Polar2D withAngle(qreal a) const;

  static Polar2D fromPos(qreal x, qreal y);
  static Polar2D fromPos(const std::pair<qreal, qreal>& xy);
  static Polar2D fromPolar(qreal r, qreal a);
  static Polar2D fromPolar(const std::pair<qreal, qreal>& polar);

private:
  struct Data: public QSharedData {
    float x { 0 };
    float y { 0 };
    float r { 0 };
    float a { 0 };
    Data()
      : QSharedData() {}
    Data(const Data& other)
      : QSharedData()
      , x(other.x)
      , y(other.y)
      , r(other.r)
      , a(other.a) {}
  };

  QSharedDataPointer<Data> m_data;

  Q_PROPERTY(qreal radius READ radius CONSTANT)
  Q_PROPERTY(qreal angle READ angle CONSTANT)
  Q_PROPERTY(qreal x READ x CONSTANT)
  Q_PROPERTY(qreal y READ y CONSTANT)
  Q_PROPERTY(bool isCenter READ isCenter CONSTANT)
  Q_PROPERTY(QVector2D vector2D READ toVector2D CONSTANT)
};

QOOL_NS_END

QVector2D operator+(const QVector2D&, const QOOL_NS::Polar2D&);
QVector2D operator-(const QVector2D&, const QOOL_NS::Polar2D&);
QPointF operator+(const QPointF&, const QOOL_NS::Polar2D&);
QPointF operator-(const QPointF&, const QOOL_NS::Polar2D&);

#endif // QOOL_POLAR2D_H
