#include "qool_message_event.h"

QOOL_NS_BEGIN

const int MessageEvent::EVENT_TYPE { QEvent::registerEventType() };

MessageEvent::MessageEvent()
  : QEvent(QEvent::Type(EVENT_TYPE)) {
}

QOOL_NS_END
