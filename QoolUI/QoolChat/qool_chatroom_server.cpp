#include "qool_chatroom_server.h"

#include "qool_beeper.h"
#include "qool_message_event.h"
#include "qoolcommon/debug.hpp"

#include <QCoreApplication>

QOOL_NS_BEGIN

/*!
    \class ChatRoomServer
    \inmodule Qool.Chat
    \brief 聊天室服务器：管理 Beeper 注册，并向频道匹配的 Beeper 投递消息。

    实例由 ChatRoomManager 按 name 创建并 \c moveToThread 到专用
    服务器线程；服务器实例仅经 \c ChatRoomManager::server(name)
    获取，"外部不可达"是隔离边界——勿在其它线程直接构造/持有
    服务器指针。

    \section1 线程架构（刻意设计，勿按常规 QObject 线程模型审查）

    \list 1
    \li ChatRoom 经 \c BlockingQueuedConnection 调用 signIn/signOut——
        调用方线程阻塞等待服务器线程完成，因此 m_beepers /
        m_objectTracker 的读写在"信号发射时"即已同步，锁内 emit
        无死锁风险（消费者均经 Queued 异步接收，不在锁内回调）。
    \li 投递路径 trySend 运行于服务器线程，跨线程读取 Beeper 的
        \c channels()（Beeper 侧已加锁，见 \l Beeper），并通过
        \c postEvent 异步投递 MessageEvent 到 Beeper 所在线程
        （Beeper 析构时 \c removePostedEvents 清理挂起事件）。
    \li 服务器实例仅经 ChatRoomManager 按 name 获取，外部不可直接
        构造/持有——"外部不可达"是隔离边界，勿在其它线程保存指针。
    \endlist

    \section1 消息过滤

    trySend 依据消息频道与 Beeper 频道集合的交集（含 \c ALL 通配）
    决定是否投递；发送者本人（senderID 与 Beeper name 相同）不接收
    自己的消息。signIn 按 Beeper name 幂等，重名注册被忽略并告警。
    \c isEmpty 表示服务器已无可投递对象（\c GLOBAL 永不视为空）。
*/
// 线程架构（刻意设计，勿按常规 QObject 线程模型审查）：
// 1. 实例被 ChatRoomManager moveToThread 到专用服务器线程；ChatRoom
//    经 BlockingQueuedConnection 调用 signIn/signOut——调用方线程
//    阻塞等待服务器线程完成，因此 m_beepers/m_objectTracker 的
//    读写在"信号发射时"即已同步，锁内 emit 无死锁风险（消费者
//    均经 Queued 异步接收，不在锁内回调）。
// 2. 投递路径 trySend 运行于服务器线程，跨线程读取 Beeper 的
//    channels()（Beeper 侧已加锁，见 qool_beeper.h）并通过
//    postEvent 异步投递到 Beeper 所在线程（Beeper 析构时
//    removePostedEvents 清理挂起事件，见 ~Beeper）。
// 3. 服务器实例仅经 ChatRoomManager 按 name 获取，外部不可直接
//    构造/持有——"外部不可达"是隔离边界，勿在其它线程保存指针。

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

  if (msgChannels.contains(MsgChannel::ALL)
      || beeperChannels.contains(MsgChannel::ALL)
      || msgChannels.intersects(beeperChannels)) {
    MessageEvent* e = new MessageEvent(msg);
    QCoreApplication::instance()->postEvent(beeper, e);
  }
}

QOOL_NS_END
