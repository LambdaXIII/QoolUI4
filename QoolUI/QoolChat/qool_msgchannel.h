#ifndef QOOL_MSGCHANNEL_H
#define QOOL_MSGCHANNEL_H

#include "qoolns.hpp"

#include <QAnyStringView>
#include <QQmlEngine>

QOOL_NS_BEGIN

class MsgChannel {
  QML_VALUE_TYPE(msgchannel)
  QML_CONSTRUCTIBLE_VALUE
public:
  Q_INVOKABLE explicit MsgChannel(QAnyStringView name);
  MsgChannel(const MsgChannel& other);
  MsgChannel(MsgChannel&& other);
  MsgChannel& operator=(const MsgChannel& other);
  MsgChannel& operator=(MsgChannel&& other);
};

QOOL_NS_END
#endif // QOOL_MSGCHANNEL_H
