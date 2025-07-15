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

  m_channels.insert(MsgChannel::ALL);
}

Beeper::~Beeper() {
  if (chatRoom())
    chatRoom()->signOut(this);
}

void Beeper::postMessage(Message message) {
  message.set_senderID(name());
  message.addChannels(channels());

  if (! chatRoom()) {
    xWarningQ
      << "Beeper" << xDBGYellow << name() << xDBGReset
      << "does not connected to a server, message cannot be posted.";
    return;
  }
  chatRoom()->postMessage(message);
}

void Beeper::postMessage(const QString& channels, Message message) {
  message.set_senderID(name());
  message.addChannel(channels);
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
  return m_channels;
}

void Beeper::set_channel(const QString& v) {
  const auto decoded = MsgChannelSet::decode(v);
  set_channels(decoded);
}

MsgChannelSet Beeper::channels() const {
  return m_channels;
}

void Beeper::set_channels(const MsgChannelSet& channels) {
  if (channels == m_channels)
    return;
  m_channels = channels;
  emit channelsChanged();
}

QOOL_NS_END
