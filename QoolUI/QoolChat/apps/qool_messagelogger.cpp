#include "qool_messagelogger.h"

QOOL_NS_BEGIN

MessageLogger::MessageLogger(QObject* parent)
  : BasicBeeperApp(parent) {
  connect(this, SIGNAL(messageRecieved(Message)), this,
    SLOT(appendMessage(Message)));
}

QString MessageLogger::appName() const {
  return QStringLiteral("MessageLogger");
}

const QList<Message>& MessageLogger::messages() const {
  return m_messages;
}

void MessageLogger::clear() {
  if (m_messages.isEmpty())
    return;
  m_messages.clear();
  emit messagesChanged();
  emit lengthChanged();
}

void MessageLogger::appendMessage(Message message) {
  if (! m_messages.isEmpty() && m_messages.constLast() == message)
    return;
  QMutexLocker locker(&m_mutex);

  const int old_len = m_messages.length();
  bool msgsChanged = false;
  const int max = maxLength();

  if (max != 0) {
    m_messages.append(message);
    msgsChanged = true;
  }

  if (max >= 0) {
    int delta_len = m_messages.length() - m_maxLength;
    if (delta_len > 0) {
      m_messages.remove(0, delta_len);
      msgsChanged = true;
    }
  }

  bool lenChanged = m_messages.length() != old_len;

  if (lenChanged || msgsChanged)
    emit messagesChanged();
  if (lenChanged)
    emit lengthChanged();
}

int MessageLogger::length() const {
  return m_messages.length();
}

QOOL_NS_END
