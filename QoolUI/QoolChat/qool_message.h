#ifndef QOOL_MESSAGE_H
#define QOOL_MESSAGE_H

#include "qoolns.hpp"

#include <QObject>
#include <QQmlEngine>

QOOL_NS_BEGIN

class Message {
  Q_GADGET
  QML_VALUE_TYPE(qoolmessage)
  QML_STRUCTURED_VALUE
  QML_CONSTRUCTIBLE_VALUE
public:
  Message();
  Q_INVOKABLE explicit Message(const QVariantMap& obj);
  Q_INVOKABLE explicit Message(const QString& content);

  QString content() const;
  QVariantMap attachments() const;

  QByteArray senderID() const;

  QDateTime created() const;
  QByteArray messageID() const;
};

QOOL_NS_END

#endif // QOOL_MESSAGE_H
