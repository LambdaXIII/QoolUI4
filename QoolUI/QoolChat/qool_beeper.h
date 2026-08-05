#ifndef QOOL_BEEPER_H
#define QOOL_BEEPER_H

#include "qool_message.h"
#include "qoolcommon/qobject_property_macros.hpp"


#include <QMutex>
#include <QObject>
#include <QQmlEngine>
#include <QQmlParserStatus>

Q_MOC_INCLUDE("qool_chatroom.h")
Q_MOC_INCLUDE("qool_basicbeeperapp.h")

QOOL_NS_BEGIN
class BasicBeeperApp;
class ChatRoom;
class Beeper : public QObject {
  Q_OBJECT
  QML_ELEMENT

  Q_CLASSINFO("DefaultProperty", "apps")
  QML_LIST_PROPERTY_ASSIGN_BEHAVIOR_REPLACE_IF_NOT_DEFAULT

  Q_PROPERTY(QQmlListProperty<BasicBeeperApp> apps READ __apps CONSTANT FINAL)

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
  // 为什么需要锁：服务器线程（ChatRoomServer 工作线程）的 trySend
  // 跨线程读取 channels()（QSet 结构），与主线程 set_channels 并发写
  // 构成数据竞争（QSet 读写并发为 UB）。name 宏 getter 刻意不加锁：
  // QByteArray 的隐式共享拷贝（原子引用计数 + 单指针）在"读指针→
  // 拷贝"窗口实践中安全（Qt 隐式共享类型跨线程拷贝的通用模式）。
  mutable QMutex m_channelsMutex;
  MsgChannelSet m_channels;
  Q_PROPERTY(
      QString channel READ channel WRITE set_channel NOTIFY channelsChanged)
  Q_PROPERTY(MsgChannelSet channels READ channels WRITE set_channels NOTIFY
          channelsChanged)

  QOBJECT_WRITABLE_PROPERTY(QByteArray, name, {})
  QOBJECT_WRITABLE_PROPERTY_DECLARE(ChatRoom*, chatRoom)
  QOBJECT_WRITABLE_PROPERTY(bool, enabled, true)
};

QOOL_NS_END

#endif // QOOL_BEEPER_H
