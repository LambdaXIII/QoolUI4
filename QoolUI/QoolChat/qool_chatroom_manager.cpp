#include "qool_chatroom_manager.h"

#include <QMutex>
#include <QThread>

QOOL_NS_BEGIN

QOOL_SIMPLE_SINGLETON_QT_IMPL(ChatRoomManager)

ChatRoomManager::ChatRoomManager()
  : QObject { nullptr }
  , m_serverThread { new QThread(this) } {
  connect(this, &ChatRoomManager::serverPurgingRequested, this,
    &ChatRoomManager::purgeClosedServers, Qt::QueuedConnection);

  m_serverThread->start();

  // server("GLOBAL");
}

ChatRoomManager::~ChatRoomManager() {
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
    connect(server, &ChatRoomServer::beeperSignedOut, this,
      &ChatRoomManager::serverPurgingRequested);
  }
  // emit serverPurgingRequested();
  return server;
}

void ChatRoomManager::purgeClosedServers() {
  QMutexLocker locker(&m_mutex);
  const auto names = m_servers.keys();
  for (const auto& name : names) {
    if (m_servers[name].isNull())
      m_servers.remove(name);
    if (m_servers[name]->isEmpty()) {
      m_servers.take(name)->deleteLater();
    }
  }
}

QOOL_NS_END
