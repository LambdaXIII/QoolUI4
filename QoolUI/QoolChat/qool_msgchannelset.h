#ifndef QOOL_MSGCHANNELSET_H
#define QOOL_MSGCHANNELSET_H

#include "qool_msgchannel.h"
#include "qoolns.hpp"

#include <QSet>

QOOL_NS_BEGIN

class MsgChannelSet: public QSet<MsgChannel> {
  Q_GADGET
  QML_VALUE_TYPE(msgchannelset)
  QML_CONSTRUCTIBLE_VALUE

public:
  MsgChannelSet();

  Q_INVOKABLE MsgChannelSet(const QList<MsgChannel>& channels);
  Q_INVOKABLE MsgChannelSet(const QStringList& channels);
  Q_INVOKABLE MsgChannelSet(const QByteArrayList& channels);
  Q_INVOKABLE MsgChannelSet(const QString& channel);

  Q_INVOKABLE bool contains(const QString& channel) const;
  Q_INVOKABLE bool contains(const QByteArray& channel) const;

  QStringList toStringList() const;
  operator QStringList() const;

  QString encode() const;
  operator QString() const;

  static MsgChannelSet decode(const QString& code);
};

QOOL_NS_END

#endif // QOOL_MSGCHANNELSET_H
