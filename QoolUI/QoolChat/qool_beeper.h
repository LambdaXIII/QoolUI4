#ifndef QOOL_BEEPER_H
#define QOOL_BEEPER_H

#include "qool_message.h"
#include "qool_msgchannel.h"
#include "qoolcommon/property_macros_for_qobject.hpp"
#include "qoolcommon/property_macros_for_qobject_declonly.hpp"

#include <QObject>
#include <QQmlEngine>

Q_MOC_INCLUDE("qool_chatroom.h")

QOOL_NS_BEGIN

class ChatRoom;
class Beeper: public QObject {
  Q_OBJECT
  QML_ELEMENT
public:
  explicit Beeper(QObject* parent = nullptr);
  ~Beeper();

  Q_SIGNAL void messageRecieved(Message message);

  Q_INVOKABLE void postMessage(Message message);
  Q_INVOKABLE void postMessage(const QString& channel, Message message);

protected:
  void customEvent(QEvent* event) override;
  QPointer<ChatRoom> m_chatRoom;

  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT(QByteArray, name, {})
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_DECL(ChatRoom*, chatRoom)
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT(
    MsgChannelSet, channels, { MsgChannelSet::all() })
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_DECL(QString, channel)
};

QOOL_NS_END

#endif // QOOL_BEEPER_H
