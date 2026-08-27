#include "qool_propertyproxy.h"

#include "qoolcommon/debug.hpp"

#include <QMetaProperty>
#include <QTimer>

QOOL_NS_BEGIN

PropertyProxy::PropertyProxy(QObject* parent)
    : QObject(parent), m_timer(new QTimer(this)) {
  // interval 宏无默认值参数——构造手动设 -1（不轮询为默认）。
  QBINDABLE_SET_VALUE(interval, -1);
  connect(m_timer, &QTimer::timeout, this, &PropertyProxy::sample);
  connect(this, &PropertyProxy::targetChanged, this,
      &PropertyProxy::when_targetChanged);
  connect(this, &PropertyProxy::propertyChanged, this,
      &PropertyProxy::when_propertyChanged);
  connect(this, &PropertyProxy::intervalChanged, this,
      &PropertyProxy::when_intervalChanged);
}

bool PropertyProxy::valid_readable() const {
  // QQmlProperty 无 isReadable——能力统一经 QMetaProperty 判断。
  return m_observed.isValid() && m_observed.property().isReadable();
}

QVariant PropertyProxy::value() const {
  if (!valid_readable())
    return QVariant();
  return m_observed.read();
}

void PropertyProxy::setValue(const QVariant& new_value) {
  if (!isWritable()) {
    xWarningQ << "value not writable, write ignored"
              << "(target"
              << (target() ? target()->metaObject()->className() : "null")
              << "property" << property() << ")";
    return;
  }
  m_observed.write(new_value);
  // valueChanged 走统一路径：有 NOTIFY → 目标 notify；无 NOTIFY → 轮询检测。
}

bool PropertyProxy::isReadable() const {
  return valid_readable();
}

bool PropertyProxy::isWritable() const {
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
  if (m_notifyConnection)
    QObject::disconnect(m_notifyConnection);
  if (m_destroyedConnection)
    QObject::disconnect(m_destroyedConnection);
  m_timer->stop();
  m_hasLast = false;

  const bool complete = target() && !property().isEmpty();
  if (complete && target())
    // QQmlProperty 包裹原始对象指针，不随 target 销毁失效——监听 destroyed 主动重置。
    m_destroyedConnection = QObject::connect(
        target(), &QObject::destroyed, this, &PropertyProxy::when_targetDestroyed);
  m_observed =
    complete ? QQmlProperty(target(), property()) : QQmlProperty();
  const bool valid = valid_readable();

  if (valid) {
    m_lastValue = m_observed.read();
    m_hasLast = true;

    const QMetaProperty meta = m_observed.property();
    if (meta.hasNotifySignal()) {
      const QMetaMethod notifier = meta.notifySignal();
      const QMetaMethod slot = metaObject()->method(metaObject()->indexOfMethod(
          QMetaObject::normalizedSignature("whenTargetNotify()")));
      m_notifyConnection = QObject::connect(target(), notifier, this, slot);
    } else {
      configure_polling();
    }
  }
  emit isReadableChanged();
  emit isWritableChanged();
  emit isConstantChanged();
  emit isResettableChanged();
  emit isBindableChanged();
}

void PropertyProxy::configure_polling() {
  // 勿沿用 NumberNotifier 的 qMax(1, interval) clamp——语义不同，会退化 interval=0 分支。
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
  // destroyed 在 target 析构体内发出；notify 连接随 sender 析构自动断开。
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
