#ifndef QOOL_MSGCHANNEL_H
#define QOOL_MSGCHANNEL_H

#include "qoolns.hpp"

#include <QAnyStringView>
#include <QQmlEngine>

QOOL_NS_BEGIN

class MsgChannel;

bool operator==(const MsgChannel& a, const MsgChannel& b);
bool operator!=(const MsgChannel& a, const MsgChannel& b);

size_t qHash(const MsgChannel& key, size_t seed) noexcept;

class MsgChannel {
  Q_GADGET
  QML_VALUE_TYPE(msgchannel)
  QML_CONSTRUCTIBLE_VALUE
public:
  MsgChannel();
  Q_INVOKABLE MsgChannel(const QByteArray& name);
  MsgChannel(const MsgChannel& other);
  MsgChannel(MsgChannel&& other);
  MsgChannel& operator=(const MsgChannel& other);
  MsgChannel& operator=(MsgChannel&& other);
  ~MsgChannel() = default;

  QString toString() const;
  QByteArray toByteArray() const;
  operator QString() const;
  operator QByteArray() const;

  friend bool operator==(const MsgChannel& a, const MsgChannel& b);
  friend bool operator!=(const MsgChannel& a, const MsgChannel& b);
  friend size_t qHash(const MsgChannel& key, size_t seed) noexcept;

  static const QByteArray EMPTY_CODE;
  static const QByteArray ALL;

private:
  static QSet<QByteArray> m_symbols;
  static QByteArray symbolify(const QByteArray& code);
  QByteArray m_data;
};

QOOL_NS_END

#endif // QOOL_MSGCHANNEL_H
