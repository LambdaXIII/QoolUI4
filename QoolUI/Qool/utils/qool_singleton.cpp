#include "qool_singleton.h"

#include "qool_interface_test.h"
#include "qoolcommon/debug.hpp"
#include "qoolcommon/plugin_loader.hpp"

QOOL_NS_BEGIN

QoolSingleton::QoolSingleton(QObject* parent)
  : SmartObject(parent)
  , m_positions { new Extension_Positions(this) }
  , m_geo { new GeoUtils(this) } {
}

Vector QoolSingleton::vector(qreal xpos, qreal ypos) {
  return Vector(xpos, ypos);
}

Vector QoolSingleton::vector(
  qreal fromx, qreal fromy, qreal tox, qreal toy) {
  return Vector(QPointF(fromx, fromy), QPointF(tox, toy));
}

Vector QoolSingleton::vector(const QPointF& from, const QPointF to) {
  return Vector(from, to);
}

Polar2D QoolSingleton::polar2d(qreal radius, qreal angle) {
  return Polar2D(radius, angle);
}

Polar2D QoolSingleton::polar2d(const QVector2D& vector2d) {
  return Polar2D(vector2d.toPointF());
}

void QoolSingleton::test() {
  auto plugins = PluginLoader<TestObject>::loadInstances();
  for (auto iter = plugins.constBegin(); iter != plugins.constEnd();
    ++iter) {
    xDebugQ << iter.key() << iter.value()->value();
  }
}

QOOL_NS_END
