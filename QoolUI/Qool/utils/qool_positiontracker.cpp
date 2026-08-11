#include "qool_positiontracker.h"

#include <QTimer>
#include <utility>

/*!
    \qmltype PositionTracker
    \inqmlmodule Qool
    \nativetype qoolui::PositionTracker
    \brief 2D 位置追踪器：追踪 target 局部点 point 的场景坐标与屏幕坐标。

    给定 \c target（QQuickItem）与 \c point（target 局部坐标点，默认原点），
    逐层监听 target 祖先链的坐标/变换/拓扑变化，维护该点的 \c scenePos
    （场景坐标）、\c globalPos（屏幕坐标）与 \c currentWindow（所在场景）。

    祖先链任意层平移/缩放/旋转自动触发重算；坐标变化通知按事件循环批次
    合并（延迟至多一帧），值未变不重复通知。\c target 未显式设置时默认
    追踪声明父；\c target 为 null 时输出透传 \c point 原值；target 无窗口
    时 \c globalPos 等于 \c scenePos。

    \section1 信号

    所有属性均经 Qt 自动生成的 \c xxxChanged 信号通知（值守卫：实际值
    变化才发出，不重复通知）。输出属性 \c scenePosChanged /
    \c globalPosChanged / \c currentWindowChanged 是位置更新通知——
    强制重算（\c update()）后值若变化同样经此通知；输入属性
    \c targetChanged / \c pointChanged 是配置变化通知。

    \c transform 列表属性（transform 数组）变化无公开信号，需要时调用
    \c update() 强制重算。QWidget 混合场景（QQuickWidget）中
    \c currentWindow 是内部离屏渲染窗口（非显示容器），\c globalPos
    不反映真实屏幕位置——\c scenePos 不受影响。
*/

QOOL_NS_BEGIN

PositionTracker::PositionTracker(QObject* parent)
  : QObject { parent } {
  // target 缺省 = 声明父（构造时快照，不持续跟随 parent）。
  // 宿主显式赋值（含 null）经 setter 自然覆盖，无「显式 null」歧义。
  // setValue 先于 connect 执行：不触发 when_targetChanged（无重复重建）。
  m_target.setValue(qobject_cast<QQuickItem*>(parent));
  connect(this, &PositionTracker::targetChanged, this,
    &PositionTracker::when_targetChanged);
  connect(this, &PositionTracker::pointChanged, this,
    &PositionTracker::when_pointChanged);
  // 首次链路组装 + 置脏：flush 在事件循环首批执行；
  // QML 晚赋值的 target/point 会再次触发（重配/置脏），最终一致。
  rebuild_chain();
  when_geometryChanged();
}

void PositionTracker::when_geometryChanged() {
  // 几何输入变化汇聚（链节点 x/y/scale/rotation/transformOrigin +
  // 窗口坐标；point 经 when_pointChanged 走同一置脏路径）：
  // 帧内合并——只置脏，重算延迟到 flush（singleShot(0) 事件循环
  // 批次，非严格帧级）。已调度则无事可做——一帧内任意多次触发
  // 合并为一次重算。
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
  // 拓扑变更必须即时重建链路（否则信号从错误的链路来），
  // 坐标计算延迟到 flush——核心规则：拓扑即时、坐标延迟。
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
  // 强制立即重算：覆盖无信号可监听的盲区（如 transform 列表变化）。
  // 若批次已调度，此处立即执行后，后续 flush 回调因 m_dirty 已清而空转。
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
  // 整条断开重连：disconnect(node, nullptr, this, nullptr) 按节点
  // 批量断开（连接按节点组织，链路节点列表即连接管理单元）。
  for (auto* node : std::as_const(m_chain))
    disconnect(node, nullptr, this, nullptr);
  m_chain.clear();
  if (m_window)
    disconnect(m_window, nullptr, this, nullptr);
  m_window = nullptr;

  // 收集链路：target → 各级父 → 场景根 item（parent 为 null 处终止，
  // 场景根入链统一逻辑——其坐标恒为 0，不触发但无额外开销）。
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
  // windowChanged 只挂 target 一层：窗口变化沿祖先链传播，
  // 必然反映到 target 的 window 属性，每层都挂是冗余。
  if (m_target)
    connect(m_target, &QQuickItem::windowChanged, this,
      &PositionTracker::when_windowChanged);

  // 窗口坐标监听：窗口位置只影响屏幕坐标（scenePos 与窗口位置无关）。
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
      newGlobalPos = newScenePos; // 无窗口：屏幕坐标退化为场景坐标
  } else {
    // target 为空：无坐标系可映射，输出透传输入（scene = global = point）。
    // 保底语义连续——「未挂窗口」由 currentWindow == null 表达，
    // 不引入无效值概念（(0,0) 是合法坐标）。
    newScenePos = m_point.value();
    newGlobalPos = m_point.value();
  }

  // 值去重：结果未变不发信号，阻断下游无意义传播
  // （多层变化相互抵消时下游完全无感）。
  if (newScenePos != m_scenePos.value())
    m_scenePos.setValue(newScenePos);
  if (newGlobalPos != m_globalPos.value())
    m_globalPos.setValue(newGlobalPos);
  if (newWindow != m_currentWindow.value())
    m_currentWindow.setValue(newWindow);
}

QOOL_NS_END
