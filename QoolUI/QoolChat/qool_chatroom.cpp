#include "qool_chatroom.h"

#include "qool_beeper.h"
#include "qool_chatroom_manager.h"

QOOL_NS_BEGIN

ChatRoom::ChatRoom(QObject* parent)
  : QObject { parent } {
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
  connect(
    this, &ChatRoom::wannaSignIn, m_server, &ChatRoomServer::signIn);
  connect(
    this, &ChatRoom::wannaSignOut, m_server, &ChatRoomServer::signOut);
  emit nameChanged();
}

QOOL_NS_END
