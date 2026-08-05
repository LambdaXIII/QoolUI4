#include "qool_basicbeeperapp.h"

#include "qool_beeper.h"
#include "qoolcommon/debug.hpp"
#include "qoolcommon/std_tools.hpp"

QOOL_NS_BEGIN

/*!
    \class BasicBeeperApp
    \inmodule Qool.Chat
    \brief Beeper 应用基类：安装在 Beeper 上、订阅其消息的应用外壳。

    BasicBeeperApp 是"装在 Beeper 上的应用"的基类：经 \l Beeper 的
    \c apps 默认属性安装（target 自动指向宿主 Beeper）后，Beeper
    收到的消息被转发为 \c messageRecieved 信号。子类（如
    \l MessageLogger）重写 \c appName 并提供业务逻辑。

    \section1 target 安装/卸载（刻意设计）

    \c target 指向所安装的 Beeper。换绑时 targetChange 只断开
    oldTarget → 本对象的连接——刻意不用单参数 \c disconnect(oldTarget)
    （那会断开 oldTarget 的全部出站连接，破坏 Beeper 的消息投递链）。
    卸载日志刻意引用 oldTarget（newTarget 可能为 null，解引用即
    崩溃）。

    \section1 appID

    \c appID 由 \c appName + '_' + 构造时生成的随机串组成，每个实例
    唯一；\c appName 由子类重写（基类自身返回 "BasicBeeperApp"）。

    \note QML_ANONYMOUS：不可在 QML 中直接实例化，仅作为派生类型
    的基类存在。
*/
BasicBeeperApp::BasicBeeperApp(QObject* parent)
  : QObject { parent } // , QQmlParserStatus()
{
  m_id = QByteArray::fromStdString(tools::generate_random_string(6));
}

Beeper* BasicBeeperApp::target() const {
  return m_target;
}

void BasicBeeperApp::setTarget(Beeper* beeper) {
  if (m_target == beeper)
    return;
  targetChange(beeper, m_target);
  m_target = beeper;
  emit targetChanged();
}

QString BasicBeeperApp::appName() const {
  return QStringLiteral("BasicBeeperApp");
}

QByteArray BasicBeeperApp::appID() const {
  QByteArray result;
  result.append(appName().toUtf8());
  result.append(u'_');
  result.append(m_id);
  return result;
}

void BasicBeeperApp::targetChange(
  Beeper* newTarget, Beeper* oldTarget) {
  if (oldTarget) {
    // 只断开 oldTarget→this 的连接：单参数 disconnect(oldTarget) 会
    // 断开 oldTarget 的全部出站连接（如 Beeper→ChatRoomServer 的
    // 消息投递链），破坏 Beeper 功能。
    disconnect(oldTarget, nullptr, this, nullptr);
    // 日志必须引用 oldTarget（正被卸载的目标）：此处 newTarget 可能
    // 为 null（换到无目标），newTarget->name() 是空指针解引用
    xInfoQ << xDBGRed << appID()
           << xDBGReset "uninstalled from" xDBGYellow << oldTarget
           << oldTarget->name() << xDBGReset;
  }
  if (newTarget) {
    connect(newTarget, SIGNAL(messageRecieved(Message)), this,
      SIGNAL(messageRecieved(Message)));
    xInfoQ << xDBGGreen << appID()
           << xDBGReset "installed to" xDBGYellow << newTarget
           << newTarget->name() << xDBGReset;
  }
}

QOOL_NS_END
