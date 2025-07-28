#include "qool_geoutils.h"

#include "qoolcommon/math.hpp"

QOOLCOMMON_MATH_MARK

QOOL_NS_BEGIN

GeoUtils::GeoUtils(QObject* parent)
  : QObject { parent } {
}

qreal GeoUtils::radiansFromDegrees(qreal d) {
  return math::radians_from_degrees(d);
}

qreal GeoUtils::degreesFromRadians(qreal r) {
  return math::degrees_from_radians(r);
}

const qreal GeoUtils::PI { M_PI };

QOOL_NS_END
