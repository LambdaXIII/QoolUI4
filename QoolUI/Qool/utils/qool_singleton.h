#ifndef QOOL_SINGLETON_H
#define QOOL_SINGLETON_H

#include "qool_extension_positions.h"
#include "qool_geoutils.h"
#include "qool_literals.h"
#include "qool_polar2d.h"
#include "qool_smartobj.h"
#include "qool_vector.h"
// #include "qoolcommon/bindable_property_macros_for_qobject.hpp"
#include "qoolcommon/property_macros_for_qobject.hpp"
#include "qoolns.hpp"
#include "qoolversion.hpp"

QOOL_LITERALS_USED

QOOL_NS_BEGIN

class QoolSingleton: public SmartObject {
  Q_OBJECT
  QML_ELEMENT
  QML_EXTENDED_NAMESPACE(QoolLiterals)

  QOOL_PROPERTY_CONSTANT_FOR_QOBJECT(
    QString, version, QOOLUI_VERSION_FULL)
  QOOL_PROPERTY_CONSTANT_FOR_QOBJECT(
    Extension_Positions*, positions, nullptr)
  QOOL_PROPERTY_CONSTANT_FOR_QOBJECT(GeoUtils*, geo, nullptr)

public:
  explicit QoolSingleton(QObject* parent = nullptr);
  ~QoolSingleton() = default;

  Q_INVOKABLE static Vector vector(qreal xpos, qreal ypos);
  Q_INVOKABLE static Vector vector(
    qreal fromx, qreal fromy, qreal tox, qreal toy);
  Q_INVOKABLE static Vector vector(
    const QPointF& from, const QPointF to);

  Q_INVOKABLE static Polar2D polar2d(qreal radius, qreal angle);
  Q_INVOKABLE static Polar2D polar2d(const QVector2D& vector2d);

  Q_INVOKABLE static QList<int> intRange(
    int from, int to, bool rightEdgeIncluded = false);

  Q_INVOKABLE static int bound(int min, int value, int max);
  Q_INVOKABLE static double bound(double min, double value, double max);

  Q_INVOKABLE void test();
};

QOOL_NS_END

#endif // QOOL_SINGLETON_H
