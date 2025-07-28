#ifndef QOOL_GEOUTILS_H
#define QOOL_GEOUTILS_H

#include "qoolns.hpp"

#include <QObject>
#include <QQmlEngine>

QOOL_NS_BEGIN

class GeoUtils: public QObject {
  Q_OBJECT
  QML_ANONYMOUS
public:
  explicit GeoUtils(QObject* parent = nullptr);

  Q_INVOKABLE static qreal radiansFromDegrees(qreal d);
  Q_INVOKABLE static qreal degreesFromRadians(qreal r);

  static const qreal PI;

private:
  Q_PROPERTY(qreal PI MEMBER PI CONSTANT)
};

QOOL_NS_END

#endif // QOOL_GEOUTILS_H
