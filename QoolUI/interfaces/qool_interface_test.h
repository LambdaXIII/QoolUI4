#ifndef QOOL_INTERFACE_TEST_H
#define QOOL_INTERFACE_TEST_H

#include "qoolns.hpp"

#include <QString>
#include <QtPlugin>

QOOL_NS_BEGIN
struct TestObject {
  virtual ~TestObject() = default;
  virtual QString value() const = 0;
};
QOOL_NS_END

#define QOOL_TESTOBJECT_IID "com.qoolui.testobject.interface"
Q_DECLARE_INTERFACE(QOOL_NS::TestObject, QOOL_TESTOBJECT_IID)

#endif // QOOL_INTERFACE_TEST_H
