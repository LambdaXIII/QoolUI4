#include "qool_msgchannel.h"

#include <QMutex>
#include <QRegularExpression>
#include <utility>

QOOL_NS_BEGIN

const QByteArray MsgChannel::EMPTY_CODE { QByteArrayLiteral(
  "__EMPTY__") };
const QByteArray MsgChannel::ALL { QByteArrayLiteral("__ALL__") };

MsgChannel::MsgChannel() {
  m_data = symbolify(EMPTY_CODE);
}

MsgChannel::MsgChannel(QAnyStringView name) {
  m_data = symbolify(name.toString().toUtf8());
}

MsgChannel::MsgChannel(const MsgChannel& other)
  : m_data { other.m_data } {
}

MsgChannel::MsgChannel(MsgChannel&& other)
  : m_data { std::move(other) } {
}

MsgChannel& MsgChannel::operator=(const MsgChannel& other) {
  m_data = other.m_data;
  return *this;
}

MsgChannel& MsgChannel::operator=(MsgChannel&& other) {
  m_data = std::move(other.m_data);
  return *this;
}

QString MsgChannel::toString() const {
  return QString::fromUtf8(m_data);
}

QByteArray MsgChannel::toByteArray() const {
  return m_data;
}

MsgChannel::operator QString() const {
  return toString();
}

MsgChannel::operator QByteArray() const {
  return m_data;
}

QSet<QByteArray> MsgChannel::m_symbols { ALL, EMPTY_CODE };

QByteArray MsgChannel::symbolify(QByteArrayView code) {
  static QMutex mutex;
  const auto symbol = code.toByteArray();
  if (! m_symbols.contains(symbol)) {
    QMutexLocker locker(&mutex);
    if (! m_symbols.contains(symbol))
      m_symbols << symbol;
  }
  return *(m_symbols.find(symbol));
}

bool operator==(const MsgChannel& a, const MsgChannel& b) {
  return a.m_data == b.m_data;
}

bool operator!=(const MsgChannel& a, const MsgChannel& b) {
  return ! operator==(a, b);
}

size_t qHash(const MsgChannel& key, size_t seed) noexcept {
  return qHashMulti(seed, "msgchannel", key.m_data);
}

MsgChannelSet::MsgChannelSet()
  : QSet<MsgChannel>() {
}

MsgChannelSet::MsgChannelSet(const QStringList& codes) {
  for (const auto& x : codes)
    insert(MsgChannel(x));
}

MsgChannelSet::MsgChannelSet(const QList<QByteArray>& codes) {
  for (const auto& x : codes)
    insert(MsgChannel(x));
}

MsgChannelSet::MsgChannelSet(
  std::initializer_list<QAnyStringView> codes) {
  for (const auto& x : codes)
    insert(MsgChannel(x));
}

MsgChannelSet::MsgChannelSet(const QSet<QString>& codes) {
  for (const auto& x : codes)
    insert(MsgChannel(x));
}

MsgChannelSet::MsgChannelSet(const QSet<QByteArray>& codes) {
  for (const auto& x : codes)
    insert(MsgChannel(x));
}

MsgChannelSet::operator QStringList() const {
  return { this->constBegin(), this->constEnd() };
}

MsgChannelSet::operator QList<QByteArray>() const {
  return { this->constBegin(), this->constEnd() };
}

QString MsgChannelSet::encode() const {
  return QStringList(*this).join(m_splitChars[0]);
}

MsgChannelSet MsgChannelSet::decode(QAnyStringView string) {
  static const QRegularExpression splitRegex { QString("[%1]").arg(
    m_splitChars) };
  const QStringList symbols =
    string.toString().split(splitRegex, Qt::SkipEmptyParts);
  return MsgChannelSet(symbols);
}

const QString MsgChannelSet::m_splitChars { QStringLiteral(" ,;") };

QOOL_NS_END
