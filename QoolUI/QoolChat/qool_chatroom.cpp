#include "qool_chatroom.h"

#include "qool_beeper.h"
#include "qool_chatroom_manager.h"
#include "qoolcommon/debug.hpp"

QOOL_NS_BEGIN

/*!
    \qmltype ChatRoom
    \inqmlmodule Qool.Chat
    \nativetype qoolui::ChatRoom
    \brief 聊天室：Beeper 的注册容器与消息分发入口。

    ChatRoom 把一组 \l Beeper 组织到同一频道空间：QML 子元素声明
    即自动注册（默认属性 \c beepers），注册/注销经 ChatRoomManager
    转发到该房间对应的服务器线程。

    \section1 name 与服务器连接

    \c name 是房间的服务器频道名。赋值 \c name 即建立到
    \c ChatRoomManager::server(name) 的连接（复用同名服务器缓存，
    服务器实例常驻专用线程）；未设置时 \c componentComplete 默认补为
    \c "GLOBAL"。服务器连接建立后统一补发已注册 Beeper 的注册信号
    （见下"注册时机"）。

    \section1 beepers 默认属性与注册时机（刻意设计）

    \c beepers 是默认属性（DefaultProperty），QML 子元素声明即自动
    注册（signIn）。注册刻意延迟到"组件完成、属性就绪"节点：QML
    属性求值顺序下，Beeper 的 \c chatRoom 赋值可能先于 \c name 执行，
    其注册信号会在服务器连接建立前发射而丢失；服务器连接建立后按
    name 幂等补发（已注册者被忽略），正常声明顺序（name 在前）下
    零开销。另注：服务器投递时实时读取 Beeper 频道（trySend →
    beeper->channels()），注册时机不影响频道正确性。

    \section1 消息发送

    单参 \c postMessage(message) 使用消息自带频道；双参
    \c postMessage(channels, message) 把 \c channels 附加到消息后
    投递，供"发往指定频道"的便利用法——两者并存，不是冗余。

    \note ChatRoom 是 QML 注册实体（QML_ELEMENT）；C++ 侧如需直接
    获取服务器请经 \c ChatRoomManager::instance()->server(name)。
*/
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
