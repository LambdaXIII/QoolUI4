#include "qool_beeper.h"

#include "qool_basicbeeperapp.h"
#include "qool_chatroom.h"
#include "qool_message_event.h"
#include "qoolcommon/debug.hpp"
#include "qoolcommon/std_tools.hpp"

QOOL_NS_BEGIN

Beeper::Beeper(QObject* parent)
  : QObject { parent } {
  m_name =
    QString("BEEPER_%1").arg(tools::generate_random_string(6)).toUtf8();

  m_channels = MsgChannelSet::all();

  connect(
    this, SIGNAL(channelsChanged()), this, SIGNAL(channelChanged()));
}

Beeper::~Beeper() {
  if (chatRoom())
    chatRoom()->signOut(this);
}

void Beeper::postMessage(Message message) {
  message.setSenderID(name());
  message << m_channels;
  if (! chatRoom()) {
    xWarningQ
      << "Beeper" << xDBGYellow << name() << xDBGReset
      << "does not connected to a server, message cannot be posted.";
    return;
  }
  chatRoom()->postMessage(message);
}

void Beeper::postMessage(const QString& channels, Message message) {
  message.setSenderID(name());
  message << MsgChannelSet::decode(channels);
  if (! chatRoom()) {
    xWarningQ
      << "Beeper" << xDBGYellow << name() << xDBGReset
      << "does not connected to a server, message cannot be posted.";
    return;
  }
  chatRoom()->postMessage(message);
}

void Beeper::customEvent(QEvent* event) {
  if (event->type() == MessageEvent::EVENT_TYPE) {
    auto e = static_cast<MessageEvent*>(event);
    emit messageRecieved(e->message());
    event->setAccepted(true);
  }
}

void __apps_append(
  QQmlListProperty<BasicBeeperApp>* property, BasicBeeperApp* app) {
  Beeper* beeper = qobject_cast<Beeper*>(property->object);
  if (app->target() == nullptr)
    app->setTarget(beeper);
}

QQmlListProperty<BasicBeeperApp> Beeper::__apps() {
  return { this, nullptr, &__apps_append, nullptr, nullptr, nullptr };
}

ChatRoom* Beeper::chatRoom() const {
  return m_chatRoom;
}

void Beeper::set_chatRoom(ChatRoom* room) {
  if (room == m_chatRoom)
    return;
  if (m_chatRoom)
    m_chatRoom->signOut(this);
  m_chatRoom = QPointer(room);
  if (m_chatRoom)
    m_chatRoom->signIn(this);
  emit chatRoomChanged();
}

QString Beeper::channel() const {
  return channels().encode();
}

void Beeper::set_channel(const QString& v) {
  MsgChannelSet x = MsgChannelSet::decode(v);
  if (channels() == x)
    return;
  set_channels(x);
}

QOOL_NS_END
