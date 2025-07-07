#include "qool_testplugin.h"
QOOL_NS_BEGIN
TestPlugin::TestPlugin(QObject* parent)
  : QObject { parent }
  , TestObject() {
}

QString TestPlugin::value() const {
  return { "GOOD!!" };
}
QOOL_NS_END
