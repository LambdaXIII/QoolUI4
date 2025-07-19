#include "qool_chatroom.h"

#include "qool_beeper.h"
#include "qool_chatroom_manager.h"
#include "qoolcommon/debug.hpp"

QOOL_NS_BEGIN

ChatRoom::ChatRoom(QObject* parent)
  : QObject { parent }
  , QQmlParserStatus() {
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
  message.addChannel(channels);
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

void ChatRoom::classBegin() {
}

void ChatRoom::componentComplete() {
  if (m_server.isNull())
    set_name("GLOBAL");
  for (const auto& beeper : std::as_const(m_beepers))
    if (! beeper->chatRoom())
      emit wannaSignIn(beeper);
}

QQmlListProperty<Beeper> ChatRoom::__beepers() {
  return { this, nullptr, &ChatRoom::__append, &ChatRoom::__count,
    &ChatRoom::__at, nullptr };
}

void ChatRoom::__append(
  QQmlListProperty<Beeper>* property, Beeper* value) {
  ChatRoom* room = qobject_cast<ChatRoom*>(property->object);
  room->signIn(value);
}

qsizetype ChatRoom::__count(QQmlListProperty<Beeper>* property) {
  ChatRoom* room = qobject_cast<ChatRoom*>(property->object);
  return room->m_beepers.count();
}

Beeper* ChatRoom::__at(
  QQmlListProperty<Beeper>* property, qsizetype index) {
  ChatRoom* room = qobject_cast<ChatRoom*>(property->object);
  return room->m_beepers.at(index);
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
