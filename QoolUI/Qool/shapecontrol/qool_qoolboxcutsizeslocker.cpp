#include "qool_qoolboxcutsizeslocker.h"

#include "qoolcommon/macro_foreach.hpp"

QOOL_NS_BEGIN

QoolBoxCutSizesLocker::QoolBoxCutSizesLocker(QObject* parent)
  : SmartObject{parent} {
  connect(this, &QoolBoxCutSizesLocker::cutSizeChanged, this,
      &QoolBoxCutSizesLocker::whenCutSizesChanged);
  connect(this, &QoolBoxCutSizesLocker::enabledChanged, this,
      &QoolBoxCutSizesLocker::whenEnabledChanged);

  // 专属插件定位：parent 为 QoolBoxSettings 时自动挂接，否则 target 为
  // null 安全空转（QML 可显式设置 target 属性）。
  set_target(qobject_cast<QoolBoxSettings*>(this->parent()));
}

void QoolBoxCutSizesLocker::whenCutSizesChanged() {
  if (! m_enabled || m_target == nullptr) return;
  unify_target();
}

void QoolBoxCutSizesLocker::whenEnabledChanged() {
  if (m_enabled) {
    // 进入锁定状态（target 已有效）→ 快照当前四角，再统一为 cutSize
    if (m_target == nullptr) return;
    snapshot_target(m_target);
    unify_target();
  } else {
    // 退出锁定状态 → 恢复本次锁定前快照，随后清空快照
    if (m_target == nullptr) return;
    restore_target(m_target);
    m_old_sizes = {0, 0, 0, 0};
  }
}

void QoolBoxCutSizesLocker::setup_target(QoolBoxSettings* settings) {
  Q_ASSERT(settings != nullptr);
  // 连接新 target 四角变化。回调用 m_target 取当前 target（不依赖
  // sender()），并带 this 上下文——teardown_target 经
  // disconnect(target, nullptr, this, nullptr) 可精确拆掉本对象连接。
#define SETUP(XX)                                                         \
  connect(settings, &QoolBoxSettings::cutSize##XX##Changed, this, [this] { \
    if (! m_enabled || m_target == nullptr) return;                       \
    set_cutSize(m_target->cutSize##XX());                                 \
  });
  QOOL_FOREACH_4(SETUP, TL, TR, BL, BR)
#undef SETUP
}

void QoolBoxCutSizesLocker::teardown_target(QoolBoxSettings* settings) {
  Q_ASSERT(settings != nullptr);
  // 仅断开旧 target 上指向本对象的连接，避免误伤其他对象连到该 target
  // 的信号。
  disconnect(settings, nullptr, this, nullptr);
}

void QoolBoxCutSizesLocker::snapshot_target(QoolBoxSettings* settings) {
  Q_ASSERT(settings != nullptr);
  // 快照四角顺序固定 TL/TR/BL/BR，与 restore_target 恢复索引一一对应。
  m_old_sizes = {settings->cutSizeTL(), settings->cutSizeTR(),
    settings->cutSizeBL(), settings->cutSizeBR()};
}

void QoolBoxCutSizesLocker::restore_target(QoolBoxSettings* settings) {
  Q_ASSERT(settings != nullptr);
  Qt::beginPropertyUpdateGroup();
  settings->set_cutSizeTL(m_old_sizes[0]);
  settings->set_cutSizeTR(m_old_sizes[1]);
  settings->set_cutSizeBL(m_old_sizes[2]);
  settings->set_cutSizeBR(m_old_sizes[3]);
  Qt::endPropertyUpdateGroup();
}

void QoolBoxCutSizesLocker::unify_target() {
  Q_ASSERT(m_target != nullptr);
  Qt::beginPropertyUpdateGroup();
#define SETUP(XX) m_target->set_cutSize##XX(m_cutSize);
  QOOL_FOREACH_4(SETUP, TL, TR, BL, BR)
#undef SETUP
  Qt::endPropertyUpdateGroup();
}

void QoolBoxCutSizesLocker::set_target(QoolBoxSettings* new_target) {
  if (new_target == m_target) return;

  if (m_target != nullptr) {
    // 先拆旧 target 连接，再恢复旧 target——恢复动作会改四角，若连接
    // 仍在，四角变化回调会反向污染本次恢复（把 cutSize 又写回旧值）。
    teardown_target(m_target);
    if (m_enabled) restore_target(m_target);
  }

  m_target = new_target;
  if (m_target != nullptr) setup_target(m_target);

  if (m_enabled && m_target != nullptr) {
    // 进入锁定状态：新 target 立即快照其当前四角，再按当前 cutSize 统一
    snapshot_target(m_target);
    unify_target();
  } else {
    m_old_sizes = {0, 0, 0, 0};
  }

  emit targetChanged();
}

QoolBoxSettings* QoolBoxCutSizesLocker::target() const { return m_target; }

QOOL_NS_END
