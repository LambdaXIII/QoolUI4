#include "qool_propertyproxy.h"

#include "qoolcommon/debug.hpp"

#include <QMetaProperty>
#include <QTimer>

QOOL_NS_BEGIN

PropertyProxy::PropertyProxy(QObject* parent)
    : QObject(parent), m_timer(new QTimer(this)) {
  // interval 默认 -1（宏无默认值参数——构造赋值；不轮询为默认，busy polling
  // opt-in）
  m_interval = -1;
  connect(m_timer, &QTimer::timeout, this, &PropertyProxy::sample);
  // target/property 写入 → 重建观测；interval 写入 → 重配轮询
  connect(this, &PropertyProxy::targetChanged, this,
      &PropertyProxy::when_targetChanged);
  connect(this, &PropertyProxy::propertyChanged, this,
      &PropertyProxy::when_propertyChanged);
  connect(this, &PropertyProxy::intervalChanged, this,
      &PropertyProxy::when_intervalChanged);
}

bool PropertyProxy::valid_readable() const {
  // 有效且可读。能力统一从 QMetaProperty 判断（QQmlProperty 无 isReadable；
  // QMetaProperty 无效时 isReadable() 为 false，isValid 短路保底）。
  return m_observed.isValid() && m_observed.property().isReadable();
}

QVariant PropertyProxy::value() const {
  // 无状态代理：现读 target.property；无效态返回无效（QML undefined）
  if (!valid_readable())
    return QVariant();
  return m_observed.read();
}

void PropertyProxy::setValue(const QVariant& new_value) {
  // 写方向：净化可写性守卫；不过 → 忽略 + xWarningQ（显化组件名）
  if (!isWritable()) {
    xWarningQ << "value not writable, write ignored"
              << "(target"
              << (target() ? target()->metaObject()->className() : "null")
              << "property" << property() << ")";
    return;
  }
  m_observed.write(new_value);
  // valueChanged 由统一路径发出：有 NOTIFY → 事件驱动；无 NOTIFY → 轮询检测
}

bool PropertyProxy::isReadable() const {
  return valid_readable();
}

bool PropertyProxy::isWritable() const {
  // 净化可写性：元对象可写且非常量——写方向守卫单一条件
  if (!m_observed.isValid())
    return false;
  const QMetaProperty meta = m_observed.property();
  return meta.isWritable() && !meta.isConstant();
}

bool PropertyProxy::isConstant() const {
  return m_observed.isValid() && m_observed.property().isConstant();
}

bool PropertyProxy::isResettable() const {
  return m_observed.isValid() && m_observed.property().isResettable();
}

bool PropertyProxy::isBindable() const {
  return m_observed.isValid() && m_observed.property().isBindable();
}

void PropertyProxy::rebuild_observation() {
  // 断开旧 notify / destroyed 监听、停表（轮询关）、重置判变基准
  if (m_notifyConnection)
    QObject::disconnect(m_notifyConnection);
  if (m_destroyedConnection)
    QObject::disconnect(m_destroyedConnection);
  m_timer->stop();
  m_hasLast = false;

  const bool complete = target() && !property().isEmpty();
  if (complete && target())
    // 监听 target 析构 → 重置观测（防轮询/getter 解引用已释放 target——
    // QQmlProperty 包裹原始对象指针，不随 target 销毁失效）
    m_destroyedConnection = QObject::connect(
        target(), &QObject::destroyed, this, &PropertyProxy::when_targetDestroyed);
  m_observed =
    complete ? QQmlProperty(target(), property()) : QQmlProperty();
  const bool valid = valid_readable();

  if (valid) {
    // 初始同步（通用前置）：value getter 现读即终值；快照仅用于比较判变。
    // 初始同步不发 valueChanged——值"就绪"不是"变化"。
    m_lastValue = m_observed.read();
    m_hasLast = true;

    const QMetaProperty meta = m_observed.property();
    if (meta.hasNotifySignal()) {
      // 事件驱动：连 notify（不轮询——表已停）
      const QMetaMethod notifier = meta.notifySignal();
      const QMetaMethod slot = metaObject()->method(metaObject()->indexOfMethod(
          QMetaObject::normalizedSignature("whenTargetNotify()")));
      m_notifyConnection = QObject::connect(target(), notifier, this, slot);
    } else {
      configure_polling(); // 无 NOTIFY → 轮询（按 interval 三态）
    }
  }
  // 有效/无效两侧能力都可能因观测而变——统一通知刷新（QML 侧绑定更新）。
  emit isReadableChanged();
  emit isWritableChanged();
  emit isConstantChanged();
  emit isResettableChanged();
  emit isBindableChanged();
}

void PropertyProxy::configure_polling() {
  // interval 三态：<0 不轮询 / =0 零定时器（事件循环周期）/ >0 固定间隔。
  // 勿沿用 NumberNotifier 的 qMax(1, interval) clamp——语义不同，沿用会把
  // =0 分支退化。
  if (!valid_readable() || m_observed.property().hasNotifySignal()
      || interval() < 0) {
    m_timer->stop();
    return;
  }
  m_timer->setInterval(interval() == 0 ? 0 : interval());
  m_timer->start();
}

void PropertyProxy::when_targetChanged() {
  rebuild_observation();
}

void PropertyProxy::when_propertyChanged() {
  rebuild_observation();
}

void PropertyProxy::when_intervalChanged() {
  configure_polling();
}

void PropertyProxy::whenTargetNotify() {
  // 事件驱动：目标 notify 触发 → 现读 + 相等守卫 → 值实际变化才发
  if (!valid_readable())
    return;
  const QVariant current = m_observed.read();
  if (m_hasLast && current == m_lastValue)
    return; // 相等守卫
  m_lastValue = current;
  m_hasLast = true;
  emit valueChanged();
}

void PropertyProxy::when_targetDestroyed() {
  // target 析构：重置观测为无效态。destroyed 在 target 析构体内发出，此刻
  // 清空 m_observed（其持 target 原始指针，不随销毁失效）以杜绝轮询/getter
  // 解引用已释放对象；notify 连接已随 sender 析构自动断开。能力 → false。
  if (m_notifyConnection)
    QObject::disconnect(m_notifyConnection);
  m_timer->stop();
  m_observed = QQmlProperty();
  m_hasLast = false;
  m_destroyedConnection = QMetaObject::Connection();
  emit isReadableChanged();
  emit isWritableChanged();
  emit isConstantChanged();
  emit isResettableChanged();
  emit isBindableChanged();
}

void PropertyProxy::sample() {
  // 轮询采样：同相等守卫；观测无效 → 重置基准、不发
  if (!valid_readable()) {
    m_hasLast = false;
    return;
  }
  const QVariant current = m_observed.read();
  if (m_hasLast && current == m_lastValue)
    return;
  m_lastValue = current;
  m_hasLast = true;
  emit valueChanged();
}

QOOL_NS_END
