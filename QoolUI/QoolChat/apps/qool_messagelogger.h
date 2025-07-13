#ifndef QOOL_MESSAGELOGGER_H
#define QOOL_MESSAGELOGGER_H

#include "qool_basicbeeperapp.h"
#include "qoolcommon/property_macros_for_qobject.hpp"
#include "qoolcommon/property_macros_for_qobject_declonly.hpp"

#include <QObject>
#include <QQmlEngine>
#include <QQmlListProperty>

QOOL_NS_BEGIN

class MessageLogger: public BasicBeeperApp {
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
  QList<Message> m_messages;
  QMutex m_mutex;

private:
  Q_PROPERTY(
    QList<Message> messages READ messages NOTIFY messagesChanged)

  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT(int, maxLength, 50)
  QOOL_PROPERTY_READONLY_FOR_QOBJECT_DECL(int, length)
};

QOOL_NS_END

#endif // QOOL_MESSAGELOGGER_H
