#ifndef QOOL_INTERFACE_BEEPERAPP_H
#define QOOL_INTERFACE_BEEPERAPP_H

#include "qoolns.hpp"

#include <QQmlEngine>

QOOL_NS_BEGIN

class Beeper;

struct BeeperApp {
  QML_INTERFACE
  virtual ~BeeperApp() = 0;
  virtual QString name() const = 0;
  virtual QString appID() const = 0;
  virtual Beeper* target() const = 0;
  virtual void setTarget(Beeper*) = 0;
};

QOOL_NS_END

#define QOOL_BEEPERAPP_IID "com.qoolui.beeperapp.interface"
Q_DECLARE_INTERFACE(QOOL_NS::BeeperApp, QOOL_BEEPERAPP_IID)

#endif // QOOL_INTERFACE_BEEPERAPP_H
