#ifndef QOOL_POLAR2D_H
#define QOOL_POLAR2D_H

#include "qoolcommon/qoolns.hpp"

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
  Polar2D(const QPointF&);
  Polar2D(const QPoint&);
  Polar2D(const QVector2D&);
  Polar2D(float radius, float angle);

  Polar2D(const Polar2D& other);

  float radius() const;
  float angle() const;
  float x() const;
  float y() const;
  bool isCenter() const;

  Q_INVOKABLE QVector2D toVector2D() const;
  Q_INVOKABLE QPointF toPointF() const;
  Q_INVOKABLE QPoint toPoint() const;

  operator QVector2D() const;
  operator QPointF() const;
  operator QPoint() const;

  Q_INVOKABLE Polar2D withRadius(float r) const;
  Q_INVOKABLE Polar2D withAngle(float a) const;

  static Polar2D fromPos(float x, float y);
  static Polar2D fromPos(const std::pair<float, float>& xy);
  static Polar2D fromPolar(float r, float a);
  static Polar2D fromPolar(const std::pair<float, float>& polar);

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

  Q_PROPERTY(float radius READ radius CONSTANT)
  Q_PROPERTY(float angle READ angle CONSTANT)
  Q_PROPERTY(float x READ x CONSTANT)
  Q_PROPERTY(float y READ y CONSTANT)
  Q_PROPERTY(bool isCenter READ isCenter CONSTANT)
  Q_PROPERTY(QVector2D vector2D READ toVector2D CONSTANT)
};

QOOL_NS_END

#endif // QOOL_POLAR2D_H
