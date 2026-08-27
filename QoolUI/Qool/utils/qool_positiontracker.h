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
class PositionTracker: public QObject {
  Q_OBJECT
  QML_ELEMENT
public:
  explicit PositionTracker(QObject* parent = nullptr);

  Q_INVOKABLE void update();

protected:
  Q_SLOT void when_geometryChanged();
  Q_SLOT void when_parentChanged();
  Q_SLOT void when_windowChanged();
  Q_SLOT void when_targetChanged();
  // point 变化：仅重算（链路结构只依赖 target 父链，与 point 无关）
  Q_SLOT void when_pointChanged();
  void flush();

private:
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
