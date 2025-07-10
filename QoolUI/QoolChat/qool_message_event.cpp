#include "qool_message_event.h"

QOOL_NS_BEGIN

const int MessageEvent::EVENT_TYPE { QEvent::registerEventType() };

MessageEvent::MessageEvent(const Message& message)
  : QEvent(QEvent::Type(EVENT_TYPE))
  , m_message { message } {
}

const Message& MessageEvent::message() const {
  return m_message;
}

QOOL_NS_END
