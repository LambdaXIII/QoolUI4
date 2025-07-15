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

MsgChannel::MsgChannel(const QByteArray& name) {
  m_data = symbolify(name);
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

QByteArray MsgChannel::symbolify(const QByteArray& code) {
  const auto n = QString::fromUtf8(code).toLower();
  if (n == "all")
    return ALL;
  if (n.isEmpty())
    return EMPTY_CODE;

  static QMutex mutex;
  const auto symbol = code;
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

Q_GLOBAL_STATIC_WITH_ARGS(QString, SPLIT_CHARS, QStringLiteral(" ,;"));

QByteArrayList __decode_channels__(QAnyStringView str) {
  static const QRegularExpression splitRegex { QString("[%1]").arg(
    *SPLIT_CHARS) };
  const QStringList symbols =
    str.toString().split(splitRegex, Qt::SkipEmptyParts);
  QByteArrayList result;
  std::transform(symbols.cbegin(), symbols.cend(),
    std::back_inserter(result),
    [](const QString& x) { return x.toUtf8(); });
  return result;
}

QOOL_NS_END
