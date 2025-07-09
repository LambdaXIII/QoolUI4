#ifndef QOOL_CHATROOM_SERVER_H
#define QOOL_CHATROOM_SERVER_H

#include "qoolcommon/property_macros_for_qobject.hpp"
#include "qoolns.hpp"

#include <QObject>
#include <QQmlEngine>

QOOL_NS_BEGIN

class ChatRoomServer: public QObject {
  Q_OBJECT
  QOOL_PROPERTY_CONSTANT_FOR_QOBJECT(QString, name, "");

public:
  explicit ChatRoomServer(
    const QString& name, QObject* parent = nullptr);
};

QOOL_NS_END
#endif // QOOL_CHATROOM_SERVER_H