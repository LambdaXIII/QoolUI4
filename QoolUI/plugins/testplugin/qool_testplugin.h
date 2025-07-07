#ifndef QOOL_TESTPLUGIN_H
#define QOOL_TESTPLUGIN_H

#include "qool_interface_test.h"
#include "qoolns.hpp"

#include <QObject>

QOOL_NS_BEGIN

class TestPlugin
  : public QObject
  , public TestObject {
  Q_OBJECT
  Q_PLUGIN_METADATA(IID QOOL_TESTOBJECT_IID FILE "qool_testplugin.json")
  Q_INTERFACES(QOOL_NS::TestObject)
public:
  explicit TestPlugin(QObject* parent = nullptr);

  QString value() const override;
};

QOOL_NS_END

#endif // QOOL_TESTPLUGIN_H
