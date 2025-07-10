#ifndef QOOL_BEEPER_H
#define QOOL_BEEPER_H

#include "qool_message.h"
#include "qool_msgchannel.h"
#include "qoolcommon/property_macros_for_qobject.hpp"
#include "qoolcommon/property_macros_for_qobject_declonly.hpp"

#include <QObject>
#include <QQmlEngine>

QOOL_NS_BEGIN

class Beeper: public QObject {
  Q_OBJECT
  QML_ELEMENT
public:
  explicit Beeper(QObject* parent = nullptr);
  ~Beeper();

  Q_SIGNAL void messageRecieved(Message message);

  Q_INVOKABLE void sendMessage(const Message& message);
  Q_INVOKABLE void sendMessage(
    const QString& channels, const Message& message);

  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT(QByteArray, id, {})
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_DECL(QString, chatRoom)
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_DECL(QVariant, channels)
};

QOOL_NS_END

#endif // QOOL_BEEPER_H
