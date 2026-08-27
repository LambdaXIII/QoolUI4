#include "qool_numbernotifier.h"

#include <QTimer>
#include <cmath>

QOOL_NS_BEGIN

NumberNotifier::NumberNotifier(QObject* parent)
    : QObject(parent), m_timer(new QTimer(this)) {
  m_interval = 200;
  m_timer->setInterval(interval());
  connect(m_timer, &QTimer::timeout, this, &NumberNotifier::sample);
  connect(this, &NumberNotifier::targetChanged, this,
      &NumberNotifier::when_targetChanged);
  connect(this, &NumberNotifier::propertyChanged, this,
      &NumberNotifier::when_propertyChanged);
  connect(this, &NumberNotifier::intervalChanged, this,
      &NumberNotifier::when_intervalChanged);
  m_timer->start();
}

void NumberNotifier::setTarget(const QQmlProperty& property) {
  m_observed = property;
  m_hasLast = false;
}

void NumberNotifier::rebuild_observation() {
  if (target() && !property().isEmpty())
    m_observed = QQmlProperty(target(), property());
  else
    m_observed = QQmlProperty();
  m_hasLast = false;
}

void NumberNotifier::when_targetChanged() {
  rebuild_observation();
}

void NumberNotifier::when_propertyChanged() {
  rebuild_observation();
}

void NumberNotifier::when_intervalChanged() {
  // interval <= 0 时 QTimer 语义异常（0 为尽可能快）——clamp 到 1ms
  m_timer->setInterval(qMax(1, interval()));
}

void NumberNotifier::sample() {
  if (!m_observed.isValid()) {
    m_hasLast = false;
    QBINDABLE_SET_VALUE(velocity, 0)
    return;
  }
  bool ok = false;
  const qreal value = m_observed.read().toReal(&ok);
  if (!ok || !std::isfinite(value)) {
    // 读值异常（类型不匹配/非有限数）——基准重置、速率归零，静默处理
    m_hasLast = false;
    QBINDABLE_SET_VALUE(velocity, 0)
    return;
  }
  if (!m_hasLast) {
    // 首次采样 / 观测重建后：仅记录基准，不发事件
    m_hasLast = true;
    m_lastValue = value;
    return;
  }
  const qreal old = m_lastValue;
  m_lastValue = value;
  const qreal diff = value - old;
  const qreal vel = diff / (qMax(1, interval()) / 1000.0);
  QBINDABLE_SET_VALUE(velocity, vel)
  // 差值非零才发事件；相等值写入在采样粒度下不可见
  if (diff != 0)
    emit valueUpdated(value, old);
}

QOOL_NS_END
