#include "qool_chatroom_server.h"

QOOL_NS_BEGIN

ChatRoomServer::ChatRoomServer(const QString& name, QObject* parent)
  : QObject(parent)
  , m_name(name) {
}

QOOL_NS_END