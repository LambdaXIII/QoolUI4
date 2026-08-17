#include "qool_message.h"

#include "qoolcommon/debug.hpp"
#include "qoolcommon/std_tools.hpp"

#include <QBindable>
#include <QDateTime>
#include <QUuid>

#include <atomic>

QOOL_NS_BEGIN

#define LOCK_DATA QMutexLocker locker(&m_mutex);

QByteArray __generate_id__(const QDateTime& time) {
  static const QString t { QStringLiteral("MESSAGE_%1_%2") };
  const QString timecode =
    time.toString(QStringLiteral("yyyyMMddhhmmsszzz"));
  // 同毫秒多条消息：seed 若直接取时间戳则完全相同，而随机串是
  // 确定性的——messageID 必然碰撞。混合进程内单调计数器：同毫秒内
  // seed 随序号递增，跨毫秒由时间戳区分，保证 id 唯一。
  static std::atomic<quint64> counter { 0 };
  const quint64 seq = counter.fetch_add(1, std::memory_order_relaxed);
  const unsigned seed = static_cast<unsigned>(
    time.toMSecsSinceEpoch() + seq * 2654435761ull);
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
  // 刻意设计（勿当 bug 修）：拷贝构造生成全新的 created/messageID——
  // 拷贝得到的 Message 是"内容相同但身份不同"的新消息（身份 = 发送
  // 时间 + 消息 ID）。operator== 比较 messageID，故拷贝不相等；
  // 需要浅拷贝共享身份时请用隐式共享（QSharedDataPointer 拷贝构造
  // 走本路径——语义即"转发/再发送"）。
}

bool MessageData::operator==(const MessageData& other) const {
  return messageID == other.messageID && created == other.created
         && senderID == other.senderID && content == other.content
         && channels == other.channels
         && attachments == other.attachments;
}

bool operator==(const Message& a, const Message& b) {
  return a.m_data == b.m_data
         || *a.m_data.constData() == *b.m_data.constData();
}

bool operator!=(const Message& a, const Message& b) {
  return ! operator==(a, b);
}

Message::Message()
  : m_data { new MessageData } {
}

Message::Message(const QString& content)
  : Message() {
  m_data->content = content;
}

Message::Message(const QVariantMap& object)
  : Message() {
  __auto_insert(object);
}

Message::Message(const Message& other)
  : m_data { other.m_data } {
}

Message::Message(Message&& other)
  : m_data { std::move(other.m_data) } {
}

Message& Message::operator=(const Message& other) {
  LOCK_DATA
  m_data = other.m_data;
  return *this;
}

Message& Message::operator=(Message&& other) {
  LOCK_DATA
  m_data = std::move(other.m_data);
  return *this;
}


QString Message::channel() const {
  return m_data->channels;
}

void Message::set_channel(const QString& x) {
  const auto decoded = MsgChannelSet::decode(x);
  if (decoded == m_data->channels)
    return;
  LOCK_DATA
  m_data->channels = decoded;
}

MsgChannelSet Message::channels() const {
  return m_data->channels;
}

void Message::set_channels(const MsgChannelSet& x) {
  if (m_data->channels == x)
    return;
  LOCK_DATA
  m_data->channels = x;
}

bool Message::contains(const QString& key) const {
  // 契约（刻意设计）：key 为逗号分隔清单时按 AND 语义全包含判断
  // （"a,b" 要求 a 与 b 均在附件中）；空串/空集 = 通配（恒 true）。
  // 用于频道/附件过滤场景，勿按"子串包含"理解。
  return m_data->attachments.contains(key);
}

QVariant Message::attachment(const QString& key) const {
  return m_data->attachments.value(key);
}

Message& Message::attach(const QString& key, const QVariant& value) {
  if (m_data->attachments.value(key) == value)
    return *this;
  LOCK_DATA
  __auto_insert(key, value);
  return *this;
}

Message& Message::addChannel(const QString& channel) {
  const auto decoded = MsgChannelSet::decode(channel);
  return addChannels(decoded);
}

Message& Message::addChannels(const MsgChannelSet& channels) {
  LOCK_DATA
  m_data->channels.unite(channels);
  return *this;
}

Message& Message::removeChannel(const QString& channel) {
  const auto decoded = MsgChannelSet::decode(channel);
  return removeChannels(decoded);
}

Message& Message::removeChannels(const MsgChannelSet& channels) {
  LOCK_DATA
  m_data->channels.subtract(channels);
  return *this;
}

bool Message::isEmpty() const {
  return m_data->content.isEmpty() && m_data->attachments.isEmpty();
}

void Message::__auto_insert(const QVariantMap& data) {
  LOCK_DATA
  Qt::beginPropertyUpdateGroup();
  for (auto iter = data.constBegin(); iter != data.constEnd(); ++iter) {
    __auto_insert(iter.key().simplified(), iter.value());
  }
  Qt::endPropertyUpdateGroup();
}

void Message::__auto_insert(const QString& key, const QVariant& value) {
  LOCK_DATA
  if (key == "content") {
    if (value.canConvert<QString>())
      set_content(value.toString());
    return;
  }

  if (key == "channels" || key == "channel") {
    if (value.canConvert<MsgChannelSet>())
      set_channels(value.value<MsgChannelSet>());
    else if (value.canConvert<QStringList>()) {
      const QStringList codes = value.toStringList();
      MsgChannelSet _channels;
      for (const auto& code : codes)
        _channels.unite(MsgChannelSet::decode(code));
      set_channels(_channels);
    } else if (value.canConvert<QString>())
      set_channel(value.toString());
    return;
  }

  if (key == "senderID") {
    if (value.canConvert<QByteArray>())
      set_senderID(value.toByteArray());
    return;
  }

  static const QStringList CONSTANT_KEYS { "created", "messageID",
    "attachment", "attachments" };

  if (CONSTANT_KEYS.contains(key)) {
    xWarningQ << xDBGRed << key << xDBGReset "is not a valid key.";
    return;
  }

  if (value.isNull())
    m_data->attachments.remove(key);
  else
    m_data->attachments.insert(key, value);
}

QString Message::content() const {
  return m_data->content;
}
void Message::set_content(const QString& x) {
  if (m_data->content == x)
    return;
  LOCK_DATA
  m_data->content = x;
}

QVariantMap Message::attachments() const {
  return m_data->attachments;
}

void Message::set_attachments(const QVariantMap& data) {
  if (m_data->attachments == data)
    return;
  LOCK_DATA;
  m_data->attachments = data;
}

QByteArray Message::senderID() const {
  return m_data->senderID;
}

void Message::set_senderID(const QByteArray& x) {
  if (m_data->senderID == x)
    return;
  LOCK_DATA
  m_data->senderID = x;
}

QDateTime Message::created() const {
  return m_data->created;
}
QByteArray Message::messageID() const {
  return m_data->messageID;
}

#undef LOCK_DATA

QOOL_NS_END
