#ifndef QOOL_BEEPER_H
#define QOOL_BEEPER_H

#include "qool_message.h"
#include "qoolcommon/property_macros_for_qobject.hpp"
#include "qoolcommon/property_macros_for_qobject_declonly.hpp"

#include <QObject>
#include <QQmlEngine>
#include <QQmlParserStatus>

Q_MOC_INCLUDE("qool_chatroom.h")
Q_MOC_INCLUDE("qool_basicbeeperapp.h")

QOOL_NS_BEGIN
class BasicBeeperApp;
class ChatRoom;
class Beeper: public QObject {
  Q_OBJECT
  QML_ELEMENT

  Q_CLASSINFO("DefaultProperty", "apps")
  QML_LIST_PROPERTY_ASSIGN_BEHAVIOR_REPLACE_IF_NOT_DEFAULT

  Q_PROPERTY(
    QQmlListProperty<BasicBeeperApp> apps READ __apps CONSTANT FINAL)

public:
  explicit Beeper(QObject* parent = nullptr);
  ~Beeper();

  Q_SIGNAL void messageRecieved(Message message);

  Q_INVOKABLE void postMessage(Message message);
  Q_INVOKABLE void postMessage(const QString& channel, Message message);

  Q_SIGNAL void channelsChanged();
  QString channel() const;
  void set_channel(const QString& channel);
  MsgChannelSet channels() const;
  void set_channels(const MsgChannelSet& channels);

protected:
  void customEvent(QEvent* event) override;
  QPointer<ChatRoom> m_chatRoom;
  QList<BasicBeeperApp*> m_apps;
  QQmlListProperty<BasicBeeperApp> __apps();
  MsgChannelSet m_channels;
  Q_PROPERTY(QString channel READ channel WRITE set_channel NOTIFY
      channelsChanged)
  Q_PROPERTY(MsgChannelSet channels READ channels WRITE set_channels
      NOTIFY channelsChanged)

  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT(QByteArray, name, {})
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_DECL(ChatRoom*, chatRoom)
};

QOOL_NS_END

#endif // QOOL_BEEPER_H
