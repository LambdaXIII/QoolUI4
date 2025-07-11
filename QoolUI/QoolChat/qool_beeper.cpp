#include "qool_beeper.h"

#include "qool_chatroom.h"
#include "qool_message_event.h"
#include "qoolcommon/debug.hpp"
#include "qoolcommon/std_tools.hpp"

QOOL_NS_BEGIN

Beeper::Beeper(QObject* parent)
  : QObject { parent } {
  m_name =
    QString("BEEPER#%1").arg(tools::generate_random_string(6)).toUtf8();

  connect(
    this, SIGNAL(channelsChanged()), this, SIGNAL(channelChanged()));
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
