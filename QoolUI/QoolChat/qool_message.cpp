#include "qool_message.h"

#include "qoolcommon/debug.hpp"
#include "qoolcommon/std_tools.hpp"

#include <QDateTime>
#include <QUuid>

QOOL_NS_BEGIN

#define LOCK_DATA QMutexLocker locker(&m_mutex);

QByteArray __generate_id__(const QDateTime& time) {
  static const QString t { QStringLiteral("Message%1%2") };
  const QString timecode =
    time.toString(QStringLiteral("yyyyMMddhhmmsszzz"));
  const unsigned seed = time.toMSecsSinceEpoch();
  const QString random =
    QString::fromStdString(tools::generate_random_string(10, seed));
  return t.arg(timecode, random).toUtf8();
}

MessageData::MessageData()
  : QSharedData()
  , created { QDateTime::currentDateTime() }
  , messageID { __generate_id__(created) } {
}

MessageData::MessageData(const MessageData& other)
  : QSharedData(other)
  , created { QDateTime::currentDateTime() }
  , messageID { __generate_id__(created) }
  , content { other.content }
  , attachments { other.attachments }
  , channels { other.channels }
  , senderID { other.senderID } {
}

bool MessageData::operator==(const MessageData& other) const {
  return messageID == other.messageID && created == other.created
         && senderID == other.senderID && content == other.content
         && channels == other.channels
         && attachments == other.attachments;
}

Message::Message()
  : m_data { new MessageData } {
}

Message::Message(const QVariantMap& obj)
  : Message() {
  check_and_insert(obj);
}

Message::Message(const QString& content)
  : Message() {
  m_data->content = content;
}

Message::Message(const QString& content, const QVariantMap& obj)
  : Message() {
  check_and_insert(obj);
  m_data->content = content;
}

Message::Message(const Message& other)
  : m_data(other.m_data) {
}

Message::Message(Message&& other)
  : m_data(std::move(other.m_data)) {
}

const QString Message::content() const {
  return m_data->content;
}

Message& Message::setContent(const QString& msg) {
  if (content() != msg) {
    LOCK_DATA
    m_data->content = msg;
  }
  return *this;
}

const QVariantMap& Message::attachments() const {
  return m_data->attachments;
}

Message& Message::setAttachments(const QVariantMap& attachments) {
  if (m_data->attachments != attachments) {
    LOCK_DATA
    m_data->attachments.clear();
    check_and_insert(attachments);
  }
  return *this;
}

bool Message::contains(const QString& key) const {
  return m_data->attachments.contains(key);
}

QVariant Message::attachment(
  const QString& key, const QVariant& defvalue) const {
  return m_data->attachments.value(key, defvalue);
}

Message& Message::attach(const QString& key, const QVariant& value) {
  check_and_insert(key, value);
  return *this;
}

Message& Message::attach(const QVariantMap& attachments) {
  check_and_insert(attachments);
  return *this;
}

const QByteArray& Message::senderID() const {
  return m_data->senderID;
}

Message& Message::setSenderID(QByteArrayView id) {
  if (senderID() != id) {
    LOCK_DATA
    m_data->senderID = id.toByteArray();
  }
  return *this;
}

const MsgChannelSet& Message::channels() const {
  return m_data->channels;
}

QString Message::channelCode() const {
  return m_data->channels.encode();
}

Message& Message::setChannels(const MsgChannelSet& channels) {
  if (this->channels() != channels) {
    LOCK_DATA
    m_data->channels = channels;
  }
  return *this;
}

Message& Message::setChannelCode(const QString& code) {
  if (this->channelCode() != code) {
    LOCK_DATA
    m_data->channels = MsgChannelSet::decode(code);
  }
  return *this;
}

Message& Message::addChannel(const MsgChannel& channel) {
  LOCK_DATA
  m_data->channels.insert(channel);
  return *this;
}

Message& Message::addChannels(const MsgChannelSet& channels) {
  LOCK_DATA
  m_data->channels.unite(channels);
  return *this;
}

Message& Message::addChannels(const QString& code) {
  LOCK_DATA
  m_data->channels.unite(MsgChannelSet::decode(code));
  return *this;
}

Message& Message::removeChannel(const MsgChannel& channel) {
  LOCK_DATA
  m_data->channels.remove(channel);
  return *this;
}

Message& Message::removeChannels(const MsgChannelSet& channels) {
  LOCK_DATA
  m_data->channels.subtract(channels);
  return *this;
}

Message& Message::removeChannels(const QString& code) {
  LOCK_DATA
  m_data->channels.subtract(MsgChannelSet::decode(code));
  return *this;
}

Message& Message::operator<<(const MsgChannel& channel) {
  LOCK_DATA
  m_data->channels.insert(channel);
  return *this;
}

Message& Message::operator<<(const MsgChannelSet& channels) {
  LOCK_DATA
  m_data->channels.unite(channels);
  return *this;
}

Message& Message::operator<<(const QVariantMap& attachments) {
  check_and_insert(attachments);
  return *this;
}

void Message::check_and_insert(
  const QString& key, const QVariant& value) {
  if (key.isEmpty()) {
    xWarningQ << "Empty key is not acceptable. Ignored.";
    return;
  }

  if (key == "created" || key == "messageID") {
    xWarningQ << "Keys equal to constant properties are not "
                 "acceptable. Ignored.";
    return;
  }

  LOCK_DATA

  if (key == "content") {
    m_data->content = value.toString();
    return;
  }

  if (key == "channels" || key == "channel") {
    if (value.typeId() == QMetaType::QStringList)
      m_data->channels = MsgChannelSet(value.toStringList());
    else if (value.typeId() == QMetaType::QByteArrayList)
      m_data->channels = MsgChannelSet(value.value<QByteArrayList>());
    else if (value.typeId() == QMetaType::QString)
      m_data->channels = MsgChannelSet::decode(value.toString());
    else if (value.typeId() == QMetaType::QByteArray)
      m_data->channels = MsgChannelSet(value.toByteArray());
    else if (value.canConvert<MsgChannelSet>())
      m_data->channels = value.value<MsgChannelSet>();
    else if (value.canConvert<MsgChannel>())
      m_data->channels.insert(value.value<MsgChannel>());
    else
      xWarningQ
        << xDBGRed
        << "\"channels\" property cannot be set, check its type."
        << xDBGReset << "Currently its typeID is" << xDBGYellow
        << value.typeId() << xDBGReset;
    return;
  }

  if (key == "senderID") {
    if (value.typeId() == QMetaType::QByteArray)
      m_data->senderID = value.toByteArray();
    else if (value.typeId() == QMetaType::QString)
      m_data->senderID = value.toString().toUtf8();
    else
      xWarningQ
        << xDBGRed
        << "\"senderID\" property cannot be set, check its type."
        << xDBGReset << "Currently its typeID is" << xDBGYellow
        << value.typeId() << xDBGReset;
    return;
  }

  if (value.isNull())
    m_data->attachments.remove(key);
  else
    m_data->attachments.insert(key, value);
}

void Message::check_and_insert(const QVariantMap& values) {
  LOCK_DATA
  for (auto iter = values.constBegin(); iter != values.constEnd();
    ++iter) {
    check_and_insert(iter.key(), iter.value());
  }
}

bool operator==(const Message& a, const Message& b) {
  return a.m_data == b.m_data
         || a.m_data.constData() == b.m_data.constData();
}

bool operator!=(const Message& a, const Message& b) {
  return ! operator==(a, b);
}

#undef LOCK_DATA

QOOL_NS_END
