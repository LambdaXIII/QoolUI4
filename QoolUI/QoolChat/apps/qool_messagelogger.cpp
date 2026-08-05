#include "qool_messagelogger.h"

QOOL_NS_BEGIN

/*!
    \qmltype MessageLogger
    \inqmlmodule Qool.Chat
    \nativetype qoolui::MessageLogger
    \brief 消息日志应用：记录 Beeper 收到的消息并暴露为列表。

    MessageLogger 是 \l BasicBeeperApp 的默认实现：安装到 Beeper
    后，把到达的消息追加进 \c messages 列表，供 UI 展示或调试。

    \section1 单线程契约（无锁原因，刻意设计）

    消息到达路径全部在主线程（messageRecieved 经 MessageEvent 在
    主线程派发后由本类槽消费），无任何跨线程调用方，锁是死代码——
    刻意不加锁。若将来引入跨线程追加，须改为 Queued 转发至本对象
    线程，而非重新加锁。

    \section1 maxLength 语义（自洽契约）

    \c maxLength 控制保留条数：
    \list
    \li 正数：保留最近 \c maxLength 条，超出部分从头部丢弃；
    \li \c 0：不保留任何消息（追加被跳过且已有消息被清空，
        列表恒为空——刻意自洽的语义）；
    \li 负数：不限制（只追加，永不裁剪）。
    \endlist
    \c length 为当前条数（只读）。

    \section1 去重

    \c appendMessage 丢弃与末条相同的消息（\c operator== 比较含
    身份字段；拷贝产生的新身份消息不算重复）。
*/
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
