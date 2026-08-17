#include "qool_chatroom.h"

#include "qool_beeper.h"
#include "qool_chatroom_manager.h"
#include "qoolcommon/debug.hpp"

QOOL_NS_BEGIN

ChatRoom::ChatRoom(QObject* parent)
  : QObject { parent }
  , QQmlParserStatus() {
}

ChatRoom::~ChatRoom() {
  while (! m_beepers.isEmpty()) {
    emit wannaSignOut(m_beepers.takeFirst());
  }
}

void ChatRoom::postMessage(const Message& message) {
  emit wannaPostMessage(message);
}

void ChatRoom::postMessage(const QString& channels, Message message) {
  // 定向发送重载（刻意设计）：channels 参数附加到消息后投递，供
  // "发往指定频道"的便利用法；与单参 postMessage（使用消息自带频道）
  // 并存，不是冗余。
  message.addChannel(channels);
  postMessage(message);
}

void ChatRoom::signIn(Beeper* beeper) {
  if (m_beepers.contains(beeper))
    return;
  m_beepers.append(beeper);
  emit wannaSignIn(beeper);
}

void ChatRoom::signOut(Beeper* beeper) {
  if (! m_beepers.contains(beeper))
    return;
  m_beepers.removeAll(beeper);
  emit wannaSignOut(beeper);
}

void ChatRoom::dumpInfo() const {
  // m_server 在 name 未设置时为 null（QPointer），解引用即崩溃
  xDebugQ << "Server:" << (m_server ? m_server->name()
                                    : QStringLiteral("(none)"));
  xDebugQ << "Beepers:" << xDBGList(m_beepers);
}

void ChatRoom::classBegin() {
}

void ChatRoom::componentComplete() {
  if (m_server.isNull())
    set_name("GLOBAL");
  // 原补发循环（对 chatRoom() 为空的 Beeper 再发 wannaSignIn）已删除：
  // 其职责由 set_name 建立服务器连接后的统一补发承担（set_name 在本
  // 方法中被调用，补发时机仍落在"组件完成、属性就绪"的节点，符合
  // 注册延迟到组件完成的设计意图）。原条件式补发在 name 先赋值场景
  // 会对已注册 Beeper 重复补发，触发服务器 "already signed in" 警告
  // 噪音；另注：服务器投递时实时读取 Beeper 频道（trySend →
  // beeper->channels()），注册时机不影响频道正确性。
}

QQmlListProperty<Beeper> ChatRoom::__beepers() {
  return { this, nullptr, &ChatRoom::__append, &ChatRoom::__count,
    &ChatRoom::__at, nullptr };
}

void ChatRoom::__append(
  QQmlListProperty<Beeper>* property, Beeper* value) {
  ChatRoom* room = qobject_cast<ChatRoom*>(property->object);
  room->signIn(value);
}

qsizetype ChatRoom::__count(QQmlListProperty<Beeper>* property) {
  ChatRoom* room = qobject_cast<ChatRoom*>(property->object);
  return room->m_beepers.count();
}

Beeper* ChatRoom::__at(
  QQmlListProperty<Beeper>* property, qsizetype index) {
  ChatRoom* room = qobject_cast<ChatRoom*>(property->object);
  return room->m_beepers.at(index);
}

QString ChatRoom::name() const {
  if (m_server.isNull())
    return {};
  return m_server->name();
}

void ChatRoom::set_name(const QString& v) {
  if (name() == v)
    return;
  if (m_server)
    disconnect(m_server);
  m_server = ChatRoomManager::instance()->server(v);
  connect(this, &ChatRoom::wannaPostMessage, m_server,
    &ChatRoomServer::dispatchMessage);
  connect(this, &ChatRoom::wannaSignIn, m_server,
    &ChatRoomServer::signIn, Qt::BlockingQueuedConnection);
  connect(this, &ChatRoom::wannaSignOut, m_server,
    &ChatRoomServer::signOut, Qt::BlockingQueuedConnection);
  // 补发注册：QML 属性求值顺序下，Beeper 的 set_chatRoom 可能在
  // name 赋值之前执行（其 signIn 注册信号在服务器连接建立前发射而
  // 丢失）。服务器连接建立后统一补发——此时恰逢组件完成、属性就绪
  // （set_name 亦在 componentComplete 中被调用），符合"组件完成后
  // 注册"的原设计。服务器 signIn 按 name 幂等，已注册者被忽略；
  // 正常声明顺序（name 在前）下 beepers 为空，此处零开销。
  for (const auto& beeper : std::as_const(m_beepers))
    emit wannaSignIn(beeper);
  emit nameChanged();
}

QOOL_NS_END
