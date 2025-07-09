#ifndef QOOL_MESSAGE_EVENT_H
#define QOOL_MESSAGE_EVENT_H

#include "qoolns.hpp"

#include <QEvent>
#include <QObject>

QOOL_NS_BEGIN

class MessageEvent: public QEvent {
public:
  static const int EVENT_TYPE;
  MessageEvent();
  ~MessageEvent() = default;
};

QOOL_NS_END
#endif // QOOL_MESSAGE_EVENT_H
