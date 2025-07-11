#ifndef QOOL_CHATROOM_H
#define QOOL_CHATROOM_H

#include "qool_message.h"
#include "qoolcommon/property_macros_for_qobject_declonly.hpp"
#include "qoolns.hpp"

#include <QObject>
#include <QQmlEngine>

Q_MOC_INCLUDE("qool_beeper.h");
Q_MOC_INCLUDE("qool_chatroom_server.h")

QOOL_NS_BEGIN
class Beeper;
class ChatRoomServer;
class ChatRoom: public QObject {
  Q_OBJECT
  QML_ELEMENT
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_DECL(QString, name)

public:
  explicit ChatRoom(QObject* parent = nullptr);

  Q_INVOKABLE void postMessage(const Message& message);
  Q_INVOKABLE void postMessage(
    const QString& channels, Message message);

  void signIn(Beeper* beeper);
  void signOut(Beeper* beeper);

protected:
  QPointer<ChatRoomServer> m_server;
  QList<QPointer<Beeper>> m_beepers;

  void connectToServer(QPointer<ChatRoomServer> server);

  Q_SIGNAL void wannaSignIn(QPointer<Beeper> beeper);
  Q_SIGNAL
  void wannaSignOut(QPointer<Beeper> beeper);
  Q_SIGNAL void wannaPostMessage(Message msg);
};

QOOL_NS_END

#endif // QOOL_CHATROOM_H
