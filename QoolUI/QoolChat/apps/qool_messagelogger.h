#ifndef QOOL_MESSAGELOGGER_H
#define QOOL_MESSAGELOGGER_H

#include "qool_basicbeeperapp.h"
#include "qoolcommon/qobject_property_macros.hpp"


#include <QObject>
#include <QQmlEngine>
#include <QQmlListProperty>

QOOL_NS_BEGIN

class MessageLogger : public BasicBeeperApp {
  Q_OBJECT
  QML_ELEMENT
public:
  explicit MessageLogger(QObject* parent = nullptr);

  QString appName() const override;

  const QList<Message>& messages() const;
  Q_SIGNAL void messagesChanged();

  Q_SLOT void appendMessage(Message message);

  Q_INVOKABLE void clear();

protected:
  // 为什么不需要锁：消息到达路径全部在主线程（messageRecieved 经
  // MessageEvent 在主线程派发后由本类槽消费），无任何跨线程调用方，
  // 锁是死代码。若将来引入跨线程追加，须改为 Queued 转发至本对象
  // 线程，而非重新加锁。
  QList<Message> m_messages;

private:
  Q_PROPERTY(QList<Message> messages READ messages NOTIFY messagesChanged)

  QOBJECT_WRITABLE_PROPERTY(int, maxLength, 50)
  QOBJECT_READONLY_PROPERTY_DECLARE(int, length)
};

QOOL_NS_END

#endif // QOOL_MESSAGELOGGER_H
