#include "qool_beeper.h"

#include "qool_basicbeeperapp.h"
#include "qool_chatroom.h"
#include "qool_message_event.h"
#include "qoolcommon/debug.hpp"
#include "qoolcommon/std_tools.hpp"

#include <QCoreApplication>

QOOL_NS_BEGIN

/*!
    \qmltype Beeper
    \inqmlmodule Qool.Chat
    \nativetype qoolui::Beeper
    \brief 聊天室成员：订阅频道、收发消息，并承载 BeeperApp 应用。

    Beeper 是 Qool.Chat 的消息终端：构造即生成唯一 \c name 并订阅
    \c ALL 频道，加入 \l ChatRoom 后经服务器收发消息。\c apps 是
    默认属性（DefaultProperty），子元素（如 \l MessageLogger）声明即
    自动安装到本 Beeper（target 自动指向本 Beeper）。

    \section1 频道与线程安全（刻意设计）

    \c channels 属性（\c msgchannelset）决定接收哪些频道的消息；
    服务器线程的 trySend 会跨线程读取它，与主线程写入并发构成数据
    竞争（QSet 读写并发为 UB），故 getter/setter 刻意加锁（锁内拷贝
    QSet 结构）。\c name 宏 getter 刻意不加锁：QByteArray 的隐式共享
    拷贝（原子引用计数 + 单指针）在"读指针→拷贝"窗口实践中安全，
    是 Qt 隐式共享类型跨线程拷贝的通用模式。\c channel 是 \c channels
    的可解码字符串便捷形式。

    \section1 消息发送

    单参 \c postMessage(message) 使用消息自带频道；双参
    \c postMessage(channels, message) 把 \c channels 附加到消息后
    定向发送。发送前自动补 \c senderID（自身 name）与自身频道。
    未连接服务器时发送被拒绝并告警。

    \section1 接收与生命周期

    \c messageRecieved 在 Beeper 所在线程发射（服务器经 postEvent
    异步投递，本对象经 customEvent 消费；\c enabled 为 false 时忽略
    到达的消息）。析构时 \c removePostedEvents 清理挂起事件、并从
    所属 ChatRoom 注销。
*/
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
