#include "qool_chatroom_manager.h"

#include <QMutex>
#include <QThread>

QOOL_NS_BEGIN

/*!
    \class ChatRoomManager
    \inmodule Qool.Chat
    \brief 聊天室服务器管理器（内部单例）：按 name 复用服务器并调度其生命周期。

    ChatRoomManager 以 \c qoolui::ChatRoomServer 为管理单元：
    \c server(name) 返回与 name 关联的服务器实例——同名重复调用直接
    命中缓存（复用），新名字则新建并 \c moveToThread 到专用服务器线程。

    \section1 复用缓存与定时清理（刻意设计）

    空服务器在周期窗口内保留 = 复用缓存：同一频道名重新连接时直接
    命中，无需重建。清理走 30s 周期兜底（\c purgeClosedServers），
    刻意不用 \c beeperSignedOut 即时触发——Beeper 登出是常态操作，
    立即 purge 会摧毁复用缓存并导致频繁重建；长期 idle 下最坏只是
    延迟回收，可接受。\c GLOBAL 房间永不回收（\c isEmpty 恒为 false）。

    \note 本类仅供内部使用（宿主一般不需要直接引用）：ChatRoom 赋值
    \c name 时自动经 \c instance() 获取服务器。
*/
QOOL_SIMPLE_SINGLETON_QT_IMPL(ChatRoomManager)

ChatRoomManager::ChatRoomManager()
  : QObject { nullptr }
  , m_serverThread { new QThread(this) } {
  // 定时清理（30s 周期）：purge 仅兜底回收"空且无人引用"的服务器。
  // 周期窗口内保留空服务器 = 复用缓存——同一频道名重新连接时直接
  // 命中（用户裁定：长期 idle 下最坏只是延迟回收，可接受）。
  // 刻意不用 beeperSignedOut 即时触发：Beeper 登出是常态操作，立即
  // purge 会摧毁复用缓存并导致频繁重建。
  m_purgeTimer.setInterval(30 * 1000);
  connect(&m_purgeTimer, &QTimer::timeout, this,
    &ChatRoomManager::purgeClosedServers);
  m_purgeTimer.start();

  m_serverThread->start();
}

ChatRoomManager::~ChatRoomManager() {
  m_purgeTimer.stop();
  const QStringList names = m_servers.keys();
  for (const auto& name : names)
    m_servers.take(name)->deleteLater();
  m_serverThread->wait();
  m_serverThread->deleteLater();
}

QPointer<ChatRoomServer> ChatRoomManager::server(const QString& name) {
  QPointer<ChatRoomServer> server;
  if (m_servers.contains(name) && ! m_servers[name].isNull())
    server = m_servers[name];
  else {
    QMutexLocker locker(&m_mutex);
    server = new ChatRoomServer(name);
    server->moveToThread(m_serverThread);
    m_servers[name] = server;
  }
  return server;
}

void ChatRoomManager::purgeClosedServers() {
  QMutexLocker locker(&m_mutex);
  const auto names = m_servers.keys();
  for (const auto& name : names) {
    const auto server = m_servers.value(name);
    if (server.isNull()) {
      // 已失效：移出容器后必须 continue——m_servers[name] 会重新
      // 插入空项，下一行解引用即崩溃（原实现缺陷）
      m_servers.remove(name);
      continue;
    }
    if (server->isEmpty()) {
      // 空服务器：先 take 移出容器（QPointer 随即失效）再 deleteLater
      // ——事件循环空闲时析构，容器与服务器线程中均无残留引用
      m_servers.take(name)->deleteLater();
    }
  }
}

QOOL_NS_END
