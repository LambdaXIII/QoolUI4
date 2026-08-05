#include "qool_msgchannelset.h"

#include <QRegularExpression>

QOOL_NS_BEGIN

/*!
    \qmlvaluetype msgchannelset
    \inqmlmodule Qool.Chat
    \nativetype qoolui::MsgChannelSet
    \brief 频道集合值类型：一组频道（MsgChannel）的无序集合。

    MsgChannelSet（QML 侧为 \c msgchannelset）表达一组频道，是
    \c QSet<MsgChannel> 的值类型包装，可直接使用集合运算。特殊
    频道 \c ALL 为通配：消息或 Beeper 的频道集合含 \c ALL 即命中
    全部频道（见 \l ChatRoomServer 的消息过滤）。

    \section1 构造与转换

    可由单个频道、字符串列表、字节数组列表或频道编码串构造
    （QML_CONSTRUCTIBLE_VALUE）。\c decode(code) 按空格/逗号/分号
    切分编码串还原集合；\c encode() 以分隔符连接排序后的频道列表
    （toStringList 输出为排序后的 QStringList）。

    \section1 contains 契约

    \c contains(channel) 对带分隔符的编码串按 AND 语义判断（解码后
    逐项检查，全部存在才返回 true）；对单个 \c QByteArray 频道则为
    普通集合成员判断。
*/
MsgChannelSet::MsgChannelSet()
  : QSet<MsgChannel>() {
}

MsgChannelSet::MsgChannelSet(const QList<MsgChannel>& channels)
  : MsgChannelSet() {
  for (const auto& channel : channels)
    this->insert(channel);
}

MsgChannelSet::MsgChannelSet(const QStringList& channels)
  : MsgChannelSet() {
  for (const auto& channel : channels)
    this->insert(channel.toUtf8());
}

MsgChannelSet::MsgChannelSet(const QByteArrayList& channels)
  : MsgChannelSet() {
  for (const auto& channel : channels)
    this->insert(channel);
}

MsgChannelSet::MsgChannelSet(const QString& channel) {
  const auto decoded = decode(channel);
  this->unite(decoded);
}

bool MsgChannelSet::contains(const QString& channel) const {
  const auto decoded = decode(channel);
  for (const auto& c : decoded) {
    if (! QSet<MsgChannel>::contains(c))
      return false;
  }
  return true;
}

bool MsgChannelSet::contains(const QByteArray& channel) const {
  return QSet<MsgChannel>::contains(channel);
}

QStringList MsgChannelSet::toStringList() const {
  QStringList result;
  std::transform(this->cbegin(), this->cend(),
    std::back_inserter(result),
    [&](const auto c) { return QString(c); });
  std::stable_sort(result.begin(), result.end());
  return result;
}

MsgChannelSet::operator QStringList() const {
  return toStringList();
}

Q_GLOBAL_STATIC_WITH_ARGS(
  QString, CHANNEL_SPLITERS, QStringLiteral(" ,;"));

QString MsgChannelSet::encode() const {
  const auto list = toStringList();
  return list.join(CHANNEL_SPLITERS->at(0));
}

MsgChannelSet::operator QString() const {
  return encode();
}

MsgChannelSet MsgChannelSet::decode(const QString& code) {
  static const QRegularExpression spliter_pattern(
    QStringLiteral("[%1]").arg(*CHANNEL_SPLITERS));

  QStringList channels =
    code.split(spliter_pattern, Qt::SkipEmptyParts);
  return { channels };
}

QOOL_NS_END
