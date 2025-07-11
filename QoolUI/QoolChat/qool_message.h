#ifndef QOOL_MESSAGE_H
#define QOOL_MESSAGE_H

#include "qool_msgchannel.h"
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
  QML_STRUCTURED_VALUE
  QML_CONSTRUCTIBLE_VALUE

  Q_PROPERTY(QString content READ content WRITE setContent)
  Q_PROPERTY(
    QVariantMap attachments READ attachments WRITE setAttachments)
  Q_PROPERTY(MsgChannelSet channels READ channels WRITE setChannels)
  Q_PROPERTY(QString channel READ channel WRITE setChannel)
  Q_PROPERTY(QByteArray senderID READ senderID WRITE setSenderID)
  Q_PROPERTY(QDateTime created READ created CONSTANT)
  Q_PROPERTY(QByteArray messageID READ messageID CONSTANT)

public:
  Message();
  Q_INVOKABLE explicit Message(const QVariantMap& obj);
  Q_INVOKABLE explicit Message(const QString& content);
  Message(const QString& content, const QVariantMap& obj);
  Message(const Message& other);
  // Message(Message&& other);

  const QString content() const;
  Message& setContent(const QString& msg);

  const QVariantMap& attachments() const;
  Message& setAttachments(const QVariantMap& attachments);

  Q_INVOKABLE bool contains(const QString& key) const;
  Q_INVOKABLE QVariant attachment(
    const QString& key, const QVariant& defvalue = {}) const;
  Q_INVOKABLE Message& attach(
    const QString& key, const QVariant& value);
  Q_INVOKABLE Message& attach(const QVariantMap& attachments);

  const QByteArray& senderID() const;
  Message& setSenderID(QByteArrayView id);

  const MsgChannelSet& channels() const;
  QString channel() const;
  Message& setChannels(const MsgChannelSet& channels);
  Message& setChannel(const QString& code);

  Q_INVOKABLE Message& addChannel(const MsgChannel& channel);
  Q_INVOKABLE Message& addChannels(const MsgChannelSet& channels);
  Q_INVOKABLE Message& addChannels(const QString& code);
  Q_INVOKABLE Message& removeChannel(const MsgChannel& channel);
  Q_INVOKABLE Message& removeChannels(const MsgChannelSet& channels);
  Q_INVOKABLE Message& removeChannels(const QString& code);

  Message& operator<<(const MsgChannel& channel);
  Message& operator<<(const MsgChannelSet& channels);
  Message& operator<<(const QVariantMap& attachments);

  QDateTime created() const;
  QByteArray messageID() const;

  friend bool operator==(const Message& a, const Message& b);

private:
  QRecursiveMutex m_mutex;
  QSharedDataPointer<MessageData> m_data;
  void check_and_insert(const QString& key, const QVariant& value);
  void check_and_insert(const QVariantMap& values);
};

QOOL_NS_END

#endif // QOOL_MESSAGE_H
