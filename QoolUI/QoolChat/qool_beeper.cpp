#include "qool_beeper.h"

#include "qool_basicbeeperapp.h"
#include "qool_chatroom.h"
#include "qool_message_event.h"
#include "qoolcommon/debug.hpp"
#include "qoolcommon/std_tools.hpp"

#include <QCoreApplication>

QOOL_NS_BEGIN

Beeper::Beeper(QObject* parent)
  : QObject { parent } {
  m_name =
    QString("BEEPER_%1").arg(tools::generate_random_string(6)).toUtf8();

  m_channels.insert(MsgChannel::ALL);
}

Beeper::~Beeper() {
  // 服务器线程经 QCoreApplication::postEvent 投递 MessageEvent——
  // 若本对象析构时事件仍在投递队列，稍后派发将解引用已析构的 this
  // （use-after-free）。removePostedEvents 清空已投递事件，关闭该
  // 窗口；此后服务器侧对已失效 Beeper 的访问由 QPointer（m_beepers
  // 为 QHash<QByteArray, QPointer<Beeper>>）跟踪自动安全跳过。
  QCoreApplication::removePostedEvents(this);
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
  if (event->type() == MessageEvent::EVENT_TYPE && m_enabled) {
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
  QMutexLocker locker(&m_channelsMutex);
  return m_channels;
}

void Beeper::set_channel(const QString& v) {
  const auto decoded = MsgChannelSet::decode(v);
  set_channels(decoded);
}

MsgChannelSet Beeper::channels() const {
  // 跨线程读（服务器线程 trySend）：锁内拷贝 QSet 结构
  QMutexLocker locker(&m_channelsMutex);
  return m_channels;
}

void Beeper::set_channels(const MsgChannelSet& channels) {
  QMutexLocker locker(&m_channelsMutex);
  if (channels == m_channels)
    return;
  m_channels = channels;
  emit channelsChanged();
}

QOOL_NS_END
