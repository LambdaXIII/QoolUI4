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

void QoolSingleton::test() {
  auto plugins = PluginLoader<TestObject>::loadInstances();
  for (auto iter = plugins.constBegin(); iter != plugins.constEnd();
    ++iter) {
    xDebugQ << iter.key() << iter.value()->value();
  }
}

QOOL_NS_END
