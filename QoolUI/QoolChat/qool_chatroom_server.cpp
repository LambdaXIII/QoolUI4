#include "qool_chatroom_server.h"

#include "qool_beeper.h"
#include "qool_message_event.h"
#include "qoolcommon/debug.hpp"

#include <QCoreApplication>

QOOL_NS_BEGIN

ChatRoomServer::ChatRoomServer(const QString& name, QObject* parent)
  : QObject(parent)
  , m_name(name) {
  xInfoQ << "ChatRoom Server" << xDBGYellow << m_name << xDBGReset
         << "initialized.";
}

ChatRoomServer::~ChatRoomServer() {
  if (! m_objectTracker.isEmpty())
    xWarningQ << xDBGRed << "Beepers are still connected while charroom"
              << xDBGYellow << m_name << xDBGRed << "is deconstructing."
              << xDBGReset;
  xInfoQ << "Server" xDBGYellow << m_name << xDBGReset "closed.";
}

void ChatRoomServer::signIn(Beeper* beeper) {
  if (beeper == nullptr)
    return;
  if (m_beepers.contains(beeper->name())) {
    xWarningQ << "Beeper" << xDBGRed << beeper << xDBGReset
              << "already signed in. Check if you have beepers with "
                 "conflict names with:"
              << xDBGRed << beeper->name() << xDBGReset;
    return;
  }
  QMutexLocker locker(&m_mutex);
  m_objectTracker.add(beeper);
  m_beepers.insert(beeper->name(), beeper);
  xInfoQ << "Beeper" << xDBGGreen << beeper->name() << xDBGReset
         << "joined chat room" << xDBGYellow << m_name << xDBGReset;
  emit beeperSignedIn(beeper);
}

void ChatRoomServer::signOut(Beeper* beeper) {
  if (beeper == nullptr)
    return;
  QMutexLocker locker(&m_mutex);
  m_objectTracker.remove(beeper);
  m_beepers.remove(beeper->name());
  xInfoQ << "Beeper" << xDBGRed << beeper->name() << xDBGReset
         << "left chat room" << xDBGYellow << m_name << xDBGReset;
  emit beeperSignedOut(beeper);
}

void ChatRoomServer::dispatchMessage(const Message& msg) const {
  const QList<QPointer<Beeper>> beepers = m_beepers.values();
  for (const auto& beeper : beepers)
    trySend(msg, beeper);
}

bool ChatRoomServer::isEmpty() const {
  if (m_name == "GLOBAL")
    return false;
  return m_beepers.isEmpty() || m_objectTracker.isEmpty();
}

void ChatRoomServer::trySend(
  const Message& msg, QPointer<Beeper> beeper) {
  if (beeper.isNull())
    return;
  if (beeper->name() == msg.senderID())
    return;
  const auto msgChannels = msg.channels();
  const auto beeperChannels = beeper->channels();
  static const MsgChannel ALLCHANNEL { MsgChannel::ALL };
  if (msgChannels.contains(ALLCHANNEL)
      || beeperChannels.contains(ALLCHANNEL)
      || msgChannels.intersects(beeper->channels())) {
    MessageEvent* e = new MessageEvent(msg);
    QCoreApplication::instance()->postEvent(beeper, e);
  }
}

QOOL_NS_END
