#include "qool_basicbeeperapp.h"

#include "qool_beeper.h"
#include "qoolcommon/debug.hpp"
#include "qoolcommon/std_tools.hpp"

QOOL_NS_BEGIN

BasicBeeperApp::BasicBeeperApp(QObject* parent)
  : QObject { parent } // , QQmlParserStatus()
{
  m_id = QByteArray::fromStdString(tools::generate_random_string(6));
}

Beeper* BasicBeeperApp::target() const {
  return m_target;
}

void BasicBeeperApp::setTarget(Beeper* beeper) {
  if (m_target == beeper)
    return;
  targetChange(beeper, m_target);
  m_target = beeper;
  emit targetChanged();
}

QString BasicBeeperApp::appName() const {
  return QStringLiteral("BasicBeeperApp");
}

QByteArray BasicBeeperApp::appID() const {
  QByteArray result;
  result.append(appName().toUtf8());
  result.append(u'_');
  result.append(m_id);
  return result;
}

void BasicBeeperApp::targetChange(
  Beeper* newTarget, Beeper* oldTarget) {
  if (oldTarget) {
    disconnect(oldTarget);
    xInfoQ << xDBGRed << appID()
           << xDBGReset "uninstalled from" xDBGYellow << newTarget
           << newTarget->name() << xDBGReset;
  }
  if (newTarget) {
    connect(newTarget, SIGNAL(messageRecieved(Message)), this,
      SIGNAL(messageRecieved(Message)));
    xInfoQ << xDBGGreen << appID()
           << xDBGReset "installed to" xDBGYellow << newTarget
           << newTarget->name() << xDBGReset;
  }
}

QOOL_NS_END
