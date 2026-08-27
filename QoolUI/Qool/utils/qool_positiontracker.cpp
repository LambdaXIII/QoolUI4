#include "qool_positiontracker.h"

#include <QTimer>
#include <utility>

QOOL_NS_BEGIN

PositionTracker::PositionTracker(QObject* parent)
  : QObject { parent } {
  // target 缺省 = 构造时父快照；setValue 先于 connect，不触发重复重建
  m_target.setValue(qobject_cast<QQuickItem*>(parent));
  connect(this, &PositionTracker::targetChanged, this,
    &PositionTracker::when_targetChanged);
  connect(this, &PositionTracker::pointChanged, this,
    &PositionTracker::when_pointChanged);
  rebuild_chain();
  when_geometryChanged();
}

void PositionTracker::when_geometryChanged() {
  if (m_flushScheduled)
    return;
  m_dirty = true;
  m_flushScheduled = true;
  QTimer::singleShot(0, this, &PositionTracker::flush);
}

void PositionTracker::when_targetChanged() {
  rebuild_chain();
  when_geometryChanged();
}

void PositionTracker::when_parentChanged() {
  // 拓扑即时重建链路，坐标计算延迟到 flush（拓扑即时、坐标延迟）
  rebuild_chain();
  when_geometryChanged();
}

void PositionTracker::when_windowChanged() {
  rebuild_chain();
  when_geometryChanged();
}

void PositionTracker::when_pointChanged() {
  when_geometryChanged();
}

void PositionTracker::update() {
  m_dirty = true;
  flush();
}

void PositionTracker::flush() {
  m_flushScheduled = false;
  if (!m_dirty)
    return;
  m_dirty = false;
  recompute();
}

void PositionTracker::rebuild_chain() {
  for (auto* node : std::as_const(m_chain))
    disconnect(node, nullptr, this, nullptr);
  m_chain.clear();
  if (m_window)
    disconnect(m_window, nullptr, this, nullptr);
  m_window = nullptr;

  for (auto* node = m_target.value(); node; node = node->parentItem())
    m_chain.append(node);

  for (auto* node : std::as_const(m_chain)) {
    connect(node, &QQuickItem::xChanged, this,
      &PositionTracker::when_geometryChanged);
    connect(node, &QQuickItem::yChanged, this,
      &PositionTracker::when_geometryChanged);
    connect(node, &QQuickItem::scaleChanged, this,
      &PositionTracker::when_geometryChanged);
    connect(node, &QQuickItem::rotationChanged, this,
      &PositionTracker::when_geometryChanged);
    connect(node, &QQuickItem::transformOriginChanged, this,
      &PositionTracker::when_geometryChanged);
    connect(node, &QQuickItem::parentChanged, this,
      &PositionTracker::when_parentChanged);
  }
  // windowChanged 只挂 target：窗口变化沿祖先链传播，必然反映到 target
  if (m_target)
    connect(m_target, &QQuickItem::windowChanged, this,
      &PositionTracker::when_windowChanged);

  m_window = m_target ? m_target->window() : nullptr;
  if (m_window) {
    connect(m_window, &QWindow::xChanged, this,
      &PositionTracker::when_geometryChanged);
    connect(m_window, &QWindow::yChanged, this,
      &PositionTracker::when_geometryChanged);
  }
}

void PositionTracker::recompute() {
  QPointF newScenePos;
  QPointF newGlobalPos;
  QQuickWindow* newWindow = nullptr;
  if (m_target) {
    newScenePos = m_target->mapToScene(m_point.value());
    newWindow = m_target->window();
    if (newWindow)
      newGlobalPos = m_target->mapToGlobal(m_point.value());
    else
      newGlobalPos = newScenePos;
  } else {
    // target 为空：无坐标系可映射，输出透传（scene = global = point）
    newScenePos = m_point.value();
    newGlobalPos = m_point.value();
  }

  if (newScenePos != m_scenePos.value())
    m_scenePos.setValue(newScenePos);
  if (newGlobalPos != m_globalPos.value())
    m_globalPos.setValue(newGlobalPos);
  if (newWindow != m_currentWindow.value())
    m_currentWindow.setValue(newWindow);
}

QOOL_NS_END
