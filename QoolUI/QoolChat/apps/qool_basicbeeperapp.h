#ifndef QOOL_BASICBEEPERAPP_H
#define QOOL_BASICBEEPERAPP_H

#include "qool_message.h"
#include "qoolns.hpp"

#include <QObject>
#include <QQmlParserStatus>

Q_MOC_INCLUDE("qool_beeper.h")

QOOL_NS_BEGIN

class Beeper;

class BasicBeeperApp: public QObject {
  Q_OBJECT
  QML_ANONYMOUS

  Q_PROPERTY(Beeper* target READ target WRITE setTarget NOTIFY
      targetChanged FINAL)
  Q_PROPERTY(QString appName READ appName CONSTANT)
  Q_PROPERTY(QByteArray appID READ appID CONSTANT)

public:
  explicit BasicBeeperApp(QObject* parent = nullptr);

  Beeper* target() const;
  void setTarget(Beeper* beeper);
  Q_SIGNAL void targetChanged();

  virtual QString appName() const;
  QByteArray appID() const;

  Q_SIGNAL void messageRecieved(Message);

protected:
  virtual void targetChange(Beeper* newTarget, Beeper* oldTarget);

private:
  QByteArray m_id;
  QPointer<Beeper> m_target;
};

QOOL_NS_END

#endif // QOOL_BASICBEEPERAPP_H
