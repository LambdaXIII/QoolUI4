#include "qool_numbernotifier.h"

#include <QTimer>
#include <cmath>

QOOL_NS_BEGIN

NumberNotifier::NumberNotifier(QObject* parent)
    : QObject(parent), m_timer(new QTimer(this)) {
  // interval 默认 200ms（宏无默认值参数——构造赋值；notify 无监听者无碍）
  m_interval = 200;
  m_timer->setInterval(interval());
  connect(m_timer, &QTimer::timeout, this, &NumberNotifier::sample);
  // target/property 写入 → 重建观测（基准重置；on 语法路径不经过这两属性）
  connect(this, &NumberNotifier::targetChanged, this,
      &NumberNotifier::when_targetChanged);
  connect(this, &NumberNotifier::propertyChanged, this,
      &NumberNotifier::when_propertyChanged);
  connect(this, &NumberNotifier::intervalChanged, this,
      &NumberNotifier::when_intervalChanged);
  // 构造即启动：QML 属性赋值发生在构造后（同一事件循环内），首次采样
  // （interval 后）时观测必然已就绪；观测无效期间采样空转（见 sample）
  m_timer->start();
}

void NumberNotifier::setTarget(const QQmlProperty& property) {
  // on 语法路径：引擎在属性赋值失败时调用（文档契约——"正常赋值优先，
  // 失败才 setTarget"）。与 target/property 属性互斥使用；观测引用拷贝
  // 保存，基准重置（下次采样仅记录基准、不产生速率与事件）
  m_observed = property;
  m_hasLast = false;
}

void NumberNotifier::rebuild_observation() {
  if (target() && !property().isEmpty())
    m_observed = QQmlProperty(target(), property());
  else
    m_observed = QQmlProperty(); // 不完整——采样空转
  m_hasLast = false;
}

void NumberNotifier::when_targetChanged() {
  rebuild_observation();
}

void NumberNotifier::when_propertyChanged() {
  rebuild_observation();
}

void NumberNotifier::when_intervalChanged() {
  // 防御：interval <= 0 时 QTimer 语义异常（0 为尽可能快）——clamp 到 1ms
  m_timer->setInterval(qMax(1, interval()));
}

void NumberNotifier::sample() {
  if (!m_observed.isValid()) {
    m_hasLast = false;
    QBINDABLE_SET_VALUE(velocity, 0) // setValue 内置相等守卫（值同不 notify）
    return;
  }
  bool ok = false;
  const qreal value = m_observed.read().toReal(&ok);
  if (!ok || !std::isfinite(value)) {
    // 非有限数（属性类型不匹配/读值异常）——基准重置、速率归零；
    // 静默处理（观测器不打扰宿主，velocity 归零即是信号）
    m_hasLast = false;
    QBINDABLE_SET_VALUE(velocity, 0)
    return;
  }
  if (!m_hasLast) {
    // 首次采样 / 观测重建后：仅记录基准——velocity 保持 0、不发事件
    m_hasLast = true;
    m_lastValue = value;
    return;
  }
  const qreal old = m_lastValue;
  m_lastValue = value;
  const qreal diff = value - old;
  const qreal vel = diff / (qMax(1, interval()) / 1000.0); // 除零防御：与 when_intervalChanged 的 clamp 一致（interval<=0 时 timer 已 clamp 到 1ms）
  QBINDABLE_SET_VALUE(velocity, vel)
  // 采样检测到变化才发事件（差值非零；相等值写入在采样粒度下不可见）
  if (diff != 0)
    emit valueUpdated(value, old);
}

QOOL_NS_END
