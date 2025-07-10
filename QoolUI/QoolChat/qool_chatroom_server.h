#ifndef QOOL_CHATROOM_SERVER_H
#define QOOL_CHATROOM_SERVER_H

#include "qool_message.h"
#include "qoolcommon/property_macros_for_qobject.hpp"
#include "qoolns.hpp"

#include <QObject>
#include <QQmlEngine>

QOOL_NS_BEGIN

class Beeper;
class ChatRoomServer: public QObject {
  Q_OBJECT
  QOOL_PROPERTY_CONSTANT_FOR_QOBJECT(QString, name, "");

public:
  explicit ChatRoomServer(
    const QString& name, QObject* parent = nullptr);

  ~ChatRoomServer();

  Q_SLOT void signIn();
  Q_SLOT void signOut();

  Q_SLOT void post(const Message& msg);
};

QOOL_NS_END
#endif // QOOL_CHATROOM_SERVER_H
