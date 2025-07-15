#ifndef QOOL_MESSAGE_H
#define QOOL_MESSAGE_H

#include "qool_msgchannelset.h"
#include "qoolcommon/property_macros_for_qgadget.hpp"
#include "qoolns.hpp"

#include <QDateTime>
#include <QMutex>
#include <QObject>
#include <QQmlEngine>
#include <QSharedDataPointer>

QOOL_NS_BEGIN

struct MessageData: public QSharedData {
  QString content;
  QVariantMap attachments;
  MsgChannelSet channels;
  QByteArray senderID;
  QDateTime created;
  QByteArray messageID;
  MessageData();
  MessageData(const MessageData& other);
  ~MessageData() = default;
  bool operator==(const MessageData& other) const;
};

class Message;
bool operator==(const Message& a, const Message& b);
bool operator!=(const Message& a, const Message& b);

class Message {
  Q_GADGET
  QML_VALUE_TYPE(qoolmessage)
  QML_CONSTRUCTIBLE_VALUE

public:
  Message();
  Q_INVOKABLE Message(const QString& content);
  Q_INVOKABLE Message(const QVariantMap& object);
  Message(const Message& other);
  Message(Message&& other);
  Message& operator=(const Message& other);
  Message& operator=(Message&& other);

  QString channel() const;
  void set_channel(const QString& x);
  MsgChannelSet channels() const;
  void set_channels(const MsgChannelSet& x);

  Q_INVOKABLE QVariant attachment(const QString& key) const;
  Q_INVOKABLE Message& attach(
    const QString& key, const QVariant& value);

  Q_INVOKABLE Message& addChannel(const QString& channel);
  Q_INVOKABLE Message& addChannels(const MsgChannelSet& channels);
  Q_INVOKABLE Message& removeChannel(const QString& channel);
  Q_INVOKABLE Message& removeChannels(const MsgChannelSet& channels);

  friend bool operator==(const Message& a, const Message& b);

private:
  QRecursiveMutex m_mutex;
  QSharedDataPointer<MessageData> m_data;
  void __auto_insert(const QVariantMap& data);
  void __auto_insert(const QString& key, const QVariant& value);

  Q_PROPERTY(MsgChannelSet channels READ channels WRITE set_channels
      NOTIFY channelsChanged)
  Q_PROPERTY(QString channel READ channel WRITE set_channel NOTIFY
      channelsChanged)

  QOOL_PROPERTY_WRITABLE_DECL(QString, content)
  QOOL_PROPERTY_WRITABLE_DECL(QVariantMap, attachments)
  QOOL_PROPERTY_WRITABLE_DECL(QByteArray, senderID)
  QOOL_PROPERTY_CONSTANT_DECL(QDateTime, created)
  QOOL_PROPERTY_CONSTANT_DECL(QByteArray, messageID)
};

QOOL_NS_END

#endif // QOOL_MESSAGE_H
