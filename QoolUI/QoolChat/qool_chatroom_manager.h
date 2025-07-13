#ifndef QOOL_CHATROOM_MANAGER_H
#define QOOL_CHATROOM_MANAGER_H

#include "qool_chatroom_server.h"
#include "qoolcommon/singleton.hpp"
#include "qoolns.hpp"

#include <QMutex>
#include <QObject>

QOOL_NS_BEGIN

class ChatRoomManager: public QObject {
  Q_OBJECT
  QOOL_SIMPLE_SINGLETON_DECL(ChatRoomManager)

public:
  ~ChatRoomManager();
  QPointer<ChatRoomServer> server(const QString& name);

protected:
  QMutex m_mutex;
  QThread* m_serverThread;
  QHash<QString, QPointer<ChatRoomServer>> m_servers;

  Q_SIGNAL void serverPurgingRequested();
  void purgeClosedServers();
};

QOOL_NS_END

#endif // QOOL_CHATROOM_MANAGER_H
