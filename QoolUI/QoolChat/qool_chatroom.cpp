#include "qool_chatroom.h"

#include "qool_beeper.h"
#include "qool_chatroom_manager.h"
#include "qoolcommon/debug.hpp"

QOOL_NS_BEGIN

ChatRoom::ChatRoom(QObject* parent)
  : QObject { parent } {
  set_name("GLOBAL");
}

ChatRoom::~ChatRoom() {
  while (! m_beepers.isEmpty()) {
    emit wannaSignOut(m_beepers.takeFirst());
  }
}

void ChatRoom::postMessage(const Message& message) {
  emit wannaPostMessage(message);
}

void ChatRoom::postMessage(const QString& channels, Message message) {
  message << MsgChannelSet(channels);
  postMessage(message);
}

void ChatRoom::signIn(Beeper* beeper) {
  if (m_beepers.contains(beeper))
    return;
  m_beepers.append(beeper);
  emit wannaSignIn(beeper);
}

void ChatRoom::signOut(Beeper* beeper) {
  if (! m_beepers.contains(beeper))
    return;
  m_beepers.removeAll(beeper);
  emit wannaSignOut(beeper);
}

void ChatRoom::dumpInfo() const {
  xDebugQ << "Server:" << m_server->name();
  xDebugQ << "Beepers:" << xDBGList(m_beepers);
}

QString ChatRoom::name() const {
  if (m_server.isNull())
    return {};
  return m_server->name();
}

void ChatRoom::set_name(const QString& v) {
  if (name() == v)
    return;
  if (m_server)
    disconnect(m_server);
  m_server = ChatRoomManager::instance()->server(v);
  connect(this, &ChatRoom::wannaPostMessage, m_server,
    &ChatRoomServer::dispatchMessage);
  connect(this, &ChatRoom::wannaSignIn, m_server,
    &ChatRoomServer::signIn, Qt::BlockingQueuedConnection);
  connect(this, &ChatRoom::wannaSignOut, m_server,
    &ChatRoomServer::signOut, Qt::BlockingQueuedConnection);
  emit nameChanged();
}

QOOL_NS_END
