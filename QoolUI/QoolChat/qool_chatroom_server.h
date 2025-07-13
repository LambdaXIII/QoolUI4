#ifndef QOOL_CHATROOM_SERVER_H
#define QOOL_CHATROOM_SERVER_H

#include "qool_message.h"
#include "qoolcommon/property_macros_for_qobject.hpp"
#include "qoolns.hpp"

#include <QObject>
#include <QObjectCleanupHandler>
#include <QPointer>
#include <QQmlEngine>

Q_MOC_INCLUDE("qool_beeper.h");

QOOL_NS_BEGIN

class Beeper;
class ChatRoomServer: public QObject {
  Q_OBJECT
  QOOL_PROPERTY_CONSTANT_FOR_QOBJECT(QString, name, "");

public:
  explicit ChatRoomServer(
    const QString& name, QObject* parent = nullptr);

  ~ChatRoomServer();

  void signIn(Beeper* beeper);
  void signOut(Beeper* beeper);

  void dispatchMessage(const Message& msg) const;

  Q_SIGNAL void beeperSignedOut(QPointer<Beeper> beeper);
  Q_SIGNAL void beeperSignedIn(QPointer<Beeper> beeper);

  bool isEmpty() const;

protected:
  QMutex m_mutex;
  QObjectCleanupHandler m_objectTracker;
  QHash<QByteArray, QPointer<Beeper>> m_beepers;

  static void trySend(const Message& msg, QPointer<Beeper> beeper);

  // void customEvent(QEvent* event) override;
};

QOOL_NS_END
#endif // QOOL_CHATROOM_SERVER_H
