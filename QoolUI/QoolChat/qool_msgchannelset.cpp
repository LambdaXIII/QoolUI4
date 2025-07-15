#include "qool_msgchannelset.h"

#include <QRegularExpression>

QOOL_NS_BEGIN

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
