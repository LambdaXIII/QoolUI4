#ifndef QOOL_POSITIONTRACKER_H
#define QOOL_POSITIONTRACKER_H

#include "qoolcommon/qbindable_property_macros.hpp"
#include "qoolns.hpp"

#include <QObject>
#include <QPointF>
#include <QQuickItem>
#include <QQuickWindow>

QOOL_NS_BEGIN

// 2D 位置追踪器：追踪 target 局部点 point 的场景坐标与屏幕坐标。
// 与 ItemTracker 并列的独立工具（追踪机制不同：坐标无 flow-on，
// 必须逐层监听祖先链——监听自身信号覆盖不了祖先链平移）。
class PositionTracker: public QObject {
  Q_OBJECT
  QML_ELEMENT
public:
  explicit PositionTracker(QObject* parent = nullptr);

  // 强制立即重算（覆盖无信号盲区，如 transform 列表变化）
  Q_INVOKABLE void update();

protected:
  // 几何/窗口坐标信号汇聚槽：只置脏，不立即重算（帧内合并）
  Q_SLOT void when_geometryChanged();
  // 拓扑变更（父级/窗口/target 变化）：立即重建链路 + 置脏
  Q_SLOT void when_parentChanged();
  Q_SLOT void when_windowChanged();
  Q_SLOT void when_targetChanged();
  // point 变化：仅重算（链路结构只依赖 target 父链，与 point 无关）
  Q_SLOT void when_pointChanged();
  // 合并批次执行：重算 + 值去重 + 发信号。由 singleShot functor 回调
  // 与 update() 直接调用——非信号连接目标，故为普通成员而非槽
  void flush();

private:
  // 整条断开重连：断开旧链路（item 层 + 窗口层）→ 沿 parentItem()
  // 收集新链 → 循环连接 → 重连窗口
  void rebuild_chain();
  void recompute();

  QBINDABLE_WRITABLE_PROPERTY(
    PositionTracker, QQuickItem*, target)
  QBINDABLE_WRITABLE_PROPERTY(
    PositionTracker, QPointF, point)
  QBINDABLE_READONLY_PROPERTY(
    PositionTracker, QPointF, scenePos)
  QBINDABLE_READONLY_PROPERTY(
    PositionTracker, QPointF, globalPos)
  QBINDABLE_READONLY_PROPERTY(
    PositionTracker, QQuickWindow*, currentWindow)

  QList<QQuickItem*> m_chain;
  QQuickWindow* m_window { nullptr };
  bool m_dirty { false };
  bool m_flushScheduled { false };
};

QOOL_NS_END
#endif // QOOL_POSITIONTRACKER_H
