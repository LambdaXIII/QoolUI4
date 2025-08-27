#ifndef QOOL_SINGLETON_H
#define QOOL_SINGLETON_H

#include "qool_extension_positions.h"
#include "qool_geoutils.h"
#include "qool_literals.h"
// #include "qool_polar2d.h"
#include "qool_smartobj.h"

#include "qoolcommon/qobject_property_macros.hpp"
#include "qoolns.hpp"
#include "qoolversion.hpp"

QOOL_LITERALS_USED

QOOL_NS_BEGIN

class QoolSingleton: public SmartObject {
  Q_OBJECT
  QML_ELEMENT
  QML_EXTENDED_NAMESPACE(QoolLiterals)

  QOBJECT_CONSTANT_PROPERTY(
    QString, version, QOOLUI_VERSION_FULL)
  QOBJECT_CONSTANT_PROPERTY(
    Extension_Positions*, positions, nullptr)
  QOBJECT_CONSTANT_PROPERTY(GeoUtils*, geo, nullptr)

public:
  explicit QoolSingleton(QObject* parent = nullptr);
  ~QoolSingleton() = default;

  // Q_INVOKABLE static Polar2D polar2d(qreal radius, qreal angle);
  // Q_INVOKABLE static Polar2D polar2d(const QVector2D& vector2d);

  Q_INVOKABLE static QList<int> intRange(
    int from, int to, bool rightEdgeIncluded = false);

  Q_INVOKABLE static qreal bound(qreal min, qreal value, qreal max);
  Q_INVOKABLE static qreal remap(qreal value, qreal sourceMin,
    qreal sourceMax, qreal targetMin = 0, qreal targetMax = 1);

  Q_INVOKABLE void test();
};

QOOL_NS_END

#endif // QOOL_SINGLETON_H
